require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_helper.rb')
require 'forme/bs3'

describe "Forme Bootstrap3 (BS3) forms" do
  def sel(opts, s)
    opts.map{|o| "<option #{'selected="selected" ' if o == s}value=\"#{o}\">#{sprintf("%02i", o)}</option>"}.join
  end

  before do
    @f = Forme::Form.new(:config=>:bs3)
    @ab = Album[1]
    @b = Forme::Form.new(@ab, :config=>:bs3)
    @ac = Album[2]
    @c = Forme::Form.new(@ac, :config=>:bs3)
  end
  
  describe 'input[:text]' do
    it "should create a simple input[:text] tag" do
      @f.input(:text).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/></div>'
    end
    
    it "should create an input[:text] tag with a label when ':label => Name'" do
      @f.input(:text, :label=>"Name").to_s.must_equal '<div class="form-group"><label>Name</label> <input class="form-control" type="text"/></div>'
    end
    
    it "should create an input[:text] tag with a label when ':class => bar'" do
      @f.input(:text, :label=>"Name", :class=>'bar').to_s.must_equal '<div class="form-group"><label>Name</label> <input class="form-control bar" type="text"/></div>'
    end
    
    it "should create an input[:text] tag with a label when ':id => bar'" do
      @f.input(:text, :label=>"Name", :id=>'bar').to_s.must_equal '<div class="form-group"><label for="bar">Name</label> <input class="form-control" id="bar" type="text"/></div>'
    end
    
    it "should create an input[:text] tag with a label when ':id => bar' with an error" do
      @f.input(:text, :label=>"Name", :id=>'bar', :class=>'foo', :error=>'input-text-error').to_s.must_equal '<div class="form-group has-error"><label for="bar">Name</label> <input class="form-control foo" id="bar" type="text"/><span class="help-block with-errors">input-text-error</span></div>'
    end
    
    describe 'from a Sequel model' do
      it "should create a correct input[:text] tag from Sequel model" do
        @c.input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" type="text" value="c"/></div>'
      end
      
      it "should correctly handle an input[:text] tag from Sequel model with error" do
        @ac.errors.add(:name, 'name not valid')
        @c.input(:name).to_s.must_equal '<div class="form-group has-error string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" type="text" value="c"/><span class="help-block with-errors">name not valid</span></div>'
      end
    end
  end
  
  describe 'input[:password]' do
    it "should create a simple input[:password] tag" do
      @f.input(:password).to_s.must_equal '<div class="form-group"><input class="form-control" type="password"/></div>'
    end
    
    it "should create an input[:password] tag with a label when ':label => Name'" do
      @f.input(:password, :label=>"Name").to_s.must_equal '<div class="form-group"><label>Name</label> <input class="form-control" type="password"/></div>'
    end
    
    it "should create an input[:password] tag with a label when ':class => bar'" do
      @f.input(:password, :label=>"Name", :class=>'bar').to_s.must_equal '<div class="form-group"><label>Name</label> <input class="form-control bar" type="password"/></div>'
    end
    
    it "should create an input[:password] tag with a label when ':id => bar'" do
      @f.input(:password, :label=>"Name", :id=>'bar').to_s.must_equal '<div class="form-group"><label for="bar">Name</label> <input class="form-control" id="bar" type="password"/></div>'
    end
    
    it "should create an input[:password] tag with a label when ':id => bar' with an error" do
      @f.input(:password, :label=>"Name", :id=>'bar', :class=>'foo', :error=>'input-password-error').to_s.must_equal '<div class="form-group has-error"><label for="bar">Name</label> <input class="form-control foo" id="bar" type="password"/><span class="help-block with-errors">input-password-error</span></div>'
    end
  end
  
  describe 'input[:email]' do
    it "should create a simple input[:email] tag" do
      @f.input(:email).to_s.must_equal '<div class="form-group"><input class="form-control" type="email"/></div>'
    end
    
    it "should create an input[:email] tag with a label when ':label => Name'" do
      @f.input(:email, :label=>"Name").to_s.must_equal '<div class="form-group"><label>Name</label> <input class="form-control" type="email"/></div>'
    end
    
    it "should create an input[:email] tag with a label when ':class => bar'" do
      @f.input(:email, :label=>"Name", :class=>'bar').to_s.must_equal '<div class="form-group"><label>Name</label> <input class="form-control bar" type="email"/></div>'
    end
    
    it "should create an input[:email] tag with a label when ':id => bar'" do
      @f.input(:email, :label=>"Name", :id=>'bar').to_s.must_equal '<div class="form-group"><label for="bar">Name</label> <input class="form-control" id="bar" type="email"/></div>'
    end
    
    it "should create an input[:email] tag with a label when ':id => bar' with an error" do
      @f.input(:email, :label=>"Name", :id=>'bar', :class=>'foo', :error=>'input-email-error').to_s.must_equal '<div class="form-group has-error"><label for="bar">Name</label> <input class="form-control foo" id="bar" type="email"/><span class="help-block with-errors">input-email-error</span></div>'
    end
  end
  
  describe 'input[:file]' do
    it "should create a simple input[:file] tag" do
      @f.input(:file).to_s.must_equal '<div class="form-group"><input type="file"/></div>'
    end
    
    it "should create an input[:file] tag with a label when ':label => Name'" do
      @f.input(:file, :label=>"Name").to_s.must_equal '<div class="form-group"><label>Name</label> <input type="file"/></div>'
    end
    
    it "should create an input[:file] tag with a label when ':class => bar'" do
      @f.input(:file, :label=>"Name", :class=>'bar').to_s.must_equal '<div class="form-group"><label>Name</label> <input class="bar" type="file"/></div>'
    end
    
    it "should create an input[:file] tag with a label when ':id => bar'" do
      @f.input(:file, :label=>"Name", :id=>'bar').to_s.must_equal '<div class="form-group"><label for="bar">Name</label> <input id="bar" type="file"/></div>'
    end
    
    it "should create an input[:file] tag with a label when ':id => bar' with an error" do
      @f.input(:file, :label=>"Name", :id=>'bar', :class=>'foo', :error=>'input-file-error').to_s.must_equal '<div class="form-group has-error"><label for="bar">Name</label> <input class="foo" id="bar" type="file"/><span class="help-block with-errors">input-file-error</span></div>'
    end
  end
  
  describe 'input[:submit]' do
    it "should create a simple input[:submit] tag" do
      @f.input(:submit).to_s.must_equal '<input class="btn btn-default" type="submit"/>'
    end
  
    it "should create an input[:submit] tag with the correct value" do
      @f.input(:submit, :value=>'Save').to_s.must_equal '<input class="btn btn-default" type="submit" value="Save"/>'
    end
  
    it "should create an input[:submit] tag with the correct class" do
      @f.input(:submit, :value=>'Save', :class=>'btn-primary').to_s.must_equal '<input class="btn btn-primary" type="submit" value="Save"/>'
    end
  
    it "should create an input[:submit] tag with the correct id" do
      @f.input(:submit, :value=>'Save', :id=>'foo').to_s.must_equal '<input class="btn btn-default" id="foo" type="submit" value="Save"/>'
    end
    
    it "should create an input[:submit] tag without error message " do
      @f.input(:submit, :value=>'Save', :id=>'foo', :error=>'error-message').to_s.must_equal '<input class="btn btn-default" id="foo" type="submit" value="Save"/>'
    end
  end
  
  describe 'input[:reset]' do
    it "should create a simple input[:reset] tag" do
      @f.input(:reset).to_s.must_equal '<input class="btn btn-default" type="reset"/>'
    end
  
    it "should create an input[:reset] tag with the correct value" do
      @f.input(:reset, :value=>'Save').to_s.must_equal '<input class="btn btn-default" type="reset" value="Save"/>'
    end
  
    it "should create an input[:reset] tag with the correct class" do
      @f.input(:reset, :value=>'Save', :class=>'btn-primary').to_s.must_equal '<input class="btn btn-primary" type="reset" value="Save"/>'
    end
  
    it "should create an input[:reset] tag with the correct id" do
      @f.input(:reset, :value=>'Save', :id=>'foo').to_s.must_equal '<input class="btn btn-default" id="foo" type="reset" value="Save"/>'
    end
  
    it "should create an input[:reset] tag without error message " do
      @f.input(:reset, :value=>'Save', :id=>'foo', :error=>'error-message').to_s.must_equal '<input class="btn btn-default" id="foo" type="reset" value="Save"/>'
    end
  end
  
  describe 'textarea' do
    it "should create a simple :textarea tag" do
      @f.input(:textarea).to_s.must_equal '<div class="form-group"><textarea class="form-control"></textarea></div>'
    end
  
    it "should create an :textarea tag with the correct value" do
      @f.input(:textarea, :value=>'Bio').to_s.must_equal '<div class="form-group"><textarea class="form-control">Bio</textarea></div>'
    end
  
    it "should create an :textarea tag with the correct class" do
      @f.input(:textarea, :class=>'foo').to_s.must_equal '<div class="form-group"><textarea class="form-control foo"></textarea></div>'
    end
  
    it "should create an :textarea tag with the correct id" do
      @f.input(:textarea, :id=>'bar').to_s.must_equal '<div class="form-group"><textarea class="form-control" id="bar"></textarea></div>'
    end
    
    it "should create a textarea tag without a .has-error and error message span when ':skip_error => true'" do
      @f.input(:textarea, :skip_error=>true).to_s.must_equal '<div class="form-group"><textarea class="form-control"></textarea></div>'
    end
  
    it "should create a textarea tag with .has-error and error message when ':error => is-a-string'" do
      @f.input(:textarea, :error=>'input-textarea-error').to_s.must_equal '<div class="form-group has-error"><textarea class="form-control"></textarea><span class="help-block with-errors">input-textarea-error</span></div>'
    end
    
    describe 'from a Sequel model' do
      it "should create a correct input[:text] tag from Sequel model" do
        @c.input(:name, :as=>:textarea).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <textarea class="form-control" id="album_name" maxlength="255" name="album[name]">c</textarea></div>'
      end
      
      it "should correctly handle an input[:text] tag from Sequel model with error" do
        @ac.errors.add(:name, 'name not valid')
        @c.input(:name, :as=>:textarea).to_s.must_equal '<div class="form-group has-error string"><label for="album_name">Name</label> <textarea class="form-control" id="album_name" maxlength="255" name="album[name]">c</textarea><span class="help-block with-errors">name not valid</span></div>'
      end
    end
  end
  
  describe 'select' do
    it "should create a simple :select tag" do
      @f.input(:select).to_s.must_equal '<div class="form-group"><select class="form-control"></select></div>'
    end
    
    it "should create a simple :select tag with options" do
      @f.input(:select, :options=>[[:a, 1], [:b,2]]).to_s.must_equal '<div class="form-group"><select class="form-control"><option value="1">a</option><option value="2">b</option></select></div>'
    end
  
    it "should create a simple :select tag with options and the correct value" do
      @f.input(:select, :options=>[[:a, 1], [:b,2]], :value=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option value="1">a</option><option selected="selected" value="2">b</option></select></div>'
    end
  
    it "should support :add_blank option for select inputs" do
      @f.input(:select, :options=>[[:a, 1], [:b, 2]], :add_blank=>true, :value=>1).to_s.must_equal '<div class="form-group"><select class="form-control"><option value=""></option><option selected="selected" value="1">a</option><option value="2">b</option></select></div>'
    end
    
    it "should create an :select tag with the correct class" do
      @f.input(:select, :class=>'foo').to_s.must_equal '<div class="form-group"><select class="form-control foo"></select></div>'
    end
  
    it "should create an :select tag with the correct id" do
      @f.input(:select, :id=>'bar').to_s.must_equal '<div class="form-group"><select class="form-control" id="bar"></select></div>'
    end
    
    it "should create a select tag without .has-error and error message span when ':skip_error => true'" do
      @f.input(:select, :skip_error=>true).to_s.must_equal '<div class="form-group"><select class="form-control"></select></div>'
    end
    
    it "should create a select tag with .has-error and error message when ':error => is-a-string'" do
      @f.input(:select, :error=>'input-select-error').to_s.must_equal '<div class="form-group has-error"><select class="form-control"></select><span class="help-block with-errors">input-select-error</span></div>'
    end
    
    it "should correctly handle a Sequel model output :as => :select" do
      @b.input(:artist, :as=>:select).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">a</option><option value="2">d</option></select></div>'
    end
    
    it "should correctly handle a Sequel model output :as => :select with error" do
      @ac.errors.add(:artist, 'error message')
      @c.input(:artist, :as=>:select).to_s.must_equal '<div class="form-group has-error many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a</option><option selected="selected" value="2">d</option></select><span class="help-block with-errors">error message</span></div>'
    end
    
    describe 'from a Sequel model' do
      it "should correctly handle a boolean attribute from a Sequel model" do
        @c.input(:gold).to_s.must_equal '<div class="boolean form-group"><label for="album_gold">Gold</label> <select class="form-control" id="album_gold" name="album[gold]"><option value=""></option><option selected="selected" value="t">True</option><option value="f">False</option></select></div>'
      end
      
      it "should correctly handle a boolean attribute from a Sequel model with an error" do
        @ac.errors.add(:gold, 'error message')
        @c.input(:gold).to_s.must_equal '<div class="boolean form-group has-error"><label for="album_gold">Gold</label> <select class="form-control" id="album_gold" name="album[gold]"><option value=""></option><option selected="selected" value="t">True</option><option value="f">False</option></select><span class="help-block with-errors">error message</span></div>'
      end
    end
  end
  
  describe 'input[:checkbox]' do
    it "should create a simple input[:checkbox] tag" do
      @f.input(:checkbox).to_s.must_equal '<div class="checkbox"><input type="checkbox"/></div>'
    end
  
    it "should create an input[:checkbox] tag with a label when ':label => Gold'" do
      @f.input(:checkbox, :label=>"Gold").to_s.must_equal '<div class="checkbox"><label><input type="checkbox"/> Gold</label></div>'
    end
    
    it "should create an input[:checkbox] tag with a label when ':class => bar'" do
      @f.input(:checkbox, :label=>"Gold", :class=>'bar').to_s.must_equal '<div class="checkbox"><label><input class="bar" type="checkbox"/> Gold</label></div>'
    end
    
    it "should create an input[:checkbox] tag with a label when ':id => bar'" do
      @f.input(:checkbox, :label=>"Gold", :id=>'bar').to_s.must_equal '<div class="checkbox"><label for="bar"><input id="bar" type="checkbox"/> Gold</label></div>'
    end
    
    it "should create an input[:checkbox] tag with a label when ':id => bar' with an error" do
      @f.input(:checkbox, :label=>"Gold", :id=>'bar', :class=>'foo', :error=>'input-checkbox-error').to_s.must_equal '<div class="has-error"><div class="checkbox"><label for="bar"><input class="foo" id="bar" type="checkbox"/> Gold</label></div><span class="help-block with-errors">input-checkbox-error</span></div>'
    end
    
    describe 'from a Sequel model' do
      it "should correctly handle a boolean attribute ':as=>:checkbox'" do
        @c.input(:gold, :as=>:checkbox).to_s.must_equal '<div class="boolean checkbox"><label for="album_gold"><input id="album_gold_hidden" name="album[gold]" type="hidden" value="f"/><input checked="checked" id="album_gold" name="album[gold]" type="checkbox" value="t"/> Gold</label></div>'
      end
    
      it "should correctly handle a boolean attribute ':as=>:checkbox' with an error" do
        @ac.errors.add(:gold, 'error message')
        @c.input(:gold, :as=>:checkbox).to_s.must_equal '<div class="boolean has-error"><div class="checkbox"><label for="album_gold"><input id="album_gold_hidden" name="album[gold]" type="hidden" value="f"/><input checked="checked" id="album_gold" name="album[gold]" type="checkbox" value="t"/> Gold</label></div><span class="help-block with-errors">error message</span></div>'
      end
    end
  end
  
  
  describe 'input[:radio]' do
    it "should create a simple input[:radio] tag" do
      @f.input(:radio).to_s.must_equal '<div class="radio"><input type="radio"/></div>'
    end
  
    it "should create an input[:radio] tag with a label when ':label => Gold'" do
      @f.input(:radio, :label=>"Gold").to_s.must_equal '<div class="radio"><label><input type="radio"/> Gold</label></div>'
    end
    
    it "should create an input[:radio] tag with a label when ':class => bar'" do
      @f.input(:radio, :label=>"Gold", :class=>'bar').to_s.must_equal '<div class="radio"><label><input class="bar" type="radio"/> Gold</label></div>'
    end
    
    it "should create an input[:radio] tag with a label when ':id => bar'" do
      @f.input(:radio, :label=>"Gold", :id=>'bar').to_s.must_equal '<div class="radio"><label for="bar"><input id="bar" type="radio"/> Gold</label></div>'
    end
    
    it "should create an input[:radio] tag with a label when ':id => bar' with an error" do
      @f.input(:radio, :label=>"Gold", :id=>'bar', :class=>'foo', :error=>'input-radio-error').to_s.must_equal '<div class="has-error"><div class="radio"><label for="bar"><input class="foo" id="bar" type="radio"/> Gold</label></div><span class="help-block with-errors">input-radio-error</span></div>'
    end
    
    describe 'from a Sequel model' do
      it "should correctly handle a boolean attribute ':as=>:radio'" do
        @c.input(:gold, :as=>:radio).to_s.must_equal '<div class="boolean radioset"><label>Gold</label><div class="radio"><label class="option" for="album_gold_yes"><input checked="checked" id="album_gold_yes" name="album[gold]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_gold_no"><input id="album_gold_no" name="album[gold]" type="radio" value="f"/> No</label></div></div>'
      end
      
      it "should correctly handle a boolean attribute ':as=>:radio' with an error" do
        @ac.errors.add(:gold, 'error message')
        @c.input(:gold, :as=>:radio).to_s.must_equal '<div class="boolean radioset has-error"><label>Gold</label><div class="radio"><label class="option" for="album_gold_yes"><input checked="checked" id="album_gold_yes" name="album[gold]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_gold_no"><input id="album_gold_no" name="album[gold]" type="radio" value="f"/> No</label></div><span class="help-block with-errors">error message</span></div>'
      end
    end
  end
  
  
  it "should correctly handle a :checkboxset tag" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b,2]]).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option"><input type="checkbox" value="1"/> a</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="2"/> b</label></div></div>'
  end
  
  it "should correctly handle a :checkboxset tag without options" do
    @f.input(:checkboxset, :options=>[]).to_s.must_equal '<div class="checkboxset"></div>'
  end
  
  it "should correctly handle a :checkboxset tag with an error - Alternative A: (see BS3 HTML reference)" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b,2]], :error=>'error message').to_s.must_equal '<div class="checkboxset has-error"><div class="checkbox"><label class="option"><input type="checkbox" value="1"/> a</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="2"/> b</label></div><span class="help-block with-errors">error message</span></div>'
  end

  it "should correctly handle a :checkboxset tag with an error and label - Alternative A: (see BS3 HTML reference)" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b,2]], :error=>'error message', :label=>'CheckboxSet').to_s.must_equal '<div class="checkboxset has-error"><label>CheckboxSet</label><div class="checkbox"><label class="option"><input type="checkbox" value="1"/> a</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="2"/> b</label></div><span class="help-block with-errors">error message</span></div>'
  end

  it "should correctly handle a :radioset tag" do
    @f.input(:radioset, :options=>[[:a, 1], [:b,2]]).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option"><input type="radio" value="1"/> a</label></div><div class="radio"><label class="option"><input type="radio" value="2"/> b</label></div></div>'
  end
  
  it "should correctly handle a :radioset tag without options" do
    @f.input(:radioset, :options=>[]).to_s.must_equal '<div class="radioset"></div>'
  end
  
  it "should correctly handle a :radioset tag with an error - Alternative A: (see BS3 HTML reference)" do
    @f.input(:radioset, :options=>[[:a, 1], [:b,2]], :error=>'error message').to_s.must_equal '<div class="radioset has-error"><div class="radio"><label class="option"><input type="radio" value="1"/> a</label></div><div class="radio"><label class="option"><input type="radio" value="2"/> b</label></div><span class="help-block with-errors">error message</span></div>'
  end
  
  it "should correctly handle a :radioset tag with an error and label - Alternative A: (see BS3 HTML reference)" do
    @f.input(:radioset, :options=>[[:a, 1], [:b,2]], :error=>'error message', :label=>'RadioSet').to_s.must_equal '<div class="radioset has-error"><label>RadioSet</label><div class="radio"><label class="option"><input type="radio" value="1"/> a</label></div><div class="radio"><label class="option"><input type="radio" value="2"/> b</label></div><span class="help-block with-errors">error message</span></div>'
  end
  
  it "should use a set of radio buttons for many_to_one associations with :as=>:radio option" do
    @b.input(:artist, :as=>:radio).to_s.must_equal '<div class="many_to_one radioset"><label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></div>'
    @b.input(:artist, :as=>:radio, :wrapper=>nil).to_s.must_equal '<label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div>'
    @c.input(:artist, :as=>:radio).to_s.must_equal '<div class="many_to_one radioset"><label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input checked="checked" id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></div>'
    @c.input(:artist, :as=>:radio, :wrapper=>:div).to_s.must_equal '<div class="many_to_one radioset"><label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input checked="checked" id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></div>'
  end
end
