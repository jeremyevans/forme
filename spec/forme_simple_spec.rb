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
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).should == '<select><option></option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
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

  specify "#tag! should return a Forme::Tag object" do
    t = @f.tag!(:textarea)
    t.should be_a_kind_of(Forme::Tag)
    t.type.should == :textarea
    t.attr.should == {}
  end

  specify "Forme::Tag#<< should add children to the tag" do
    t  = @f.tag!(:textarea)
    t << "foo"
    @f.tag(:div, {}, t).should == "<div><textarea>foo</textarea></div>"
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
end

describe "Forme built-in custom" do
  specify "labeler: explicit uses an explicit label with for attribute" do
    Forme::Form.new(:labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'bar').should == '<label for="foo">bar</label><textarea id="foo"></textarea>'
  end

  specify "wrapper: li wraps tag in an li" do
    Forme::Form.new(:wrapper=>:li).input(:textarea, :id=>'foo').should == '<li><textarea id="foo"></textarea></li>'
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
