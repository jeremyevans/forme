require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'erb_helper.rb')

require 'rubygems'
begin
  require 'roda'
  require 'tilt'
rescue LoadError
  warn "unable to load roda or tilt, skipping roda specs"
else
begin
  require 'tilt/erubi'
rescue LoadError
  begin
    require 'tilt/erubis'
  rescue LoadError
    require 'tilt/erb'
  end
end

class FormeRodaTest < Roda
  opts[:check_dynamic_arity] = opts[:check_arity] = :warn
  
  if defined?(Roda::RodaVersionNumber) && Roda::RodaVersionNumber >= 30100
    require 'roda/session_middleware'
    opts[:sessions_convert_symbols] = true
    use RodaSessionMiddleware, :secret=>SecureRandom.random_bytes(64), :key=>'rack.session'
  else
    use Rack::Session::Cookie, :secret => "__a_very_long_string__"
  end

  def erb(s, opts={})
    render(opts.merge(:inline=>s))
  end

  route do |r|
    r.get 'use_request_specific_token', :use do |use|
      render :inline=>"[#{Base64.strict_encode64(send(:csrf_secret))}]<%= form({:method=>:post}, {:use_request_specific_token=>#{use == '1'}}) %>"
    end
    r.get 'hidden_tags' do |use|
      render :inline=>"<%= form({:method=>:post}, {:hidden_tags=>[{:foo=>'bar'}]}) %>"
    end
    r.get 'csrf', :use do |use|
      render :inline=>"<%= form({:method=>:post}, {:csrf=>#{use == '1'}}) %>"
    end
    instance_exec(r, &ERB_BLOCK)
  end
end

begin
  require 'rack/csrf'
rescue LoadError
  warn "unable to load rack/csrf, skipping roda csrf plugin spec"
else
describe "Forme Roda ERB integration with roda forme and csrf plugins" do
  app = FormeRodaCSRFTest = Class.new(FormeRodaTest)
  app.plugin :csrf
  app.plugin :forme
  
  def sin_get(path)
    s = String.new
    FormeRodaCSRFTest.app.call(@rack.merge('PATH_INFO'=>path))[2].each{|str| s << str}
    s.gsub(/\s+/, ' ').strip
  end

  include FormeErbSpecs
end
end

begin
  require 'roda/plugins/route_csrf'
rescue LoadError
  warn "unable to load roda/plugins/route_csrf, skipping forme_route_csrf plugin spec"
else
[{}, {:require_request_specific_tokens=>false}].each do |plugin_opts|
  describe "Forme Roda ERB integration with roda forme_route_csrf and route_csrf plugin with #{plugin_opts}" do
    app = Class.new(FormeRodaTest)
    app.plugin :forme_route_csrf
    app.plugin :route_csrf, plugin_opts

    define_method(:sin_get) do |path|
      s = String.new
      app.call(@rack.merge('PATH_INFO'=>path))[2].each{|str| s << str}
      s.gsub(/\s+/, ' ').strip
    end

    include FormeErbSpecs

    it "should handle the :hidden_tags option" do
      output = sin_get('/use_request_specific_token/1')
      output =~ /\[([^\]]+)\].*?value=\"([^\"]+)\"/
      secret = $1
      token = $2
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/1', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal true
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/2', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal false
    end

    it "should handle the :use_request_specific_token => true option" do
      output = sin_get('/use_request_specific_token/1')
      output =~ /\[([^\]]+)\].*?value=\"([^\"]+)\"/
      secret = $1
      token = $2
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/1', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal true
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/2', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal false
    end

    it "should handle the :use_request_specific_token => false option" do
      output = sin_get('/use_request_specific_token/0')
      output =~ /\[([^\]]+)\].*?value=\"([^\"]+)\"/
      secret = $1
      token = $2
      app.new({'SCRIPT_NAME'=>'', 'PATH_INFO'=>'/use_request_specific_token/0', 'REQUEST_METHOD'=>'POST', 'rack.session'=>{'_roda_csrf_secret'=>secret}, 'rack.input'=>StringIO.new}).valid_csrf?(:token=>token).must_equal(plugin_opts.empty? ? false : true)
    end

    it "should handle the :hidden_tags option" do
      sin_get('/hidden_tags').must_include 'name="foo" type="hidden" value="bar"'
    end

    it "should handle the :csrf option" do
      sin_get('/csrf/1').must_include '<input name="_csrf" type="hidden" value="'
      sin_get('/csrf/0').wont_include '<input name="_csrf" type="hidden" value="'
    end
  end

  describe "Forme Roda ERB Sequel integration with roda forme_set plugin and route_csrf plugin with #{plugin_opts}" do
    before do
      @app = Class.new(FormeRodaTest)
      @app.plugin :route_csrf, plugin_opts
      @app.plugin(:forme_set, :secret=>'1'*64)

      @ab = Album.new
    end

    def forme_parse(*args, &block)
      _forme_set(:forme_parse, *args, &block)
    end

    def forme_set(*args, &block)
      _forme_set(:forme_set, *args, &block)
    end

    def forme_call(params)
      @app.call('REQUEST_METHOD'=>'POST', 'rack.input'=>StringIO.new, :params=>params)
    end

    def _forme_set(meth, obj, orig_hash, *form_args, &block)
      hash = {}
      orig_hash.each{|k,v| hash[k.to_s] = v}
      album = @ab
      ret, form, data, hmac = nil
      
      @app.route do |r|
        r.get do
          form(*env[:args], &env[:block]).to_s
        end
        r.post do
          r.params.replace(env[:params])
          ret = send(meth, album)
          nil
        end
      end
      body = @app.call('REQUEST_METHOD'=>'GET', :args=>[album, *form_args], :block=>block)[2].join
      body =~ %r|<input name="_csrf" type="hidden" value="([^"]+)"/>.*<input name="_forme_set_data" type="hidden" value="([^"]+)"/><input name="_forme_set_data_hmac" type="hidden" value="([^"]+)"/>|n
      csrf = $1
      data = $2
      hmac = $3
      data.gsub!("&quot;", '"') if data
      h = {"album"=>hash,  "_forme_set_data"=>data, "_forme_set_data_hmac"=>hmac, "_csrf"=>csrf}
      if data && hmac
        forme_call(h)
      end
      meth == :forme_parse ? ret : h
    end

    it "#forme_set should include HMAC values if form includes inputs for obj" do
      h = forme_set(@ab, :name=>'Foo')
      proc{forme_call(h)}.must_raise Roda::RodaPlugins::FormeSet::Error
      @ab.name.must_be_nil
      @ab.copies_sold.must_be_nil

      h = forme_set(@ab, :name=>'Foo'){|f| f.input(:name)}
      hmac = h.delete("_forme_set_data_hmac")
      proc{forme_call(h)}.must_raise Roda::RodaPlugins::FormeSet::Error
      proc{forme_call(h.merge("_forme_set_data_hmac"=>hmac+'1'))}.must_raise Roda::RodaPlugins::FormeSet::Error
      data = h["_forme_set_data"]
      data.sub!(/"csrf":\["_csrf","./, "\"csrf\":[\"_csrf\",\"|")
      hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA512.new, '1'*64, data)
      proc{forme_call(h.merge("_forme_set_data_hmac"=>hmac))}.must_raise Roda::RodaPlugins::FormeSet::Error
      @ab.name.must_equal 'Foo'
      @ab.copies_sold.must_be_nil

      forme_set(@ab, :copies_sold=>100){|f| f.input(:name)}
      @ab.name.must_be_nil
      @ab.copies_sold.must_be_nil
    end

    it "#forme_set should handle custom form namespaces" do
      forme_set(@ab, {"album"=>{"name"=>'Foo', 'copies_sold'=>'100'}}, {}, :namespace=>'album'){|f| f.input(:name); f.input(:copies_sold)}
      @ab.name.must_equal 'Foo'
      @ab.copies_sold.must_equal 100

      proc{forme_set(@ab, {"a"=>{"name"=>'Foo'}}, {}, :namespace=>'album'){|f| f.input(:name); f.input(:copies_sold)}}.must_raise Roda::RodaPlugins::FormeSet::Error
    end

    it "#forme_set should only set values in the form" do
      forme_set(@ab, :name=>'Foo')
      @ab.name.must_be_nil

      forme_set(@ab, :name=>'Foo'){|f| f.input(:name)}
      @ab.name.must_equal 'Foo'

      forme_set(@ab, 'copies_sold'=>'1'){|f| f.input(:name)}
      @ab.name.must_be_nil
      @ab.copies_sold.must_be_nil

      forme_set(@ab, 'name'=>'Bar', 'copies_sold'=>'1'){|f| f.input(:name); f.input(:copies_sold)}
      @ab.name.must_equal 'Bar'
      @ab.copies_sold.must_equal 1
    end

    it "#forme_set should work for forms without blocks" do
      forme_set(@ab, {:name=>'Foo'}, {}, :inputs=>[:name])
      @ab.name.must_equal 'Foo'
    end

    it "#forme_set should handle different ways to specify parameter names" do
      [{:attr=>{:name=>'foo'}}, {:attr=>{'name'=>:foo}}, {:name=>'foo'}, {:name=>'bar[foo]'}, {:key=>:foo}].each do |opts|
        forme_set(@ab, name=>'Foo'){|f| f.input(:name, opts)}
        @ab.name.must_be_nil

        forme_set(@ab, 'foo'=>'Foo'){|f| f.input(:name, opts)}
        @ab.name.must_equal 'Foo'
      end
    end

    it "#forme_set should ignore values where key is explicitly set to nil" do
      forme_set(@ab, :name=>'Foo'){|f| f.input(:name, :key=>nil)}
      @ab.forme_set(:name=>'Foo')
      @ab.name.must_be_nil
      @ab.forme_set(nil=>'Foo')
      @ab.name.must_be_nil
    end
    
    it "#forme_set should skip inputs with disabled/readonly formatter set on input" do
      [:disabled, :readonly, ::Forme::Formatter::Disabled, ::Forme::Formatter::ReadOnly].each do |formatter|
        forme_set(@ab, :name=>'Foo'){|f| f.input(:name, :formatter=>formatter)}
        @ab.name.must_be_nil
      end

      forme_set(@ab, :name=>'Foo'){|f| f.input(:name, :formatter=>:default)}
      @ab.name.must_equal 'Foo'
    end
    
    it "#forme_set should skip inputs with disabled/readonly formatter set on Form" do
      [:disabled, :readonly, ::Forme::Formatter::Disabled, ::Forme::Formatter::ReadOnly].each do |formatter|
        forme_set(@ab, {:name=>'Foo'}, {}, :formatter=>:disabled){|f| f.input(:name)}
        @ab.name.must_be_nil
      end

      forme_set(@ab, {:name=>'Foo'}, {}, :formatter=>:default){|f| f.input(:name)}
      @ab.name.must_equal 'Foo'
    end
    
    it "#forme_set should skip inputs with disabled/readonly formatter set using with_opts" do
      [:disabled, :readonly, ::Forme::Formatter::Disabled, ::Forme::Formatter::ReadOnly].each do |formatter|
        forme_set(@ab, :name=>'Foo'){|f| f.with_opts(:formatter=>formatter){f.input(:name)}}
        @ab.name.must_be_nil
      end

      forme_set(@ab, :name=>'Foo'){|f| f.with_opts(:formatter=>:default){f.input(:name)}}
      @ab.name.must_equal 'Foo'
    end

    it "#forme_set should prefer input formatter to with_opts formatter" do
      forme_set(@ab, :name=>'Foo'){|f| f.with_opts(:formatter=>:default){f.input(:name, :formatter=>:readonly)}}
      @ab.name.must_be_nil

      forme_set(@ab, :name=>'Foo'){|f| f.with_opts(:formatter=>:readonly){f.input(:name, :formatter=>:default)}}
      @ab.name.must_equal 'Foo'
    end

    it "#forme_set should prefer with_opts formatter to form formatter" do
      forme_set(@ab, {:name=>'Foo'}, {}, :formatter=>:default){|f| f.with_opts(:formatter=>:readonly){f.input(:name)}}
      @ab.name.must_be_nil

      forme_set(@ab, {:name=>'Foo'}, {}, :formatter=>:readonly){|f| f.with_opts(:formatter=>:default){f.input(:name)}}
      @ab.name.must_equal 'Foo'
    end
    
    it "#forme_set should handle setting values for associated objects" do
      forme_set(@ab, :artist_id=>'1')
      @ab.artist_id.must_be_nil

      forme_set(@ab, :artist_id=>'1'){|f| f.input(:artist)}
      @ab.artist_id.must_equal 1

      forme_set(@ab, 'tag_pks'=>%w'1 2'){|f| f.input(:artist)}
      @ab.artist_id.must_be_nil
      @ab.tag_pks.must_equal []

      forme_set(@ab, 'artist_id'=>'1', 'tag_pks'=>%w'1 2'){|f| f.input(:artist); f.input(:tags)}
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
        @ab.forme_validations.clear
        forme_set(@ab, 'artist_id'=>'1', 'tag_pks'=>%w'1 2'){|f| f.input(:artist, artist_opts); f.input(:tags, tag_opts)}
        @ab.artist_id.must_equal 1
        @ab.tag_pks.must_equal [1, 2]
        @ab.valid?.must_equal false
        @ab.errors[:artist_id].must_equal ['invalid value submitted']
        @ab.errors[:tag_pks].must_equal ['invalid value submitted']

        @ab.forme_validations.clear
        forme_set(@ab, 'artist_id'=>'1', 'tag_pks'=>%w'2'){|f| f.input(:artist, artist_opts); f.input(:tags, tag_opts)}
        @ab.forme_set('artist_id'=>'1', 'tag_pks'=>['2'])
        @ab.artist_id.must_equal 1
        @ab.tag_pks.must_equal [2]
        @ab.valid?.must_equal false
        @ab.errors[:artist_id].must_equal ['invalid value submitted']
        @ab.errors[:tag_pks].must_be_nil

        @ab.forme_validations.clear
        forme_set(@ab, 'artist_id'=>'2', 'tag_pks'=>%w'2'){|f| f.input(:artist, artist_opts); f.input(:tags, tag_opts)}
        @ab.valid?.must_equal true
      end
    end

    it "#forme_set should not require associated values for many_to_one association with select boxes" do
      forme_set(@ab, {}){|f| f.input(:artist)}
      @ab.valid?.must_equal true

      forme_set(@ab, {'artist_id'=>nil}){|f| f.input(:artist)}
      @ab.valid?.must_equal true

      forme_set(@ab, {'artist_id'=>''}){|f| f.input(:artist)}
      @ab.valid?.must_equal true
    end

    it "#forme_set should not require associated values for many_to_one association with radio buttons" do
      forme_set(@ab, {}){|f| f.input(:artist, :as=>:radio)}
      @ab.valid?.must_equal true
    end

    it "#forme_set should require associated values for many_to_one association with select boxes when :required is used" do
      forme_set(@ab, {}){|f| f.input(:artist, :required=>true)}
      @ab.valid?.must_equal false
      @ab.errors[:artist_id].must_equal ['invalid value submitted']
    end

    it "#forme_set should require associated values for many_to_one association with radio buttons when :required is used" do
      forme_set(@ab, {}){|f| f.input(:artist, :as=>:radio, :required=>true)}
      @ab.valid?.must_equal false
      @ab.errors[:artist_id].must_equal ['invalid value submitted']
    end

    it "#forme_set should handle cases where currently associated values is nil" do
      def @ab.tag_pks; nil; end
      forme_set(@ab, :tag_pks=>['1']){|f| f.input(:tags)}
      @ab.valid?.must_equal true
    end

    it "#forme_parse should return hash with values and validations" do
      forme_parse(@ab, :name=>'Foo'){|f| f.input(:name)}.must_equal(:values=>{:name=>'Foo'}, :validations=>{})

      hash = forme_parse(@ab, :name=>'Foo', 'artist_id'=>'1') do |f|
        f.input(:name)
        f.input(:artist, :dataset=>proc{|ds| ds.exclude(:id=>1)})
      end
      hash.must_equal(:values=>{:name=>'Foo', :artist_id=>'1'}, :validations=>{:artist_id=>[:valid, false]})

      @ab.set(hash[:values])
      @ab.valid?.must_equal true

      @ab.forme_validations.merge!(hash[:validations])
      @ab.valid?.must_equal false
      @ab.errors[:artist_id].must_equal ['invalid value submitted']

      @ab = Album.new
      hash = forme_parse(@ab, :name=>'Foo', 'artist_id'=>'1') do |f|
        f.input(:name)
        f.input(:artist, :dataset=>proc{|ds| ds.exclude(:id=>2)})
      end
      hash.must_equal(:values=>{:name=>'Foo', :artist_id=>'1'}, :validations=>{:artist_id=>[:valid, true]})
      @ab.set(hash[:values])
      @ab.valid?.must_equal true

      @ab.forme_validations.merge!(hash[:validations])
      @ab.valid?.must_equal true
    end
  end
end
end
end
