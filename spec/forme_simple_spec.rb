require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

describe "Forme" do
  include Forme

  specify "#text should create a text input field " do
    text.should == '<input type="text"/>'
  end

  specify "#form should create an empty form" do
    form.should == '<form></form>'
  end

  specify "#form(action) should create a empty form with a post action" do
    form('foo').should == '<form action="foo" method="post"></form>'
  end

  specify "#form(action, :method=>:get) should create a empty form with a get action" do
    form('foo', :method=>:get).should == '<form action="foo" method="get"></form>'
  end

  specify "#form should take a block and yield an argument to create tags" do
    form{|f| f.text}.should == '<form><input type="text"/></form>'
  end

  specify "#form should take a block and instance eval it if the block accepts no arguments" do
    form{text}.should == '<form><input type="text"/></form>'
  end

  specify "should be able to mix and match block argument and instance_eval modes" do
    form{|f| f.label('Text'){text}}.should == '<form><label>Text<input type="text"/></label></form>'
    form{label('Text'){|f| f.text}}.should == '<form><label>Text<input type="text"/></label></form>'
  end

  specify "tags should accept a :label option to automatically create a label" do
    form{text(:label=>'Foo')}.should == '<form><label>Foo: <input type="text"/></label></form>'
  end

  describe "object forms"
    before do
      @obj = Class.new do 
        def self.name() "Foo" end

        attr_reader :x, :y

        def initialize(x, y)
          @x, @y = x, y
        end
        def forme_tag(f, opts={})
          f == :x ? Forme::Tag.new(:textarea, {:label=>'X', :name=>'foo[x]', :id=>'foo_x', :text=>x}.merge!(opts)) : Forme::Tag.new(:input, {:label=>'Y', :name=>'foo[y]', :id=>'foo_y', :value=>y, :type=>:text}.merge!(opts))
        end
      end.new('&foo', 3)
    end

    specify "#form should accept a :obj option to set the object to use, with #input to create appropriate tags" do
      form(@obj){input [:x, :y]}.should == '<form><label>X: <textarea id="foo_x" name="foo[x]">&amp;foo</textarea></label><label>Y: <input id="foo_y" name="foo[y]" type="text" value="3"/></label></form>'
    end
  end
