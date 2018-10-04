require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_helper.rb')

describe "Sequel forme_set plugin" do
  before do
    @ab = Album.new
    @f = Forme::Form.new(@ab)
  end
  
  it "#forme_set should only set values in the form" do
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_be_nil

    @f.input(:name)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal 'Foo'

    @ab.forme_set('copies_sold'=>'1')
    @ab.name.must_be_nil
    @ab.copies_sold.must_be_nil

    @f.input(:copies_sold)
    @ab.forme_set('name'=>'Bar', 'copies_sold'=>'1')
    @ab.name.must_equal 'Bar'
    @ab.copies_sold.must_equal 1
  end
  
  it "#forme_set should handle different ways to specify parameter names" do
    [{:attr=>{:name=>'foo'}}, {:attr=>{'name'=>:foo}}, {:name=>'foo'}, {:name=>'bar[foo]'}, {:key=>:foo}].each do |opts|
      @f.input(:name, opts)

      @ab.forme_set(:name=>'Foo')
      @ab.name.must_be_nil

      @ab.forme_set('foo'=>'Foo')
      @ab.name.must_equal 'Foo'
      @ab.forme_inputs.clear
    end
  end

  it "#forme_set should ignore values where key is explicitly set to nil" do
    @f.input(:name, :key=>nil)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_be_nil
    @ab.forme_set(nil=>'Foo')
    @ab.name.must_be_nil
  end
  
  it "#forme_set should skip inputs with disabled/readonly formatter set on input" do
    [:disabled, :readonly, ::Forme::Formatter::Disabled, ::Forme::Formatter::ReadOnly].each do |formatter|
      @f.input(:name, :formatter=>formatter)
      @ab.forme_set(:name=>'Foo')
      @ab.name.must_be_nil
    end

    @f.input(:name, :formatter=>:default)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal 'Foo'
  end
  
  it "#forme_set should skip inputs with disabled/readonly formatter set on Form" do
    [:disabled, :readonly, ::Forme::Formatter::Disabled, ::Forme::Formatter::ReadOnly].each do |formatter|
      @f = Forme::Form.new(@ab, :formatter=>:disabled)
      @f.input(:name)
      @ab.forme_set(:name=>'Foo')
      @ab.name.must_be_nil
    end

    @f = Forme::Form.new(@ab, :formatter=>:default)
    @f.input(:name)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal 'Foo'
  end
  
  it "#forme_set should skip inputs with disabled/readonly formatter set using with_opts" do
    [:disabled, :readonly, ::Forme::Formatter::Disabled, ::Forme::Formatter::ReadOnly].each do |formatter|
      @f.with_opts(:formatter=>formatter) do
        @f.input(:name)
      end
      @ab.forme_set(:name=>'Foo')
      @ab.name.must_be_nil
    end

    @f.with_opts(:formatter=>:default) do
      @f.input(:name)
    end
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal 'Foo'
  end

  it "#forme_set should prefer input formatter to with_opts formatter" do
    @f.with_opts(:formatter=>:default) do
      @f.input(:name, :formatter=>:readonly)
    end
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_be_nil

    @f.with_opts(:formatter=>:readonly) do
      @f.input(:name, :formatter=>:default)
    end
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal 'Foo'
  end

  it "#forme_set should prefer with_opts formatter to form formatter" do
    @f = Forme::Form.new(@ab, :formatter=>:default)
    @f.with_opts(:formatter=>:readonly) do
      @f.input(:name)
    end
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_be_nil

    @f = Forme::Form.new(@ab, :formatter=>:readonly)
    @f.with_opts(:formatter=>:default) do
      @f.input(:name)
    end
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal 'Foo'
  end
  
  it "#forme_set should handle setting values for associated objects" do
    @ab.forme_set(:artist_id=>1)
    @ab.artist_id.must_be_nil

    @f.input(:artist)
    @ab.forme_set(:artist_id=>'1')
    @ab.artist_id.must_equal 1

    @ab.forme_set('tag_pks'=>%w'1 2')
    @ab.artist_id.must_be_nil
    @ab.tag_pks.must_equal []

    @f.input(:tags)
    @ab.forme_set('artist_id'=>'1', 'tag_pks'=>%w'1 2')
    @ab.artist_id.must_equal 1
    @ab.tag_pks.must_equal [1, 2]
  end
  
  it "#forme_set should handle validations for filtered associations" do
    [
      [{:dataset=>proc{|ds| ds.exclude(:id=>1)}},
       {:dataset=>proc{|ds| ds.exclude(:id=>1)}}],
      [{:options=>Artist.exclude(:id=>1).select_order_map([:name, :id])},
       {:options=>Tag.exclude(:id=>1).select_order_map(:id), :name=>'tag_pks[]'}],
      [{:options=>Artist.exclude(:id=>1).all, :text_method=>:name, :value_method=>:id},
       {:options=>Tag.exclude(:id=>1).all, :text_method=>:name, :value_method=>:id}],
    ].each do |artist_opts, tag_opts|
      @ab.forme_inputs.clear
      @f.input(:artist, artist_opts)
      @f.input(:tags, tag_opts)

      @ab.forme_validations.clear
      @ab.forme_set('artist_id'=>'1', 'tag_pks'=>%w'1 2')
      @ab.artist_id.must_equal 1
      @ab.tag_pks.must_equal [1, 2]

      @ab.valid?.must_equal false
      @ab.errors[:artist_id].must_equal ['invalid value submitted']
      @ab.errors[:tag_pks].must_equal ['invalid value submitted']

      @ab.forme_validations.clear
      @ab.forme_set('artist_id'=>'1', 'tag_pks'=>['2'])
      @ab.valid?.must_equal false
      @ab.errors[:artist_id].must_equal ['invalid value submitted']
      @ab.errors[:tag_pks].must_be_nil

      @ab.forme_validations.clear
      @ab.forme_set('artist_id'=>'2', 'tag_pks'=>['2'])
      @ab.valid?.must_equal true
    end
  end

  it "#forme_set should not require associated values for many_to_one association with select boxes" do
    @f.input(:artist)
    @ab.forme_set({})
    @ab.valid?.must_equal true
  end

  it "#forme_set should not require associated values for many_to_one association with radio buttons" do
    @f.input(:artist, :as=>:radio)
    @ab.forme_set({})
    @ab.valid?.must_equal true
  end

  it "#forme_set should require associated values for many_to_one association with select boxes when :required is used" do
    @f.input(:artist, :required=>true)
    @ab.forme_set({})
    @ab.valid?.must_equal false
    @ab.errors[:artist_id].must_equal ['invalid value submitted']
  end

  it "#forme_set should require associated values for many_to_one association with radio buttons when :required is used" do
    @f.input(:artist, :as=>:radio, :required=>true)
    @ab.forme_set({})
    @ab.valid?.must_equal false
    @ab.errors[:artist_id].must_equal ['invalid value submitted']
  end

  it "#forme_set should handle cases where currently associated values is nil" do
    @f.input(:tags)
    @ab.forme_set({:tag_pks=>[1]})
    def @ab.tag_pks; nil; end
    @ab.valid?.must_equal true
  end

  it "#forme_parse should return hash with values and validations" do
    @f.input(:name)
    @ab.forme_parse(:name=>'Foo').must_equal(:values=>{:name=>'Foo'}, :validations=>{})

    @f.input(:artist, :dataset=>proc{|ds| ds.exclude(:id=>1)})
    hash = @ab.forme_parse(:name=>'Foo', 'artist_id'=>'1')
    hash[:values] = {:name=>'Foo', :artist_id=>'1'}
    @ab.set(hash[:values])
    @ab.valid?.must_equal true

    @ab.forme_validations.merge!(hash[:validations])
    @ab.valid?.must_equal false
    @ab.errors[:artist_id].must_equal ['invalid value submitted']
  end

  it "#forme_parse should return hash with values and validations" do
    @ab.forme_validations[:name] = [:bar, []]
    proc{@ab.valid?}.must_raise Sequel::Plugins::Forme::Error
  end
end
