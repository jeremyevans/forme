require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

describe "Forme plain forms" do
  before do
    @f = Forme::Form.new
  end

  specify "Forme.version should return version string" do
    Forme.version.should =~ /\A\d+\.\d+\.\d+\z/
  end

  specify "should create a simple input tags" do
    @f.input(:text).should == '<input type="text"/>'
    @f.input(:radio).should == '<input type="radio"/>'
    @f.input(:password).should == '<input type="password"/>'
    @f.input(:checkbox).should == '<input type="checkbox"/>'
    @f.input(:submit).should == '<input type="submit"/>'
  end

  specify "should create hidden input with value 0 for each checkbox with a name" do
    @f.input(:checkbox, :name=>"foo").should == '<input name="foo" type="hidden" value="0"/><input name="foo" type="checkbox"/>'
  end

  specify "should create hidden input with _hidden appened to id for each checkbox with a name and id" do
    @f.input(:checkbox, :name=>"foo", :id=>"bar").should == '<input id="bar_hidden" name="foo" type="hidden" value="0"/><input id="bar" name="foo" type="checkbox"/>'
  end

  specify "should create hidden input with value f for each checkbox with a name and value t" do
    @f.input(:checkbox, :name=>"foo", :value=>"t").should == '<input name="foo" type="hidden" value="f"/><input name="foo" type="checkbox" value="t"/>'
  end

  specify "should use :hidden_value option for value of hidden input for checkbox" do
    @f.input(:checkbox, :name=>"foo", :hidden_value=>"no").should == '<input name="foo" type="hidden" value="no"/><input name="foo" type="checkbox"/>'
  end

  specify "should handle :checked option" do
    @f.input(:checkbox, :checked=>true).should == '<input checked="checked" type="checkbox"/>'
    @f.input(:checkbox, :checked=>false).should == '<input type="checkbox"/>'
  end

  specify "should create textarea tag" do
    @f.input(:textarea).should == '<textarea></textarea>'
  end

  specify "should create select tag" do
    @f.input(:select).should == '<select></select>'
  end

  specify "should create select tag with options" do
    @f.input(:select, :options=>[1, 2, 3], :selected=>2).should == '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
    @f.input(:select, :options=>[1, 2, 3], :value=>2).should == '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
  end

  specify "should create select tag with options and values" do
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).should == '<select><option value="1">a</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  specify "should create select tag with options and values with hashes" do
    @f.input(:select, :options=>[[:a, {:foo=>1}], [:b, {:bar=>4, :value=>2}], [:c, {:baz=>3}]], :selected=>2).should == '<select><option foo="1">a</option><option bar="4" selected="selected" value="2">b</option><option baz="3">c</option></select>'
  end

  specify "should create select tag with options and values using given method" do
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).should == '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).should == '<select><option value="a">1</option><option selected="selected" value="b">2</option><option value="c">3</option></select>'
  end

  specify "should use html attributes specified in options" do
    @f.input(:text, :value=>'foo', :name=>'bar').should == '<input name="bar" type="text" value="foo"/>'
    @f.input(:textarea, :value=>'foo', :name=>'bar').should == '<textarea name="bar">foo</textarea>'
    @f.input(:select, :name=>'bar', :options=>[1, 2, 3]).should == '<select name="bar"><option>1</option><option>2</option><option>3</option></select>'
  end

  specify "should support :add_blank option for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).should == '<select><option value=""></option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  specify "should use :add_blank option value as prompt if it is a String" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).should == '<select><option value="">Prompt Here</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  specify "radio and checkbox inputs should handle :checked option" do
    @f.input(:radio, :checked=>true).should == '<input checked="checked" type="radio"/>'
    @f.input(:radio, :checked=>false).should == '<input type="radio"/>'
    @f.input(:checkbox, :checked=>true).should == '<input checked="checked" type="checkbox"/>'
    @f.input(:checkbox, :checked=>false).should == '<input type="checkbox"/>'
  end

  specify "should automatically create a label if a :label option is used" do
    @f.input(:text, :label=>'Foo', :value=>'foo').should == '<label>Foo: <input type="text" value="foo"/></label>'
  end

  specify "should automatically note the input has errors if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo').should == '<input class="error" type="text" value="foo"/><span class="error_message">Bad Stuff!</span>'
  end

  specify "should add to existing :class option if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :class=>'bar', :value=>'foo').should == '<input class="bar error" type="text" value="foo"/><span class="error_message">Bad Stuff!</span>'
  end

  specify "#open should return an opening tag" do
    @f.open(:action=>'foo', :method=>'post').should == '<form action="foo" method="post">'
  end

  specify "#close should return a closing tag" do
    @f.close.should == '</form>'
  end

  specify "#button should return a submit tag" do
    @f.button.should == '<input type="submit"/>'
  end

  specify "#tag should return a serialized_tag" do
    @f.tag(:textarea).should == '<textarea></textarea>'
    @f.tag(:textarea, :name=>:foo).should == '<textarea name="foo"></textarea>'
    @f.tag(:textarea, {:name=>:foo}, :bar).should == '<textarea name="foo">bar</textarea>'
  end

  specify "should have an #inputs method for multiple inputs wrapped in a fieldset" do
    @f.inputs(:textarea, :text).should == '<fieldset><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have an #inputs method take a block and yield to it" do
    @f.inputs{@f.input(:textarea); @f.input(:text)}.should == '<fieldset><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have an #inputs method work with both args and block" do
    @f.inputs(:textarea){@f.input(:text)}.should == '<fieldset><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have an #inputs method support array arguments and creating inputs with the array as argument list" do
    @f.inputs([:textarea, {:name=>'foo'}], [:text, {:id=>'bar'}]).should == '<fieldset><textarea name="foo"></textarea><input id="bar" type="text"/></fieldset>'
  end
end

describe "Forme custom" do
  specify "formatters can be specified as a proc" do
    Forme::Form.new(:formatter=>proc{|f, i| Forme::Tag.new(:textarea, i.opts.map{|k,v| [v.upcase, k.to_s.downcase]})}).input(:text, :NAME=>'foo').should == '<textarea FOO="name"></textarea>'
  end

  specify "serializers can be specified as a proc" do
    Forme::Form.new(:serializer=>proc{|t| "#{t.type} = #{t.attr.inspect}"}).input(:textarea, :NAME=>'foo').should == 'textarea = {:NAME=>"foo"}'
  end

  specify "labelers can be specified as a proc" do
    Forme::Form.new(:labeler=>proc{|l, t| ["#{l}: ", t]}).input(:textarea, :NAME=>'foo', :label=>'bar').should == 'bar: <textarea NAME="foo"></textarea>'
  end

  specify "wrappers can be specified as a proc" do
    Forme::Form.new(:wrapper=>proc{|t| Forme::Tag.new(:div, {}, t)}).input(:textarea, :NAME=>'foo').should == '<div><textarea NAME="foo"></textarea></div>'
  end

  specify "inputs_wrappers can be specified as a proc" do
    Forme::Form.new(:inputs_wrapper=>proc{|f, &block| f.tag(:div, &block)}).inputs(:textarea).should == '<div><textarea></textarea></div>'
  end
end

describe "Forme built-in custom" do
  specify "transformers should raise if the there is no matching transformer" do
    proc{Forme::Form.new(:formatter=>:foo)}.should raise_error(Forme::Error)
  end

  specify "labeler: explicit uses an explicit label with for attribute" do
    Forme::Form.new(:labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'bar').should == '<label for="foo">bar</label><textarea id="foo"></textarea>'
  end

  specify "labeler: explicit should handle tags with errors" do
    Forme::Form.new(:labeler=>:explicit).input(:text, :error=>'Bad Stuff!', :value=>'f', :id=>'foo', :label=>'bar').should == '<label for="foo">bar</label><input class="error" id="foo" type="text" value="f"/><span class="error_message">Bad Stuff!</span>'
  end

  specify "wrapper: li wraps tag in an li" do
    Forme::Form.new(:wrapper=>:li).input(:textarea, :id=>'foo').should == '<li><textarea id="foo"></textarea></li>'
  end

  specify "wrapper: trtd wraps tag in an tr/td" do
    Forme::Form.new(:wrapper=>:trtd).input(:textarea, :id=>'foo').should == '<tr><td><textarea id="foo"></textarea></td></tr>'
  end

  specify "wrapper: trtd supports multiple tags in separate tds" do
    Forme::Form.new(:wrapper=>:trtd, :labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'Foo').should == '<tr><td><label for="foo">Foo</label></td><td><textarea id="foo"></textarea></td></tr>'
  end

  specify "inputs_wrapper: ol wraps tags in an ol" do
    Forme::Form.new(:inputs_wrapper=>:ol, :wrapper=>:li).inputs(:textarea).should == '<ol><li><textarea></textarea></li></ol>'
  end

  specify "inputs_wrapper: table wraps tags in an table" do
    Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs(:textarea).should == '<table><tr><td><textarea></textarea></td></tr></table>'
  end

  specify "serializer: text uses plain text output instead of html" do
    Forme::Form.new(:serializer=>:text).input(:textarea, :label=>"Foo", :value=>"Bar").should == "Foo: Bar\n\n"
    Forme::Form.new(:serializer=>:text).input(:text, :label=>"Foo", :value=>"Bar").should == "Foo: Bar\n\n"
    Forme::Form.new(:serializer=>:text).input(:radio, :label=>"Foo", :value=>"Bar").should == "___ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:radio, :label=>"Foo", :value=>"Bar", :checked=>true).should == "_X_ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:checkbox, :label=>"Foo", :value=>"Bar").should == "___ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:radio, :label=>"Foo", :value=>"Bar", :checked=>true).should == "_X_ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:select, :label=>"Foo", :options=>[1, 2, 3], :value=>2).should == "Foo: \n___ 1\n_X_ 2\n___ 3\n\n"
  end
end

describe "Forme registering custom transformers" do
  specify "should have #register_transformer register a transformer object for later use" do
    Forme::Wrapper.register_transformer(:div, proc{|t| Forme::Tag.new(:div, {}, [t])})
    Forme::Form.new(:wrapper=>:div).input(:textarea).should == '<div><textarea></textarea></div>'
  end

  specify "should have #register_transformer register a transformer block for later use" do
    Forme::Wrapper.register_transformer(:div1){|t| Forme::Tag.new(:div1, {}, [t])}
    Forme::Form.new(:wrapper=>:div1).input(:textarea).should == '<div1><textarea></textarea></div1>'
  end

  specify "should have #register_transformer register a transformer class for later use" do
    Forme::Wrapper.register_transformer(:div2, Class.new{def call(t) Forme::Tag.new(:div2, {}, [t]) end})
    Forme::Form.new(:wrapper=>:div2).input(:textarea).should == '<div2><textarea></textarea></div2>'
  end

  specify "should have #register_transformer raise an error if given a block and an object" do
    proc do
      Forme::Wrapper.register_transformer(:div1, proc{|t| t}){|t| Forme::Tag.new(:div1, {}, [t])}
    end.should raise_error(Forme::Error)
  end
end

describe "Forme object forms" do
  specify "should handle a simple case" do
    obj = Class.new{def forme_input(field, opts) Forme::Input.new(:text, :name=>"obj[#{field}]", :id=>"obj_#{field}", :value=>"#{field}_foo") end}.new 
    Forme::Form.new(obj).input(:field).should ==  '<input id="obj_field" name="obj[field]" type="text" value="field_foo"/>'
  end

  specify "should handle more complex case with multiple different types and opts" do
    obj = Class.new do 
      def self.name() "Foo" end

      attr_reader :x, :y

      def initialize(x, y)
        @x, @y = x, y
      end
      def forme_input(field, opts={})
        t = opts[:type]
        t ||= (field == :x ? :textarea : :text)
        s = field.to_s
        Forme::Input.new(t, {:label=>s.upcase, :name=>"foo[#{s}]", :id=>"foo_#{s}", :value=>send(field)}.merge!(opts))
      end
    end.new('&foo', 3)
    f = Forme::Form.new(obj)
    f.input(:x).should == '<label>X: <textarea id="foo_x" name="foo[x]">&amp;foo</textarea></label>'
    f.input(:y, :brain=>'no').should == '<label>Y: <input brain="no" id="foo_y" name="foo[y]" type="text" value="3"/></label>'
  end

  specify "should handle case where obj doesn't respond to forme_input" do
    Forme::Form.new([:foo]).input(:first).should ==  '<input id="first" name="first" type="text" value="foo"/>'
    obj = Class.new{attr_accessor :foo}.new
    obj.foo = 'bar'
    Forme::Form.new(obj).input(:foo).should ==  '<input id="foo" name="foo" type="text" value="bar"/>'
  end

  specify "should handle obj passed in via :obj hash key" do
    Forme::Form.new(:obj=>[:foo]).input(:first).should ==  '<input id="first" name="first" type="text" value="foo"/>'
  end

  specify "should be able to turn off obj handling per input using :obj=>nil option" do
    Forme::Form.new([:foo]).input(:checkbox, :name=>"foo", :hidden_value=>"no", :obj=>nil).should == '<input name="foo" type="hidden" value="no"/><input name="foo" type="checkbox"/>'
  end
end

describe "Forme.form DSL" do
  specify "should return a form tag" do
    Forme.form.should ==  '<form></form>'
  end

  specify "should yield a Form object to the block" do
    Forme.form{|f| f.should be_a_kind_of(Forme::Form)}
  end

  specify "should have inputs called instead the block be added to the existing form" do
    Forme.form{|f| f.input(:text)}.should ==  '<form><input type="text"/></form>'
  end

  specify "should be able to nest inputs inside tags" do
    Forme.form{|f| f.tag(:div){f.input(:text)}}.should ==  '<form><div><input type="text"/></div></form>'
    Forme.form{|f| f.tag(:div){f.tag(:fieldset){f.input(:text)}}}.should ==  '<form><div><fieldset><input type="text"/></fieldset></div></form>'
    Forme.form{|f| f.tag(:div){f.tag(:fieldset){f.tag(:span){f.input(:text)}}}}.should ==  '<form><div><fieldset><span><input type="text"/></span></fieldset></div></form>'
    Forme.form{|f| f.tag(:div){f.input(:text)}; f.input(:radio)}.should ==  '<form><div><input type="text"/></div><input type="radio"/></form>'
    Forme.form{|f| f.tag(:div){f.tag(:fieldset){f.input(:text);  f.input(:radio)};  f.input(:checkbox)}}.should ==  '<form><div><fieldset><input type="text"/><input type="radio"/></fieldset><input type="checkbox"/></div></form>'
  end
end

