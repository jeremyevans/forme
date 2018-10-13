require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_helper.rb')
require 'forme/bs3'

describe "Forme Sequel::Model BS3 forms" do
  before do
    @ab = Album[1]
    @b = Forme::Form.new(@ab, :config=>:bs3)
    @ac = Album[2]
    @c = Forme::Form.new(@ac, :config=>:bs3)
  end
  
  it "should add appropriate attributes by default" do
    @b.form.to_s.must_equal '<form class="forme album" method="post"></form>'
  end

  it "should allow overriding of attributes" do
    @b.form(:class=>:foo, :method=>:get).to_s.must_equal '<form class="foo forme album" method="get"></form>'
  end

  it "should handle invalid methods" do
    def @ab.db_schema
      super.merge(:foo=>{:type=>:bar})
    end
    @b.input(:foo, :value=>'baz').to_s.must_equal '<div class="bar form-group"><label for="album_foo">Foo</label> <input class="form-control" id="album_foo" name="album[foo]" type="text" value="baz"/></div>'
  end

  it "should allow an array of classes" do
    @b.form(:class=>[:foo, :bar]).to_s.must_equal '<form class="foo bar forme album" method="post"></form>'
    @b.form(:class=>[:foo, [:bar, :baz]]).to_s.must_equal '<form class="foo bar baz forme album" method="post"></form>'
  end

  it "should use a text field for strings" do
    @b.input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" type="text" value="b"/></div>'
    @c.input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" type="text" value="c"/></div>'
  end

  it "should allow :as=>:textarea to use a textarea" do
    @b.input(:name, :as=>:textarea).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <textarea class="form-control" id="album_name" maxlength="255" name="album[name]">b</textarea></div>'
    @c.input(:name, :as=>:textarea).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <textarea class="form-control" id="album_name" maxlength="255" name="album[name]">c</textarea></div>'
  end

  it "should allow :type=>:textarea to use a textarea" do
    @b.input(:name, :type=>:textarea).to_s.must_equal '<div class="form-group"><label for="album_name">Name</label> <textarea class="form-control" id="album_name" maxlength="255" name="album[name]">b</textarea></div>'
    @c.input(:name, :type=>:textarea).to_s.must_equal '<div class="form-group"><label for="album_name">Name</label> <textarea class="form-control" id="album_name" maxlength="255" name="album[name]">c</textarea></div>'
  end

  it "should use number inputs for integers" do
    @b.input(:copies_sold).to_s.must_equal '<div class="form-group integer"><label for="album_copies_sold">Copies sold</label> <input class="form-control" id="album_copies_sold" name="album[copies_sold]" type="number" value="10"/></div>'
  end

  it "should use date inputs for Dates" do
    @b.input(:release_date).to_s.must_equal '<div class="date form-group"><label for="album_release_date">Release date</label> <input class="form-control" id="album_release_date" name="album[release_date]" type="date" value="2011-06-05"/></div>'
  end

  it "should use datetime inputs for Time" do
    @b.input(:created_at).to_s.must_match %r{<div class="datetime form-group"><label for="album_created_at">Created at</label> <input class="form-control" id="album_created_at" name="album\[created_at\]" type="datetime-local" value="2011-06-05T00:00:00.000"/></div>}
  end

  it "should use datetime inputs for DateTimes" do
    @ab.values[:created_at] = DateTime.new(2011, 6, 5)
    @b.input(:created_at).to_s.must_equal '<div class="datetime form-group"><label for="album_created_at">Created at</label> <input class="form-control" id="album_created_at" name="album[created_at]" type="datetime-local" value="2011-06-05T00:00:00.000"/></div>'
  end

  it "should include type as wrapper class" do
    @ab.values[:created_at] = DateTime.new(2011, 6, 5)
    f = Forme::Form.new(@ab, :config=>:bs3)
    f.input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" type="text" value="b"/></div>'
    f.input(:release_date).to_s.must_equal '<div class="date form-group"><label for="album_release_date">Release date</label> <input class="form-control" id="album_release_date" name="album[release_date]" type="date" value="2011-06-05"/></div>'
    f.input(:created_at).to_s.must_equal '<div class="datetime form-group"><label for="album_created_at">Created at</label> <input class="form-control" id="album_created_at" name="album[created_at]" type="datetime-local" value="2011-06-05T00:00:00.000"/></div>'
  end

  it "should include required * in label if required" do
    @b.input(:name, :required=>true).to_s.must_equal '<div class="form-group required string"><label for="album_name">Name<abbr title="required">*</abbr></label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/></div>'
  end

  it "should add required to label even if :label option specified" do
    @b.input(:name, :required=>true, :label=>'Foo').to_s.must_equal '<div class="form-group required string"><label for="album_name">Foo<abbr title="required">*</abbr></label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/></div>'
  end

  it "should include required wrapper class if required" do
    f = Forme::Form.new(@ab, :config=>:bs3, :wrapper=>:li)
    f.input(:name, :required=>true).to_s.must_equal '<li class="string required"><label for="album_name">Name<abbr title="required">*</abbr></label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/></li>'
  end

  it "should use a select box for tri-valued boolean fields" do
    @b.input(:gold).to_s.must_equal '<div class="boolean form-group"><label for="album_gold">Gold</label> <select class="form-control" id="album_gold" name="album[gold]"><option value=""></option><option value="t">True</option><option selected="selected" value="f">False</option></select></div>'
    @c.input(:gold).to_s.must_equal '<div class="boolean form-group"><label for="album_gold">Gold</label> <select class="form-control" id="album_gold" name="album[gold]"><option value=""></option><option selected="selected" value="t">True</option><option value="f">False</option></select></div>'
  end

  it "should respect :true_label and :false_label options for tri-valued boolean fields" do
    @b.input(:gold, :true_label=>"Foo", :false_label=>"Bar").to_s.must_equal '<div class="boolean form-group"><label for="album_gold">Gold</label> <select class="form-control" id="album_gold" name="album[gold]"><option value=""></option><option value="t">Foo</option><option selected="selected" value="f">Bar</option></select></div>'
  end

  it "should respect :true_value and :false_value options for tri-valued boolean fields" do
    @b.input(:gold, :true_value=>"Foo", :false_value=>"Bar").to_s.must_equal '<div class="boolean form-group"><label for="album_gold">Gold</label> <select class="form-control" id="album_gold" name="album[gold]"><option value=""></option><option value="Foo">True</option><option value="Bar">False</option></select></div>'
  end

  it "should respect :add_blank option for tri-valued boolean fields" do
    @b.input(:gold, :add_blank=>'NULL').to_s.must_equal '<div class="boolean form-group"><label for="album_gold">Gold</label> <select class="form-control" id="album_gold" name="album[gold]"><option value="">NULL</option><option value="t">True</option><option selected="selected" value="f">False</option></select></div>'
  end

  it "should use a select box for dual-valued boolean fields where :required => false" do
    @b.input(:platinum, :required=>false).to_s.must_equal '<div class="boolean form-group"><label for="album_platinum">Platinum</label> <select class="form-control" id="album_platinum" name="album[platinum]"><option value=""></option><option value="t">True</option><option selected="selected" value="f">False</option></select></div>'
    @c.input(:platinum, :required=>false).to_s.must_equal '<div class="boolean form-group"><label for="album_platinum">Platinum</label> <select class="form-control" id="album_platinum" name="album[platinum]"><option value=""></option><option selected="selected" value="t">True</option><option value="f">False</option></select></div>'
  end

  it "should use a checkbox for dual-valued boolean fields" do
    @b.input(:platinum).to_s.must_equal '<div class="boolean checkbox"><label for="album_platinum"><input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><input id="album_platinum" name="album[platinum]" type="checkbox" value="t"/> Platinum</label></div>'
    @c.input(:platinum).to_s.must_equal '<div class="boolean checkbox"><label for="album_platinum"><input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><input checked="checked" id="album_platinum" name="album[platinum]" type="checkbox" value="t"/> Platinum</label></div>'
  end

  it "should use radio buttons for boolean fields if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio).to_s.must_equal '<div class="boolean radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div></div>'
    @c.input(:platinum, :as=>:radio).to_s.must_equal '<div class="boolean radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input checked="checked" id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div></div>'
  end

  it "should wrap both inputs if :as=>:radio is used" do
    @b = Forme::Form.new(@ab, :config=>:bs3, :wrapper=>:li)
    @b.input(:platinum, :as=>:radio).to_s.must_equal '<div class="boolean radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div></div>'
    @b.input(:platinum, :as=>:radio,:wrapper=>:li).to_s.must_equal '<li class="boolean radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div></li>'
    @b.input(:platinum, :as=>:radio, :wrapper=>:div, :tag_wrapper=>:span).to_s.must_equal '<div class="boolean radioset"><label>Platinum</label><span><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></span><span><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></span></div>'
  end

  it "should handle errors on radio buttons for boolean fields if :as=>:radio is used" do
    @ab.errors.add(:platinum, 'foo')
    @b.input(:platinum, :as=>:radio).to_s.must_equal '<div class="boolean radioset has-error"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div><span class="help-block with-errors">foo</span></div>'
    @b.input(:platinum, :as=>:radio, :wrapper=>:li).to_s.must_equal '<li class="boolean radioset has-error"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div><span class="help-block with-errors">foo</span></li>'
    @b.input(:platinum, :as=>:radio, :wrapper=>:bs3).to_s.must_equal '<div class="boolean form-group has-error radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div><span class="help-block with-errors">foo</span></div>'
  end

  it "should handle Raw :label options if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio, :label=>Forme.raw('Foo:<br />')).to_s.must_equal '<div class="boolean radioset"><label>Foo:<br /></label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div></div>'
    @b.input(:platinum, :as=>:radio, :label=>'Foo:<br />').to_s.must_equal '<div class="boolean radioset"><label>Foo:&lt;br /&gt;</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div></div>'
    @b.input(:platinum, :as=>:radio, :label=>'Foo:<br />', :wrapper=>nil).to_s.must_equal '<label>Foo:&lt;br /&gt;</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div>'
    @b.input(:platinum, :as=>:radio, :label=>'Foo:<br />', :wrapper=>:li).to_s.must_equal '<li class="boolean radioset"><label>Foo:&lt;br /&gt;</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div></li>'
    @b.input(:platinum, :as=>:radio, :label=>'Foo:<br />', :wrapper=>:bs3).to_s.must_equal '<div class="boolean form-group radioset"><label>Foo:&lt;br /&gt;</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></div></div>'
  end
  
  it "should respect :true_label and :false_label options for boolean fields if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio, :true_label=>"Foo", :false_label=>"Bar").to_s.must_equal '<div class="boolean radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Foo</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> Bar</label></div></div>'
    @b.input(:platinum, :as=>:radio, :true_label=>"Foo", :false_label=>"Bar",:wrapper=>nil).to_s.must_equal '<label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Foo</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> Bar</label></div>'
    @b.input(:platinum, :as=>:radio, :true_label=>"Foo", :false_label=>"Bar",:wrapper=>:li).to_s.must_equal '<li class="boolean radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Foo</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> Bar</label></div></li>'
    @b.input(:platinum, :as=>:radio, :true_label=>"Foo", :false_label=>"Bar",:wrapper=>:bs3).to_s.must_equal '<div class="boolean form-group radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Foo</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> Bar</label></div></div>'
  end

  it "should respect :true_value and :false_value options for boolean fields if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio, :true_value=>"Foo", :false_value=>"Bar").to_s.must_equal '<div class="boolean radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="Foo"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="Bar"/> No</label></div></div>'
    @b.input(:platinum, :as=>:radio, :true_value=>"Foo", :false_value=>"Bar", :wrapper=>nil).to_s.must_equal '<label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="Foo"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="Bar"/> No</label></div>'
    @b.input(:platinum, :as=>:radio, :true_value=>"Foo", :false_value=>"Bar", :wrapper=>:li).to_s.must_equal '<li class="boolean radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="Foo"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="Bar"/> No</label></div></li>'
    @b.input(:platinum, :as=>:radio, :true_value=>"Foo", :false_value=>"Bar", :wrapper=>:bs3).to_s.must_equal '<div class="boolean form-group radioset"><label>Platinum</label><div class="radio"><label class="option" for="album_platinum_yes"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="Foo"/> Yes</label></div><div class="radio"><label class="option" for="album_platinum_no"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="Bar"/> No</label></div></div>'
  end

  it "should use a select box for many_to_one associations" do
    @b.input(:artist).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">a</option><option value="2">d</option></select></div>'
    @c.input(:artist).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a</option><option selected="selected" value="2">d</option></select></div>'
  end

  it "should not add a blank option by default if there is a default value and it is required" do
    @b.input(:artist, :required=>true).to_s.must_equal '<div class="form-group many_to_one required"><label for="album_artist_id">Artist<abbr title="required">*</abbr></label> <select class="form-control" id="album_artist_id" name="album[artist_id]" required="required"><option selected="selected" value="1">a</option><option value="2">d</option></select></div>'
  end

  it "should allow overriding default input type using a :type option" do
    @b.input(:artist, :type=>:string, :value=>nil).to_s.must_equal '<div class="form-group"><label for="album_artist">Artist</label> <input class="form-control" id="album_artist" name="album[artist]" type="text"/></div>'
  end

  it "should use a required wrapper tag for many_to_one required associations" do
    @b.input(:artist, :required=>true, :wrapper=>:li).to_s.must_equal '<li class="many_to_one required"><label for="album_artist_id">Artist<abbr title="required">*</abbr></label> <select class="form-control" id="album_artist_id" name="album[artist_id]" required="required"><option selected="selected" value="1">a</option><option value="2">d</option></select></li>'
  end

  it "should use a set of radio buttons for many_to_one associations with :as=>:radio option" do
    @b.input(:artist, :as=>:radio).to_s.must_equal '<div class="many_to_one radioset"><label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></div>'
    @b.input(:artist, :as=>:radio, :wrapper=>nil).to_s.must_equal '<label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div>'
    @c.input(:artist, :as=>:radio).to_s.must_equal '<div class="many_to_one radioset"><label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input checked="checked" id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></div>'
    @c.input(:artist, :as=>:radio, :wrapper=>:div).to_s.must_equal '<div class="many_to_one radioset"><label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input checked="checked" id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></div>'
  end

  it "should handle Raw label for many_to_one associations with :as=>:radio option" do
    @b.input(:artist, :as=>:radio, :label=>Forme.raw('Foo:<br />')).to_s.must_equal '<div class="many_to_one radioset"><label>Foo:<br /></label><div class="radio"><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></div>'
    @b.input(:artist, :as=>:radio, :label=>'Foo<br />').to_s.must_equal '<div class="many_to_one radioset"><label>Foo&lt;br /&gt;</label><div class="radio"><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></div>'
  end

  it "should correctly use the forms wrapper for wrapping radio buttons for many_to_one associations with :as=>:radio option" do
    @b = Forme::Form.new(@ab, :config=>:bs3, :wrapper=>:li)
    @b.input(:artist, :as=>:radio).to_s.must_equal '<div class="many_to_one radioset"><label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></div>'
    @b.input(:artist, :as=>:radio,:wrapper=>:li).to_s.must_equal '<li class="many_to_one radioset"><label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div></li>'
    @b.input(:artist, :as=>:radio,:wrapper=>nil).to_s.must_equal '<label>Artist</label><div class="radio"><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></div><div class="radio"><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></div>'
  end

  it "should support custom wrappers for many_to_one associations with :as=>:radio via :tag_wrapper option" do
    @b = Forme::Form.new(@ab, :config=>:bs3, :wrapper=>:li)
    @b.input(:artist, :as=>:radio, :wrapper=>proc{|t, i| i.tag(:div, {}, [t])}, :tag_wrapper=>proc{|t, i| i.tag(:span, {}, [t])}).to_s.must_equal '<div><label>Artist</label><span><label class="option" for="album_artist_id_1"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></span><span><label class="option" for="album_artist_id_2"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></span></div>'
  end

  it "should respect an :options entry" do
    @b.input(:artist, :options=>Artist.order(:name).map{|a| [a.name, a.id+1]}).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="2">a</option><option value="3">d</option></select></div>'
    @c.input(:artist, :options=>Artist.order(:name).map{|a| [a.name, a.id+1]}).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="2">a</option><option value="3">d</option></select></div>'
  end

  it "should support :name_method option for choosing name method" do
    @b.input(:artist, :name_method=>:idname).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">1a</option><option value="2">2d</option></select></div>'
    @c.input(:artist, :name_method=>:idname).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">1a</option><option selected="selected" value="2">2d</option></select></div>'
  end

  it "should support :name_method option being a callable object" do
    @b.input(:artist, :name_method=>lambda{|obj| obj.idname * 2}).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">1a1a</option><option value="2">2d2d</option></select></div>'
    @c.input(:artist, :name_method=>lambda{|obj| obj.idname * 2}).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">1a1a</option><option selected="selected" value="2">2d2d</option></select></div>'
  end

  it "should support :dataset option providing dataset to search" do
    @b.input(:artist, :dataset=>Artist.reverse_order(:name)).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="2">d</option><option selected="selected" value="1">a</option></select></div>'
    @c.input(:artist, :dataset=>Artist.reverse_order(:name)).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="2">d</option><option value="1">a</option></select></div>'
  end

  it "should support :dataset option being a callback proc returning modified dataset to search" do
    @b.input(:artist, :dataset=>proc{|ds| ds.reverse_order(:name)}).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="2">d</option><option selected="selected" value="1">a</option></select></div>'
    @c.input(:artist, :dataset=>proc{|ds| ds.reverse_order(:name)}).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="2">d</option><option value="1">a</option></select></div>'
  end

  it "should try a list of methods to get a suitable one for select box naming" do
    al = Class.new(Album){def self.name() 'Album' end}
    ar = Class.new(Artist)
    al.many_to_one :artist, :class=>ar
    ar.class_eval{undef_method(:name)}
    f = Forme::Form.new(al.new, { :config=>:bs3 })

    ar.class_eval{def number() "#{self[:name]}1" end}
    f.input(:artist).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a1</option><option value="2">d1</option></select></div>'

    ar.class_eval{def title() "#{self[:name]}2" end}
    f.input(:artist).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a2</option><option value="2">d2</option></select></div>'

    ar.class_eval{def name() "#{self[:name]}3" end}
    f.input(:artist).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a3</option><option value="2">d3</option></select></div>'

    ar.class_eval{def forme_name() "#{self[:name]}4" end}
    f.input(:artist).to_s.must_equal '<div class="form-group many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a4</option><option value="2">d4</option></select></div>'
  end

  it "should raise an error when using an association without a usable name method" do
    al = Class.new(Album)
    ar = Class.new(Artist)
    al.many_to_one :artist, :class=>ar
    ar.class_eval{undef_method(:name)}
    proc{Forme::Form.new(al.new, :config=>:bs3).input(:artist)}.must_raise(Sequel::Plugins::Forme::Error)
  end

  it "should use a multiple select box for one_to_many associations" do
    @b.input(:tracks).to_s.must_equal '<div class="form-group one_to_many"><label for="album_track_pks">Tracks</label> <select class="form-control" id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option selected="selected" value="1">m</option><option selected="selected" value="2">n</option><option value="3">o</option></select></div>'
    @c.input(:tracks).to_s.must_equal '<div class="form-group one_to_many"><label for="album_track_pks">Tracks</label> <select class="form-control" id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option value="1">m</option><option value="2">n</option><option selected="selected" value="3">o</option></select></div>'
  end

  it "should use a multiple select box for many_to_many associations" do
    @b.input(:tags).to_s.must_equal '<div class="form-group many_to_many"><label for="album_tag_pks">Tags</label> <select class="form-control" id="album_tag_pks" multiple="multiple" name="album[tag_pks][]"><option selected="selected" value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></div>'
    @c.input(:tags).to_s.must_equal '<div class="form-group many_to_many"><label for="album_tag_pks">Tags</label> <select class="form-control" id="album_tag_pks" multiple="multiple" name="album[tag_pks][]"><option value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></div>'
  end

  it "should use a multiple select box for pg_array_to_many associations" do
    @b.input(:atags).to_s.must_equal '<div class="form-group pg_array_to_many"><label for="album_atag_ids">Atags</label> <select class="form-control" id="album_atag_ids" multiple="multiple" name="album[atag_ids][]"><option selected="selected" value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></div>'
    @c.obj.atag_ids.delete(1)
    @c.input(:atags).to_s.must_equal '<div class="form-group pg_array_to_many"><label for="album_atag_ids">Atags</label> <select class="form-control" id="album_atag_ids" multiple="multiple" name="album[atag_ids][]"><option value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></div>'
  end

  it "should handle an error message on the underlying column for pg_array_to_many associations" do
    @ab.errors.add(:atag_ids, 'tis not valid')
    @b.input(:atags).to_s.must_equal '<div class="form-group has-error pg_array_to_many"><label for="album_atag_ids">Atags</label> <select class="form-control" id="album_atag_ids" multiple="multiple" name="album[atag_ids][]"><option selected="selected" value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select><span class="help-block with-errors">tis not valid</span></div>'
    @b.input(:atags, :as=>:checkbox).to_s.must_equal '<div class="pg_array_to_many checkboxset has-error"><label>Atags</label><div class="checkbox"><label class="option" for="album_atag_ids_1"><input checked="checked" id="album_atag_ids_1" name="album[atag_ids][]" type="checkbox" value="1"/> s</label></div><div class="checkbox"><label class="option" for="album_atag_ids_2"><input checked="checked" id="album_atag_ids_2" name="album[atag_ids][]" type="checkbox" value="2"/> t</label></div><div class="checkbox"><label class="option" for="album_atag_ids_3"><input id="album_atag_ids_3" name="album[atag_ids][]" type="checkbox" value="3"/> u</label></div><span class="help-block with-errors">tis not valid</span></div>'
    @b.input(:atags, :as=>:checkbox,:wrapper=>:li).to_s.must_equal '<li class="pg_array_to_many checkboxset has-error"><label>Atags</label><div class="checkbox"><label class="option" for="album_atag_ids_1"><input checked="checked" id="album_atag_ids_1" name="album[atag_ids][]" type="checkbox" value="1"/> s</label></div><div class="checkbox"><label class="option" for="album_atag_ids_2"><input checked="checked" id="album_atag_ids_2" name="album[atag_ids][]" type="checkbox" value="2"/> t</label></div><div class="checkbox"><label class="option" for="album_atag_ids_3"><input id="album_atag_ids_3" name="album[atag_ids][]" type="checkbox" value="3"/> u</label></div><span class="help-block with-errors">tis not valid</span></li>'
  end

  it "should use a regular select box for *_to_many associations if multiple if false" do
    @b.input(:tracks, :multiple=>false).to_s.must_equal '<div class="form-group one_to_many"><label for="album_track_pks">Tracks</label> <select class="form-control" id="album_track_pks" name="album[track_pks][]"><option value="1">m</option><option value="2">n</option><option value="3">o</option></select></div>'
    @c.input(:tags, :multiple=>false).to_s.must_equal '<div class="form-group many_to_many"><label for="album_tag_pks">Tags</label> <select class="form-control" id="album_tag_pks" name="album[tag_pks][]"><option value="1">s</option><option value="2">t</option><option value="3">u</option></select></div>'
  end

  it "should use multiple checkboxes for one_to_many associations if :as=>:checkbox" do
    @b.input(:tracks).to_s.must_equal '<div class="form-group one_to_many"><label for="album_track_pks">Tracks</label> <select class="form-control" id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option selected="selected" value="1">m</option><option selected="selected" value="2">n</option><option value="3">o</option></select></div>'
    @b.input(:tracks, :as=>:checkbox).to_s.must_equal '<div class="one_to_many checkboxset"><label>Tracks</label><div class="checkbox"><label class="option" for="album_track_pks_1"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label></div><div class="checkbox"><label class="option" for="album_track_pks_2"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label></div><div class="checkbox"><label class="option" for="album_track_pks_3"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label></div></div>'
    @c.input(:tracks, :as=>:checkbox,:wrapper=>:li).to_s.must_equal '<li class="one_to_many checkboxset"><label>Tracks</label><div class="checkbox"><label class="option" for="album_track_pks_1"><input id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label></div><div class="checkbox"><label class="option" for="album_track_pks_2"><input id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label></div><div class="checkbox"><label class="option" for="album_track_pks_3"><input checked="checked" id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label></div></li>'
  end

  it "should use multiple checkboxes for many_to_many associations if :as=>:checkbox" do
    @b.input(:tags, :as=>:checkbox).to_s.must_equal '<div class="many_to_many checkboxset"><label>Tags</label><div class="checkbox"><label class="option" for="album_tag_pks_1"><input checked="checked" id="album_tag_pks_1" name="album[tag_pks][]" type="checkbox" value="1"/> s</label></div><div class="checkbox"><label class="option" for="album_tag_pks_2"><input checked="checked" id="album_tag_pks_2" name="album[tag_pks][]" type="checkbox" value="2"/> t</label></div><div class="checkbox"><label class="option" for="album_tag_pks_3"><input id="album_tag_pks_3" name="album[tag_pks][]" type="checkbox" value="3"/> u</label></div></div>'
    @c.input(:tags, :as=>:checkbox).to_s.must_equal '<div class="many_to_many checkboxset"><label>Tags</label><div class="checkbox"><label class="option" for="album_tag_pks_1"><input id="album_tag_pks_1" name="album[tag_pks][]" type="checkbox" value="1"/> s</label></div><div class="checkbox"><label class="option" for="album_tag_pks_2"><input checked="checked" id="album_tag_pks_2" name="album[tag_pks][]" type="checkbox" value="2"/> t</label></div><div class="checkbox"><label class="option" for="album_tag_pks_3"><input id="album_tag_pks_3" name="album[tag_pks][]" type="checkbox" value="3"/> u</label></div></div>'
    @c.input(:tags, :as=>:checkbox, :wrapper=>:div).to_s.must_equal '<div class="many_to_many checkboxset"><label>Tags</label><div class="checkbox"><label class="option" for="album_tag_pks_1"><input id="album_tag_pks_1" name="album[tag_pks][]" type="checkbox" value="1"/> s</label></div><div class="checkbox"><label class="option" for="album_tag_pks_2"><input checked="checked" id="album_tag_pks_2" name="album[tag_pks][]" type="checkbox" value="2"/> t</label></div><div class="checkbox"><label class="option" for="album_tag_pks_3"><input id="album_tag_pks_3" name="album[tag_pks][]" type="checkbox" value="3"/> u</label></div></div>'
  end

  it "should handle Raw label for associations with :as=>:checkbox" do
    @b.input(:tracks, :as=>:checkbox, :label=>'Foo<br />').to_s.must_equal '<div class="one_to_many checkboxset"><label>Foo&lt;br /&gt;</label><div class="checkbox"><label class="option" for="album_track_pks_1"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label></div><div class="checkbox"><label class="option" for="album_track_pks_2"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label></div><div class="checkbox"><label class="option" for="album_track_pks_3"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label></div></div>'
    @b.input(:tracks, :as=>:checkbox, :label=>'Foo<br />',:wrapper=>:div).to_s.must_equal '<div class="one_to_many checkboxset"><label>Foo&lt;br /&gt;</label><div class="checkbox"><label class="option" for="album_track_pks_1"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label></div><div class="checkbox"><label class="option" for="album_track_pks_2"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label></div><div class="checkbox"><label class="option" for="album_track_pks_3"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label></div></div>'
  end

  it "should correctly use the forms wrapper for wrapping radio buttons for one_to_many associations with :as=>:checkbox option" do
    @b = Forme::Form.new(@ab, :config=>:bs3, :wrapper=>:li)
    @b.input(:tracks, :as=>:checkbox).to_s.must_equal '<div class="one_to_many checkboxset"><label>Tracks</label><div class="checkbox"><label class="option" for="album_track_pks_1"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label></div><div class="checkbox"><label class="option" for="album_track_pks_2"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label></div><div class="checkbox"><label class="option" for="album_track_pks_3"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label></div></div>'
    @b.input(:tracks, :as=>:checkbox, :wrapper=>:li).to_s.must_equal '<li class="one_to_many checkboxset"><label>Tracks</label><div class="checkbox"><label class="option" for="album_track_pks_1"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label></div><div class="checkbox"><label class="option" for="album_track_pks_2"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label></div><div class="checkbox"><label class="option" for="album_track_pks_3"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label></div></li>'
  end

  it "should support custom wrappers for one_to_many associations with :as=>:checkbox via :tag_wrapper option" do
    @b = Forme::Form.new(@ab, :config=>:bs3, :wrapper=>:li)
    @b.input(:tracks, :as=>:checkbox, :wrapper=>proc{|t, i| i.tag(:div, i.opts[:wrapper_attr], [t])}, :tag_wrapper=>proc{|t, i| i.tag(:span, {}, [t])}).to_s.must_equal '<div class="one_to_many checkboxset"><label>Tracks</label><span><label class="option" for="album_track_pks_1"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label></span><span><label class="option" for="album_track_pks_2"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label></span><span><label class="option" for="album_track_pks_3"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label></span></div>'
  end

  it "should use a text field methods not backed by columns" do
    @b.input(:artist_name).to_s.must_equal '<div class="form-group"><label for="album_artist_name">Artist name</label> <input class="form-control" id="album_artist_name" name="album[artist_name]" type="text" value="a"/></div>'
    @c.input(:artist_name).to_s.must_equal '<div class="form-group"><label for="album_artist_name">Artist name</label> <input class="form-control" id="album_artist_name" name="album[artist_name]" type="text" value="d"/></div>'
  end

  it "should handle errors on methods not backed by columns" do
    @ab.errors.add(:artist_name, 'foo')
    @b.input(:artist_name).to_s.must_equal '<div class="form-group has-error"><label for="album_artist_name">Artist name</label> <input class="form-control" id="album_artist_name" name="album[artist_name]" type="text" value="a"/><span class="help-block with-errors">foo</span></div>'
  end

  it "should respect a :type option with a schema type as the input type for methods not backed by columns" do
    def @ab.foo; false end
    @b.input(:foo, :type=>:boolean, :as=>:select).to_s.must_equal '<div class="form-group"><label for="album_foo">Foo</label> <select class="form-control" id="album_foo" name="album[foo]"><option value=""></option><option value="t">True</option><option selected="selected" value="f">False</option></select></div>'
  end

  it "should respect a :type option with an input type as the input type for methods not backed by columns" do
    def @ab.foo; "bar" end
    @b.input(:foo, :type=>:phone).to_s.must_equal '<div class="form-group"><label for="album_foo">Foo</label> <input class="form-control" id="album_foo" name="album[foo]" type="phone" value="bar"/></div>'
  end

  it "should correctly show an error message if there is one" do
    @ab.errors.add(:name, 'tis not valid')
    @b.input(:name).to_s.must_equal '<div class="form-group has-error string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" type="text" value="b"/><span class="help-block with-errors">tis not valid</span></div>'
  end

  it "should correctly show an error message for many_to_one associations if there is one" do
    @ab.errors.add(:artist_id, 'tis not valid')
    @b.input(:artist).to_s.must_equal '<div class="form-group has-error many_to_one"><label for="album_artist_id">Artist</label> <select class="form-control" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">a</option><option value="2">d</option></select><span class="help-block with-errors">tis not valid</span></div>'
  end

  it "should raise an error for unhandled associations" do
    al = Class.new(Album)
    al.one_to_many :tags
    al.association_reflection(:tags)[:type] = :foo
    proc{Forme::Form.new(al.new).input(:tags)}.must_raise(Sequel::Plugins::Forme::Error)
  end

  it "should raise an error for unhandled fields with no :type option" do
    proc{@b.input(:foo)}.must_raise(Sequel::Plugins::Forme::Error)
  end

  it "should respect a :type option with a schema type as the input type for unhandled fields" do
    @b.input(:foo, :type=>:string).to_s.must_equal '<div class="form-group"><label for="album_foo">Foo</label> <input class="form-control" id="album_foo" name="album[foo]" type="text"/></div>'
    @b.input(:password, :type=>:string).to_s.must_equal '<div class="form-group"><label for="album_password">Password</label> <input class="form-control" id="album_password" name="album[password]" type="password"/></div>'
  end

  it "should respect a :type option with an input type as the input type for unhandled fields" do
    @b.input(:foo, :type=>:phone).to_s.must_equal '<div class="form-group"><label for="album_foo">Foo</label> <input class="form-control" id="album_foo" name="album[foo]" type="phone"/></div>'
  end

  it "should respect a :multiple option for the name attribute for unhandled fields" do
    @b.input(:foo, :type=>:phone, :multiple=>true).to_s.must_equal '<div class="form-group"><label for="album_foo">Foo</label> <input class="form-control" id="album_foo" name="album[foo][]" type="phone"/></div>'
  end

  it "should add required attribute if the column doesn't support nil values" do
    def @ab.db_schema; h = super.dup; h[:name] = h[:name].merge(:allow_null=>false); h end
    @b.input(:name).to_s.must_equal '<div class="form-group required string"><label for="album_name">Name<abbr title="required">*</abbr></label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/></div>'
  end

  it "should use allow nested forms with many_to_one associations" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist){f.input(:name)}}.to_s.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Artist</legend><div class="form-group string"><label for="album_artist_attributes_name">Name</label> <input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></div></fieldset></form>'
  end

  it "should have #subform respect an :inputs option" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist, :inputs=>[:name])}.to_s.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Artist</legend><div class="form-group string"><label for="album_artist_attributes_name">Name</label> <input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></div></fieldset></form>'
  end

  it "should have #subform respect an :obj option overriding the object to use" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist, :inputs=>[:name], :obj=>Artist.new(:name=>'b'))}.to_s.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Artist</legend><div class="form-group string"><label for="album_artist_attributes_name">Name</label> <input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="b"/></div></fieldset></form>'
  end

  it "should have #subform respect a :legend option if :inputs is used" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist, :inputs=>[:name], :legend=>'Foo')}.to_s.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Foo</legend><div class="form-group string"><label for="album_artist_attributes_name">Name</label> <input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></div></fieldset></form>'
  end

  it "should have #subform respect a callable :legend option if :inputs is used" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist, :inputs=>[:name], :legend=>proc{|o| "Foo - #{o.name}"})}.to_s.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Foo - a</legend><div class="form-group string"><label for="album_artist_attributes_name">Name</label> <input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></div></fieldset></form>'
  end

  it "should not add hidden primary key field for new many_to_one associated objects" do
    @ab.associations[:artist] = Artist.new(:name=>'a')
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist){f.input(:name)}}.to_s.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Artist</legend><div class="form-group string"><label for="album_artist_attributes_name">Name</label> <input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></div></fieldset></form>'
  end

  it "should use allow nested forms with one_to_one associations" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:album_info, :obj=>AlbumInfo.new(:info=>'a')){f.input(:info)}}.to_s.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Album info</legend><div class="form-group string"><label for="album_album_info_attributes_info">Info</label> <input class="form-control" id="album_album_info_attributes_info" maxlength="255" name="album[album_info_attributes][info]" type="text" value="a"/></div></fieldset></form>'
  end

  it "should use allow nested forms with one_to_many associations" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:tracks){f.input(:name)}}.to_s.must_equal '<form class="forme album" method="post"><input id="album_tracks_attributes_0_id" name="album[tracks_attributes][0][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Track #1</legend><div class="form-group string"><label for="album_tracks_attributes_0_name">Name</label> <input class="form-control" id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="m"/></div></fieldset><input id="album_tracks_attributes_1_id" name="album[tracks_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Track #2</legend><div class="form-group string"><label for="album_tracks_attributes_1_name">Name</label> <input class="form-control" id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="n"/></div></fieldset></form>'
  end

  it "should support :obj option for *_to_many associations" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:tracks, :obj=>[Track.new(:name=>'x'), Track.load(:id=>5, :name=>'y')]){f.input(:name)}}.to_s.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Track #1</legend><div class="form-group string"><label for="album_tracks_attributes_0_name">Name</label> <input class="form-control" id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="x"/></div></fieldset><input id="album_tracks_attributes_1_id" name="album[tracks_attributes][1][id]" type="hidden" value="5"/><fieldset class="inputs"><legend>Track #2</legend><div class="form-group string"><label for="album_tracks_attributes_1_name">Name</label> <input class="form-control" id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="y"/></div></fieldset></form>'
  end

  it "should auto number legends when using subform with inputs for *_to_many associations" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:tracks, :inputs=>[:name])}.to_s.must_equal '<form class="forme album" method="post"><input id="album_tracks_attributes_0_id" name="album[tracks_attributes][0][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Track #1</legend><div class="form-group string"><label for="album_tracks_attributes_0_name">Name</label> <input class="form-control" id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="m"/></div></fieldset><input id="album_tracks_attributes_1_id" name="album[tracks_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Track #2</legend><div class="form-group string"><label for="album_tracks_attributes_1_name">Name</label> <input class="form-control" id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="n"/></div></fieldset></form>'
  end

  it "should support callable :legend option when using subform with inputs for *_to_many associations" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:tracks, :inputs=>[:name], :legend=>proc{|o, i| "Track #{i} (#{o.name})"})}.to_s.must_equal '<form class="forme album" method="post"><input id="album_tracks_attributes_0_id" name="album[tracks_attributes][0][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Track 0 (m)</legend><div class="form-group string"><label for="album_tracks_attributes_0_name">Name</label> <input class="form-control" id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="m"/></div></fieldset><input id="album_tracks_attributes_1_id" name="album[tracks_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Track 1 (n)</legend><div class="form-group string"><label for="album_tracks_attributes_1_name">Name</label> <input class="form-control" id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="n"/></div></fieldset></form>'
  end

  it "should not add hidden primary key field for nested forms with one_to_many associations with new objects" do
    @ab.associations[:tracks] = [Track.new(:name=>'m'), Track.new(:name=>'n')]
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:tracks){f.input(:name)}}.to_s.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Track #1</legend><div class="form-group string"><label for="album_tracks_attributes_0_name">Name</label> <input class="form-control" id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="m"/></div></fieldset><fieldset class="inputs"><legend>Track #2</legend><div class="form-group string"><label for="album_tracks_attributes_1_name">Name</label> <input class="form-control" id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="n"/></div></fieldset></form>'
  end

  it "should use allow nested forms with many_to_many associations" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:tags){f.input(:name)}}.to_s.must_equal '<form class="forme album" method="post"><input id="album_tags_attributes_0_id" name="album[tags_attributes][0][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Tag #1</legend><div class="form-group string"><label for="album_tags_attributes_0_name">Name</label> <input class="form-control" id="album_tags_attributes_0_name" maxlength="255" name="album[tags_attributes][0][name]" type="text" value="s"/></div></fieldset><input id="album_tags_attributes_1_id" name="album[tags_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Tag #2</legend><div class="form-group string"><label for="album_tags_attributes_1_name">Name</label> <input class="form-control" id="album_tags_attributes_1_name" maxlength="255" name="album[tags_attributes][1][name]" type="text" value="t"/></div></fieldset></form>'
  end

  it "should not add hidden primary key field for nested forms with many_to_many associations with new objects" do
    @ab.associations[:tags] = [Tag.new(:name=>'s'), Tag.new(:name=>'t')]
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:tags){f.input(:name)}}.to_s.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Tag #1</legend><div class="form-group string"><label for="album_tags_attributes_0_name">Name</label> <input class="form-control" id="album_tags_attributes_0_name" maxlength="255" name="album[tags_attributes][0][name]" type="text" value="s"/></div></fieldset><fieldset class="inputs"><legend>Tag #2</legend><div class="form-group string"><label for="album_tags_attributes_1_name">Name</label> <input class="form-control" id="album_tags_attributes_1_name" maxlength="255" name="album[tags_attributes][1][name]" type="text" value="t"/></div></fieldset></form>'
  end

  it "should handle multiple nested levels" do
    Forme.form(Artist[1], {},{:config=>:bs3}){|f| f.subform(:albums){f.input(:name); f.subform(:tracks){f.input(:name)}}}.to_s.to_s.must_equal '<form class="forme artist" method="post"><input id="artist_albums_attributes_0_id" name="artist[albums_attributes][0][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Album #1</legend><div class="form-group string"><label for="artist_albums_attributes_0_name">Name</label> <input class="form-control" id="artist_albums_attributes_0_name" maxlength="255" name="artist[albums_attributes][0][name]" type="text" value="b"/></div><input id="artist_albums_attributes_0_tracks_attributes_0_id" name="artist[albums_attributes][0][tracks_attributes][0][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Track #1</legend><div class="form-group string"><label for="artist_albums_attributes_0_tracks_attributes_0_name">Name</label> <input class="form-control" id="artist_albums_attributes_0_tracks_attributes_0_name" maxlength="255" name="artist[albums_attributes][0][tracks_attributes][0][name]" type="text" value="m"/></div></fieldset><input id="artist_albums_attributes_0_tracks_attributes_1_id" name="artist[albums_attributes][0][tracks_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Track #2</legend><div class="form-group string"><label for="artist_albums_attributes_0_tracks_attributes_1_name">Name</label> <input class="form-control" id="artist_albums_attributes_0_tracks_attributes_1_name" maxlength="255" name="artist[albums_attributes][0][tracks_attributes][1][name]" type="text" value="n"/></div></fieldset></fieldset></form>'
  end

  it "should have #subform :grid option create a grid" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist, :inputs=>[:name], :grid=>true)}.to_s.must_equal '<form class="forme album" method="post"><table><caption>Artist</caption><thead><tr><th>Name</th></tr></thead><tbody><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><tr><td class="string"><input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end

  it "should have #subform :grid option respect :inputs_opts option to pass options to inputs" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist, :inputs=>[:name], :grid=>true, :inputs_opts=>{:attr=>{:class=>'foo'}})}.to_s.must_equal '<form class="forme album" method="post"><table class="foo"><caption>Artist</caption><thead><tr><th>Name</th></tr></thead><tbody><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><tr><td class="string"><input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end

  it "should have #subform :grid option handle :legend and :labels options" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist, :inputs=>[:name], :grid=>true, :legend=>'Foo', :labels=>%w'Bar')}.to_s.must_equal '<form class="forme album" method="post"><table><caption>Foo</caption><thead><tr><th>Bar</th></tr></thead><tbody><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><tr><td class="string"><input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end

  it "should have #subform :grid option handle :legend and :labels nil values" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist, :inputs=>[:name], :grid=>true, :legend=>nil, :labels=>nil)}.to_s.must_equal '<form class="forme album" method="post"><table><tbody><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><tr><td class="string"><input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end

  it "should have #subform :grid option handle :skip_primary_key option" do
    Forme.form(@ab, {},{:config=>:bs3}){|f| f.subform(:artist, :inputs=>[:name], :grid=>true, :skip_primary_key=>true)}.to_s.must_equal '<form class="forme album" method="post"><table><caption>Artist</caption><thead><tr><th>Name</th></tr></thead><tbody><tr><td class="string"><input class="form-control" id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end
  
end

describe "Forme Sequel plugin default input types based on column names" do
  def f(name)
    DB.create_table!(:test){String name}
    Forme::Form.new(Class.new(Sequel::Model).class_eval{def self.name; 'Test' end; set_dataset :test}.new, {:config=>:bs3}).input(name, :value=>'foo')
  end

  it "should use password input with no value for string columns with name password" do
    f(:password).to_s.must_equal '<div class="form-group string"><label for="test_password">Password</label> <input class="form-control" id="test_password" maxlength="255" name="test[password]" type="password"/></div>'
  end  

  it "should use email input for string columns with name email" do
    f(:email).to_s.must_equal '<div class="form-group string"><label for="test_email">Email</label> <input class="form-control" id="test_email" maxlength="255" name="test[email]" type="email" value="foo"/></div>'
  end

  it "should use tel input for string columns with name phone or fax" do
    f(:phone).to_s.must_equal '<div class="form-group string"><label for="test_phone">Phone</label> <input class="form-control" id="test_phone" maxlength="255" name="test[phone]" type="tel" value="foo"/></div>'
    f(:fax).to_s.must_equal '<div class="form-group string"><label for="test_fax">Fax</label> <input class="form-control" id="test_fax" maxlength="255" name="test[fax]" type="tel" value="foo"/></div>'
  end

  it "should use url input for string columns with name url, uri, or website" do
    f(:url).to_s.must_equal '<div class="form-group string"><label for="test_url">Url</label> <input class="form-control" id="test_url" maxlength="255" name="test[url]" type="url" value="foo"/></div>'
    f(:uri).to_s.must_equal '<div class="form-group string"><label for="test_uri">Uri</label> <input class="form-control" id="test_uri" maxlength="255" name="test[uri]" type="url" value="foo"/></div>'
    f(:website).to_s.must_equal '<div class="form-group string"><label for="test_website">Website</label> <input class="form-control" id="test_website" maxlength="255" name="test[website]" type="url" value="foo"/></div>'
  end
end 

describe "Forme Sequel plugin default input types based on column type" do
  def f(type)
    DB.create_table!(:test){column :foo, type}
    Forme::Form.new(Class.new(Sequel::Model).class_eval{def self.name; 'Test' end; set_dataset :test}.new,{:config=>:bs3}).input(:foo, :value=>'foo')
  end

  it "should use password input with no value for string columns with name password" do
    f(File).to_s.must_equal '<div class="blob form-group"><label for="test_foo">Foo</label> <input id="test_foo" name="test[foo]" type="file"/></div>'
  end
end

describe "Forme Sequel::Model validation parsing" do
  def f(*a)
    c = Class.new(Album){def self.name; "Album"; end}
    c.plugin :validation_class_methods
    c.send(*a)
    Forme::Form.new(c.new, :config=>:bs3)
  end

  it "should turn format into a pattern" do
    f(:validates_format_of, :name, :with=>/[A-z]+/).input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" pattern="[A-z]+" type="text"/></div>'
  end

  it "should respect :title option for format" do
    f(:validates_format_of, :name, :with=>/[A-z]+/, :title=>'Foo').input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" pattern="[A-z]+" title="Foo" type="text"/></div>'
  end

  it "should use maxlength for length :maximum, :is, and :within" do
    f(:validates_length_of, :name, :maximum=>10).input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="10" name="album[name]" type="text"/></div>'
    f(:validates_length_of, :name, :is=>10).input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="10" name="album[name]" type="text"/></div>'
    f(:validates_length_of, :name, :within=>2..10).input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="10" name="album[name]" type="text"/></div>'
    f(:validates_length_of, :name, :within=>2...11).input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="10" name="album[name]" type="text"/></div>'
  end

  it "should turn numericality into a pattern" do
    f(:validates_numericality_of, :name).input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" pattern="^[+\-]?\d+(\.\d+)?$" title="must be a number" type="text"/></div>'
  end

  it "should turn numericality :only_integer into a pattern" do
    f(:validates_numericality_of, :name, :only_integer=>true).input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" pattern="^[+\-]?\d+$" title="must be a number" type="text"/></div>'
  end

  it "should respect :title option for numericality" do
    f(:validates_numericality_of, :name, :title=>'Foo').input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" pattern="^[+\-]?\d+(\.\d+)?$" title="Foo" type="text"/></div>'
  end

  it "should respect :placeholder option for any validation" do
    f(:validates_uniqueness_of, :name, :placeholder=>'must be unique').input(:name).to_s.must_equal '<div class="form-group string"><label for="album_name">Name</label> <input class="form-control" id="album_name" maxlength="255" name="album[name]" placeholder="must be unique" type="text"/></div>'
  end
end
