require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_helper.rb')

describe "Sequel forme_set plugin" do
  before do
    @ab = Album.new
    @f = Forme::Form.new(@ab)
  end
  
  it "#forme_set should only set values in the form" do
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal nil

    @f.input(:name)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal 'Foo'

    @ab.forme_set('copies_sold'=>'1')
    @ab.name.must_equal nil
    @ab.copies_sold.must_equal nil

    @f.input(:copies_sold)
    @ab.forme_set('name'=>'Bar', 'copies_sold'=>'1')
    @ab.name.must_equal 'Bar'
    @ab.copies_sold.must_equal 1
  end
  
  it "#forme_set should handle different ways to specify parameter names" do
    [{:attr=>{:name=>'foo'}}, {:attr=>{'name'=>:foo}}, {:name=>'foo'}, {:name=>'bar[foo]'}, {:key=>:foo}].each do |opts|
      @f.input(:name, opts)

      @ab.forme_set(:name=>'Foo')
      @ab.name.must_equal nil

      @ab.forme_set('foo'=>'Foo')
      @ab.name.must_equal 'Foo'
      @ab.forme_inputs.clear
    end
  end

  it "#forme_set should ignore values where key is explicitly set to nil" do
    @f.input(:name, :key=>nil)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal nil
    @ab.forme_set(nil=>'Foo')
    @ab.name.must_equal nil
  end
  
  it "#forme_set should skip inputs with disabled/readonly formatter" do
    @f.input(:name, :formatter=>:disabled)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal nil

    @f.input(:name, :formatter=>:readonly)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal nil

    @f.input(:name, :formatter=>:default)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal 'Foo'
  end
  
  it "#forme_set should skip inputs with disabled/readonly formatter" do
    @f = Forme::Form.new(@ab, :formatter=>:disabled)
    @f.input(:name)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal nil

    @f = Forme::Form.new(@ab, :formatter=>:readonly)
    @f.input(:name)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal nil

    @f.input(:name, :formatter=>:default)
    @ab.forme_set(:name=>'Foo')
    @ab.name.must_equal 'Foo'
  end
  
  it "#forme_set should handle setting values for associated objects" do
    @ab.forme_set(:artist_id=>1)
    @ab.artist_id.must_equal nil

    @f.input(:artist)
    @ab.forme_set(:artist_id=>'1')
    @ab.artist_id.must_equal 1

    @ab.forme_set('tag_pks'=>%w'1 2')
    @ab.artist_id.must_equal nil
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
       {:options=>Tag.exclude(:id=>1).select_order_map(:id)}]
    ].each do |artist_opts, tag_opts|
      @ab.forme_inputs.clear
      @f.input(:artist, artist_opts)
      @f.input(:tags, tag_opts)

      @ab.send(:instance_hooks, :after_validation).clear
      @ab.forme_set('artist_id'=>'1', 'tag_pks'=>%w'1 2')
      @ab.artist_id.must_equal 1
      @ab.tag_pks.must_equal [1, 2]

      @ab.valid?.must_equal false
      @ab.errors[:artist_id].must_equal ['invalid value submitted']
      @ab.errors[:tag_pks].must_equal ['invalid value submitted']

      @ab.send(:instance_hooks, :after_validation).clear
      @ab.forme_set('artist_id'=>'1', 'tag_pks'=>['2'])
      @ab.valid?.must_equal false
      @ab.errors[:artist_id].must_equal ['invalid value submitted']
      @ab.errors[:tag_pks].must_equal nil

      @ab.send(:instance_hooks, :after_validation).clear
      @ab.forme_set('artist_id'=>'2', 'tag_pks'=>['2'])
      @ab.valid?.must_equal true
    end
  end
end
