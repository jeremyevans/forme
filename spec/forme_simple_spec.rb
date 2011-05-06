require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

describe "Forme basics" do
  include Forme

  before do
  end

  specify "form() should create an empty form" do
    form.should == '<form></form>'
  end

  specify "form(action) should create a empty form with a post action" do
    form('foo').should == '<form action="foo" method="post"></form>'
  end

  specify "form(action, :method=>:get) should create a empty form with a get action" do
    form('foo', :method=>:get).should == '<form action="foo" method="get"></form>'
  end

  specify "form{|f| f.text} should create a form with an text input field " do
    form{|f| f.text}.should == '<form><input type="text"/></form>'
  end

  specify "text should create a text input field " do
    text.should == '<input type="text"/>'
  end
end
