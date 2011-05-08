require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

describe "Forme" do
  include Forme

  specify "should create a simple input tags" do
    text.should == '<input type="text"/>'
    radio.should == '<input type="radio"/>'
  end

  specify "should create other tags" do
    textarea.should == '<textarea></textarea>'
    fieldset.should == '<fieldset></fieldset>'
  end

  specify "should allow easy specifying of text as separate option for common tags containing text" do
    textarea('foo').should == '<textarea>foo</textarea>'
    p('bar').should == '<p>bar</p>'
  end

  specify "should use html attributes specified in options" do
    text(:value=>'foo').should == '<input type="text" value="foo"/>'
    div(:class=>'bar').should == '<div class="bar"></div>'
  end

  specify "should support html attributes and text for text tags" do
    textarea('foo', :name=>'bar').should == '<textarea name="bar">foo</textarea>'
  end

  specify "should support just html attributes options for common tags containing text" do
    textarea(:name=>'bar').should == '<textarea name="bar"></textarea>'
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
