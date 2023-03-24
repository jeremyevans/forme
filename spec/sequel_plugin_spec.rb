require_relative 'spec_helper'
require_relative 'sequel_helper'

describe "Forme Sequel::Model forms" do
  before do
    @ab = Album[1]
    @b = Forme::Form.new(@ab)
    @ac = Album[2]
    @c = Forme::Form.new(@ac)
  end
  
  it "should handle Forme::Form subclasses" do
    c = Class.new(Forme::Form) do
      def form(*)
        super{|f| f.tag(:input, :type=>:hidden, :name=>'a', :value=>'b')}
      end
    end
    c.new(@ab).form.must_equal '<form class="forme album" method="post"><input name="a" type="hidden" value="b"/></form>'
  end

  it "should have humanize handle objects that support #humanize" do
    s = Object.new
    def s.to_s; self end
    def s.humanize; 'X' end
    @b.humanize(s).must_equal 'X'
  end

  it "should have humanize handle objects that support #humanize" do
    s = 'x_b_id'
    class << s
      undef :humanize if method_defined?(:humanize)
    end
    @b.humanize(s).must_equal 'X b'
  end

  it "should add appropriate attributes by default" do
    @b.form.must_equal '<form class="forme album" method="post"></form>'
  end

  it "should allow overriding of attributes" do
    @b.form(:class=>:foo, :method=>:get).must_equal '<form class="foo forme album" method="get"></form>'
  end

  it "should handle invalid methods" do
    def @ab.db_schema
      super.merge(:foo=>{:type=>:bar})
    end
    @b.input(:foo, :value=>'baz').must_equal '<label>Foo: <input id="album_foo" name="album[foo]" type="text" value="baz"/></label>'
  end

  it "should allow an array of classes" do
    @b.form(:class=>[:foo, :bar]).must_equal '<form class="foo bar forme album" method="post"></form>'
    @b.form(:class=>[:foo, [:bar, :baz]]).must_equal '<form class="foo bar baz forme album" method="post"></form>'
  end

  it "should use a text field for strings" do
    @b.input(:name).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" type="text" value="b"/></label>'
    @c.input(:name).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" type="text" value="c"/></label>'
  end
  
  it "should allow :as=>:textarea to use a textarea" do
    @b.input(:name, :as=>:textarea).must_equal '<label>Name: <textarea id="album_name" maxlength="255" name="album[name]">b</textarea></label>'
    @c.input(:name, :as=>:textarea).must_equal '<label>Name: <textarea id="album_name" maxlength="255" name="album[name]">c</textarea></label>'
  end
  
  it "should allow :type=>:textarea to use a textarea" do
    @b.input(:name, :type=>:textarea).must_equal '<label>Name: <textarea id="album_name" maxlength="255" name="album[name]">b</textarea></label>'
    @c.input(:name, :type=>:textarea).must_equal '<label>Name: <textarea id="album_name" maxlength="255" name="album[name]">c</textarea></label>'
  end

  it "should respect :value and :key options when using :type option" do
    @b.input(:name, :type=>:textarea, :value=>'a', :key=>'f').must_equal '<label>Name: <textarea id="album_f" maxlength="255" name="album[f]">a</textarea></label>'
  end

  it "should not include labels for hidden inputs" do
    @b.input(:name, :type=>:hidden).must_equal '<input id="album_name" name="album[name]" type="hidden" value="b"/>'
  end
  
  it "should use text input with inputmode and pattern for integer fields" do
    @b.input(:copies_sold).must_equal '<label>Copies sold: <input id="album_copies_sold" inputmode="numeric" name="album[copies_sold]" pattern="-?[0-9]*" type="text" value="10"/></label>'
  end

  it "should use text input for numeric fields" do
    @b.input(:bd).must_equal '<label>Bd: <input id="album_bd" name="album[bd]" type="text"/></label>'
  end

  it "should use text input float fields" do
    @b.input(:fl).must_equal '<label>Fl: <input id="album_fl" name="album[fl]" type="text"/></label>'
  end

  it "should use date inputs for Dates" do
    @b.input(:release_date).must_equal '<label>Release date: <input id="album_release_date" name="album[release_date]" type="date" value="2011-06-05"/></label>'
  end
  
  it "should use datetime inputs for Time" do
    @b.input(:created_at).must_match %r{<label>Created at: <input id="album_created_at" name="album\[created_at\]" type="datetime-local" value="2011-06-05T00:00:00.000"/></label>}
  end
  
  it "should use datetime inputs for DateTimes" do
    @ab.values[:created_at] = DateTime.new(2011, 6, 5)
    @b.input(:created_at).must_equal '<label>Created at: <input id="album_created_at" name="album[created_at]" type="datetime-local" value="2011-06-05T00:00:00.000"/></label>'
  end

  it "should use file inputs without value" do
    @b.input(:name, :type=>:file).must_equal '<label>Name: <input id="album_name" name="album[name]" type="file"/></label>'
  end

  it "should include type as wrapper class" do
    @ab.values[:created_at] = DateTime.new(2011, 6, 5)
    f = Forme::Form.new(@ab, :wrapper=>:li)
    f.input(:name).must_equal '<li class="string"><label>Name: <input id="album_name" maxlength="255" name="album[name]" type="text" value="b"/></label></li>'
    f.input(:release_date).must_equal '<li class="date"><label>Release date: <input id="album_release_date" name="album[release_date]" type="date" value="2011-06-05"/></label></li>'
    f.input(:created_at).must_equal '<li class="datetime"><label>Created at: <input id="album_created_at" name="album[created_at]" type="datetime-local" value="2011-06-05T00:00:00.000"/></label></li>'
  end
  
  it "should handle :wrapper_attr to add attribues on the wrapper" do
    @b.input(:name, :wrapper_attr=>{:foo=>'bar'}, :wrapper=>:div).must_equal '<div class="string" foo="bar"><label>Name: <input id="album_name" maxlength="255" name="album[name]" type="text" value="b"/></label></div>'
  end
  
  it "should handle :key to override the key" do
    @b.input(:name, :key=>:f).must_equal '<label>Name: <input id="album_f" maxlength="255" name="album[f]" type="text" value="b"/></label>'
  end
  
  it "should include required * in label if required" do
    @b.input(:name, :required=>true).must_equal '<label>Name<abbr title="required">*</abbr>: <input id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/></label>'
  end
  
  it "should add required to label even if :label option specified" do
    @b.input(:name, :required=>true, :label=>'Foo').must_equal '<label>Foo<abbr title="required">*</abbr>: <input id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/></label>'
  end
  
  it "should not add required to label even if :label option is nil" do
    @b.input(:name, :required=>true, :label=>nil).must_equal '<input id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/>'
  end
  
  it "should not add required * in label if obj.forme_use_required_abbr? is false" do
    def @ab.forme_use_required_abbr?; false end
    @b.input(:name, :required=>true).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/></label>'
  end
  
  it "should include required wrapper class if required" do
    f = Forme::Form.new(@ab, :wrapper=>:li)
    f.input(:name, :required=>true).must_equal '<li class="string required"><label>Name<abbr title="required">*</abbr>: <input id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/></label></li>'
  end
  
  it "should use a select box for tri-valued boolean fields" do
    @b.input(:gold).must_equal '<label>Gold: <select id="album_gold" name="album[gold]"><option value=""></option><option value="t">True</option><option selected="selected" value="f">False</option></select></label>'
    @c.input(:gold).must_equal '<label>Gold: <select id="album_gold" name="album[gold]"><option value=""></option><option selected="selected" value="t">True</option><option value="f">False</option></select></label>'
  end
  
  it "should handle :value option for boolean fields" do
    @b.input(:gold, :value=>nil).must_equal '<label>Gold: <select id="album_gold" name="album[gold]"><option value=""></option><option value="t">True</option><option value="f">False</option></select></label>'
    @b.input(:gold, :value=>true).must_equal '<label>Gold: <select id="album_gold" name="album[gold]"><option value=""></option><option selected="selected" value="t">True</option><option value="f">False</option></select></label>'
    @b.input(:gold, :value=>false).must_equal '<label>Gold: <select id="album_gold" name="album[gold]"><option value=""></option><option value="t">True</option><option selected="selected" value="f">False</option></select></label>'
  end
  
  it "should respect :true_label and :false_label options for tri-valued boolean fields" do
    @b.input(:gold, :true_label=>"Foo", :false_label=>"Bar").must_equal '<label>Gold: <select id="album_gold" name="album[gold]"><option value=""></option><option value="t">Foo</option><option selected="selected" value="f">Bar</option></select></label>'
  end
  
  it "should respect :true_value and :false_value options for tri-valued boolean fields" do
    @b.input(:gold, :true_value=>"Foo", :false_value=>"Bar").must_equal '<label>Gold: <select id="album_gold" name="album[gold]"><option value=""></option><option value="Foo">True</option><option value="Bar">False</option></select></label>'
  end
  
  it "should respect :add_blank option for tri-valued boolean fields" do
    @b.input(:gold, :add_blank=>'NULL').must_equal '<label>Gold: <select id="album_gold" name="album[gold]"><option value="">NULL</option><option value="t">True</option><option selected="selected" value="f">False</option></select></label>'
  end
  
  it "should use a select box for dual-valued boolean fields where :required => false" do
    @b.input(:platinum, :required=>false).must_equal '<label>Platinum: <select id="album_platinum" name="album[platinum]"><option value=""></option><option value="t">True</option><option selected="selected" value="f">False</option></select></label>'
    @c.input(:platinum, :required=>false).must_equal '<label>Platinum: <select id="album_platinum" name="album[platinum]"><option value=""></option><option selected="selected" value="t">True</option><option value="f">False</option></select></label>'
  end
  
  it "should use a checkbox for dual-valued boolean fields" do
    @b.input(:platinum).must_equal '<input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><label><input id="album_platinum" name="album[platinum]" type="checkbox" value="t"/> Platinum</label>'
    @c.input(:platinum).must_equal '<input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><label><input checked="checked" id="album_platinum" name="album[platinum]" type="checkbox" value="t"/> Platinum</label>'
  end
  
  it "should respect :value option for checkbox for dual-valued boolean fields" do
    @b.input(:platinum, :value=>nil).must_equal '<input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><label><input id="album_platinum" name="album[platinum]" type="checkbox" value="t"/> Platinum</label>'
    @b.input(:platinum, :value=>false).must_equal '<input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><label><input id="album_platinum" name="album[platinum]" type="checkbox" value="t"/> Platinum</label>'
    @b.input(:platinum, :value=>true).must_equal '<input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><label><input checked="checked" id="album_platinum" name="album[platinum]" type="checkbox" value="t"/> Platinum</label>'
  end
  
  it "should use radio buttons for boolean fields if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio).must_equal '<span class="label">Platinum</span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label>'
    @c.input(:platinum, :as=>:radio).must_equal '<span class="label">Platinum</span><label class="option"><input checked="checked" id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label>'
  end
  
  it "should handle :value given if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio, :value=>nil).must_equal '<span class="label">Platinum</span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label>'
    @b.input(:platinum, :as=>:radio, :value=>true).must_equal '<span class="label">Platinum</span><label class="option"><input checked="checked" id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label>'
    @b.input(:platinum, :as=>:radio, :value=>false).must_equal '<span class="label">Platinum</span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label>'
  end
  
  it "should wrap both inputs if :as=>:radio is used" do
    @b = Forme::Form.new(@ab, :wrapper=>:li)
    @b.input(:platinum, :as=>:radio).must_equal '<li class="boolean"><span class="label">Platinum</span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></li>'
    @b.input(:platinum, :as=>:radio, :wrapper=>:div, :tag_wrapper=>:span).must_equal '<div class="boolean"><span class="label">Platinum</span><span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label></span><span><label class="option"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label></span></div>'
  end
  
  it "should handle errors on radio buttons for boolean fields if :as=>:radio is used" do
    @ab.errors.add(:platinum, 'foo')
    @b.input(:platinum, :as=>:radio).must_equal '<span class="label">Platinum</span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input aria-describedby="album_platinum_no_error_message" aria-invalid="true" checked="checked" class="error" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label><span class="error_message" id="album_platinum_no_error_message">foo</span>'
  end
  
  it "should handle Raw :label options if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio, :label=>Forme.raw('Foo:<br />')).must_equal '<span class="label">Foo:<br /></span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label>'
    @b.input(:platinum, :as=>:radio, :label=>'Foo:<br />').must_equal '<span class="label">Foo:&lt;br /&gt;</span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label>'
  end
  
  it "should respect :true_label and :false_label options for boolean fields if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio, :true_label=>"Foo", :false_label=>"Bar").must_equal '<span class="label">Platinum</span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Foo</label><label class="option"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> Bar</label>'
  end
  
  it "should respect :true_value and :false_value options for boolean fields if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio, :true_value=>"Foo", :false_value=>"Bar").must_equal '<span class="label">Platinum</span><label class="option"><input id="album_platinum_yes" name="album[platinum]" type="radio" value="Foo"/> Yes</label><label class="option"><input checked="checked" id="album_platinum_no" name="album[platinum]" type="radio" value="Bar"/> No</label>'
  end
  
  it "should respect :formatter=>:readonly option for boolean fields if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio, :formatter=>:readonly).must_equal '<span class="label">Platinum</span><label class="option"><input disabled="disabled" id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/> Yes</label><label class="option"><input checked="checked" disabled="disabled" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/> No</label>'
  end
  
  it "should use a select box for many_to_one associations" do
    @b.input(:artist).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">a</option><option value="2">d</option></select></label>'
    @c.input(:artist).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a</option><option selected="selected" value="2">d</option></select></label>'
  end

  it "should respect given :key option for many_to_one associations" do
    @b.input(:artist, :key=>'f').must_equal '<label>Artist: <select id="album_f" name="album[f]"><option value=""></option><option selected="selected" value="1">a</option><option value="2">d</option></select></label>'
  end

  it "should respect given :value option for many_to_one associations" do
    @b.input(:artist, :value=>2).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a</option><option selected="selected" value="2">d</option></select></label>'
  end

  it "should not add a blank option by default if there is a default value and it is required" do
    @b.input(:artist, :required=>true).must_equal '<label>Artist<abbr title="required">*</abbr>: <select id="album_artist_id" name="album[artist_id]" required="required"><option selected="selected" value="1">a</option><option value="2">d</option></select></label>'
  end

  it "should allow overriding default input type using a :type option" do
    @b.input(:artist, :type=>:string, :value=>nil).must_equal '<label>Artist: <input id="album_artist" name="album[artist]" type="text"/></label>'
  end

  it "should automatically set :required for many_to_one assocations based on whether the field is required" do
    begin
      Album.db_schema[:artist_id][:allow_null] = false
      @b.input(:artist).must_equal '<label>Artist<abbr title="required">*</abbr>: <select id="album_artist_id" name="album[artist_id]" required="required"><option selected="selected" value="1">a</option><option value="2">d</option></select></label>'
      @b.input(:artist, :required=>false).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">a</option><option value="2">d</option></select></label>'
    ensure
      Album.db_schema[:artist_id][:allow_null] = true
    end
  end

  it "should use a required wrapper tag for many_to_one required associations" do
    @b.input(:artist, :required=>true, :wrapper=>:li).must_equal '<li class="many_to_one required"><label>Artist<abbr title="required">*</abbr>: <select id="album_artist_id" name="album[artist_id]" required="required"><option selected="selected" value="1">a</option><option value="2">d</option></select></label></li>'
  end

  it "should use a set of radio buttons for many_to_one associations with :as=>:radio option" do
    @b.input(:artist, :as=>:radio).must_equal '<span class="label">Artist</span><label class="option"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label><label class="option"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label>'
    @c.input(:artist, :as=>:radio).must_equal '<span class="label">Artist</span><label class="option"><input id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label><label class="option"><input checked="checked" id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label>'
  end
  
  it "should handle Raw label for many_to_one associations with :as=>:radio option" do
    @b.input(:artist, :as=>:radio, :label=>Forme.raw('Foo:<br />')).must_equal '<span class="label">Foo:<br /></span><label class="option"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label><label class="option"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label>'
    @b.input(:artist, :as=>:radio, :label=>'Foo<br />').must_equal '<span class="label">Foo&lt;br /&gt;</span><label class="option"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label><label class="option"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label>'
  end
  
  it "should correctly use the forms wrapper for wrapping radio buttons for many_to_one associations with :as=>:radio option" do
    @b = Forme::Form.new(@ab, :wrapper=>:li)
    @b.input(:artist, :as=>:radio).must_equal '<li class="many_to_one"><span class="label">Artist</span><label class="option"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label><label class="option"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></li>'
  end
  
  it "should support custom wrappers for many_to_one associations with :as=>:radio via :tag_wrapper option" do
    @b = Forme::Form.new(@ab, :wrapper=>:li)
    @b.input(:artist, :as=>:radio, :wrapper=>proc{|t, i| i.tag(:div, {}, [t])}, :tag_wrapper=>proc{|t, i| i.tag(:span, {}, [t])}).must_equal '<div><span class="label">Artist</span><span><label class="option"><input checked="checked" id="album_artist_id_1" name="album[artist_id]" type="radio" value="1"/> a</label></span><span><label class="option"><input id="album_artist_id_2" name="album[artist_id]" type="radio" value="2"/> d</label></span></div>'
  end
  
  it "should respect an :options entry" do
    @b.input(:artist, :options=>Artist.order(:name).map{|a| [a.name, a.id+1]}).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="2">a</option><option value="3">d</option></select></label>'
    @c.input(:artist, :options=>Artist.order(:name).map{|a| [a.name, a.id+1]}).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="2">a</option><option value="3">d</option></select></label>'
  end
  
  it "should support :name_method option for choosing name method" do
    @b.input(:artist, :name_method=>:idname).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">1a</option><option value="2">2d</option></select></label>'
    @c.input(:artist, :name_method=>:idname).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">1a</option><option selected="selected" value="2">2d</option></select></label>'
  end
  
  it "should support :name_method option being a callable object" do
    @b.input(:artist, :name_method=>lambda{|obj| obj.idname * 2}).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">1a1a</option><option value="2">2d2d</option></select></label>'
    @c.input(:artist, :name_method=>lambda{|obj| obj.idname * 2}).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">1a1a</option><option selected="selected" value="2">2d2d</option></select></label>'
  end
  
  it "should support :dataset option providing dataset to search" do
    @b.input(:artist, :dataset=>Artist.reverse_order(:name)).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="2">d</option><option selected="selected" value="1">a</option></select></label>'
    @c.input(:artist, :dataset=>Artist.reverse_order(:name)).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="2">d</option><option value="1">a</option></select></label>'
  end
  
  it "should support :dataset option being a callback proc returning modified dataset to search" do
    @b.input(:artist, :dataset=>proc{|ds| ds.reverse_order(:name)}).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="2">d</option><option selected="selected" value="1">a</option></select></label>'
    @c.input(:artist, :dataset=>proc{|ds| ds.reverse_order(:name)}).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="2">d</option><option value="1">a</option></select></label>'
  end
  
  it "should try a list of methods to get a suitable one for select box naming" do
    al = Class.new(Album){def self.name() 'Album' end}
    ar = Class.new(Artist)
    al.many_to_one :artist, :class=>ar
    ar.class_eval{undef_method(:name)}
    f = Forme::Form.new(al.new)

    ar.class_eval{def number() "#{self[:name]}1" end}
    f.input(:artist).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a1</option><option value="2">d1</option></select></label>'

    ar.class_eval{def title() "#{self[:name]}2" end}
    f.input(:artist).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a2</option><option value="2">d2</option></select></label>'

    ar.class_eval{def name() "#{self[:name]}3" end}
    f.input(:artist).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a3</option><option value="2">d3</option></select></label>'

    ar.class_eval{def forme_name() "#{self[:name]}4" end}
    f.input(:artist).must_equal '<label>Artist: <select id="album_artist_id" name="album[artist_id]"><option value=""></option><option value="1">a4</option><option value="2">d4</option></select></label>'
  end
  
  it "should raise an error when using an association without a usable name method" do
    al = Class.new(Album)
    ar = Class.new(Artist)
    al.many_to_one :artist, :class=>ar
    ar.class_eval{undef_method(:name)}
    proc{Forme::Form.new(al.new).input(:artist)}.must_raise(Sequel::Plugins::Forme::Error)
  end
    
  it "should use a multiple select box for one_to_many associations" do
    @b.input(:tracks).must_equal '<label>Tracks: <select id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option selected="selected" value="1">m</option><option selected="selected" value="2">n</option><option value="3">o</option></select></label>'
    @c.input(:tracks).must_equal '<label>Tracks: <select id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option value="1">m</option><option value="2">n</option><option selected="selected" value="3">o</option></select></label>'
  end
  
  it "should :respect given :key option for one_to_many associations" do
    @b.input(:tracks, :key=>:f).must_equal '<label>Tracks: <select id="album_f" multiple="multiple" name="album[f][]"><option selected="selected" value="1">m</option><option selected="selected" value="2">n</option><option value="3">o</option></select></label>'
  end

  it "should :respect given :array=>false, :multiple=>false options for one_to_many associations" do
    @b.input(:tracks, :array=>false, :multiple=>false, :value=>1).must_equal '<label>Tracks: <select id="album_track_pks" name="album[track_pks]"><option selected="selected" value="1">m</option><option value="2">n</option><option value="3">o</option></select></label>'
  end
  
  it "should handle case where object doesn't respond to *_pks for one_to_many associations" do
    class << @ab
      undef track_pks
    end
    @b.input(:tracks).must_equal '<label>Tracks: <select id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option selected="selected" value="1">m</option><option selected="selected" value="2">n</option><option value="3">o</option></select></label>'
  end
  
  it "should use a multiple select box for many_to_many associations" do
    @b.input(:tags).must_equal '<label>Tags: <select id="album_tag_pks" multiple="multiple" name="album[tag_pks][]"><option selected="selected" value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></label>'
    @c.input(:tags).must_equal '<label>Tags: <select id="album_tag_pks" multiple="multiple" name="album[tag_pks][]"><option value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></label>'
  end

  it "should use a multiple select box for pg_array_to_many associations" do
    @b.input(:atags).must_equal '<label>Atags: <select id="album_atag_ids" multiple="multiple" name="album[atag_ids][]"><option selected="selected" value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></label>'
    @c.obj.atag_ids.delete(1)
    @c.input(:atags).must_equal '<label>Atags: <select id="album_atag_ids" multiple="multiple" name="album[atag_ids][]"><option value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></label>'
  end

  it "should handle an error message on the underlying column for pg_array_to_many associations" do
    @ab.errors.add(:atag_ids, 'tis not valid')
    @b.input(:atags).must_equal '<label>Atags: <select aria-describedby="album_atag_ids_error_message" aria-invalid="true" class="error" id="album_atag_ids" multiple="multiple" name="album[atag_ids][]"><option selected="selected" value="1">s</option><option selected="selected" value="2">t</option><option value="3">u</option></select></label><span class="error_message" id="album_atag_ids_error_message">tis not valid</span>'
    @b.input(:atags, :as=>:checkbox).must_equal '<span class="label">Atags</span><label class="option"><input checked="checked" id="album_atag_ids_1" name="album[atag_ids][]" type="checkbox" value="1"/> s</label><label class="option"><input checked="checked" id="album_atag_ids_2" name="album[atag_ids][]" type="checkbox" value="2"/> t</label><label class="option"><input aria-describedby="album_atag_ids_3_error_message" aria-invalid="true" class="error" id="album_atag_ids_3" name="album[atag_ids][]" type="checkbox" value="3"/> u</label><span class="error_message" id="album_atag_ids_3_error_message">tis not valid</span>'
  end
  
  it "should use a regular select box for *_to_many associations if multiple if false" do
    @b.input(:tracks, :multiple=>false).must_equal '<label>Tracks: <select id="album_track_pks" name="album[track_pks][]"><option value="1">m</option><option value="2">n</option><option value="3">o</option></select></label>'
    @c.input(:tags, :multiple=>false).must_equal '<label>Tags: <select id="album_tag_pks" name="album[tag_pks][]"><option value="1">s</option><option value="2">t</option><option value="3">u</option></select></label>'
  end

  it "should handle a given :value for one_to_many associations" do
    @b.input(:tracks, :value=>[1,3]).must_equal '<label>Tracks: <select id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option selected="selected" value="1">m</option><option value="2">n</option><option selected="selected" value="3">o</option></select></label>'
    @c.input(:tracks, :value=>nil).must_equal '<label>Tracks: <select id="album_track_pks" multiple="multiple" name="album[track_pks][]"><option value="1">m</option><option value="2">n</option><option value="3">o</option></select></label>'
  end
  
  it "should use multiple checkboxes for one_to_many associations if :as=>:checkbox" do
    @b.input(:tracks, :as=>:checkbox).must_equal '<span class="label">Tracks</span><label class="option"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label><label class="option"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label><label class="option"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label>'
    @c.input(:tracks, :as=>:checkbox).must_equal '<span class="label">Tracks</span><label class="option"><input id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label><label class="option"><input id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label><label class="option"><input checked="checked" id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label>'
  end
  
  it "should use multiple checkboxes for many_to_many associations if :as=>:checkbox" do
    @b.input(:tags, :as=>:checkbox).must_equal '<span class="label">Tags</span><label class="option"><input checked="checked" id="album_tag_pks_1" name="album[tag_pks][]" type="checkbox" value="1"/> s</label><label class="option"><input checked="checked" id="album_tag_pks_2" name="album[tag_pks][]" type="checkbox" value="2"/> t</label><label class="option"><input id="album_tag_pks_3" name="album[tag_pks][]" type="checkbox" value="3"/> u</label>'
    @c.input(:tags, :as=>:checkbox).must_equal '<span class="label">Tags</span><label class="option"><input id="album_tag_pks_1" name="album[tag_pks][]" type="checkbox" value="1"/> s</label><label class="option"><input checked="checked" id="album_tag_pks_2" name="album[tag_pks][]" type="checkbox" value="2"/> t</label><label class="option"><input id="album_tag_pks_3" name="album[tag_pks][]" type="checkbox" value="3"/> u</label>'
  end

  it "should handle Raw label for associations with :as=>:checkbox" do
    @b.input(:tracks, :as=>:checkbox, :label=>Forme.raw('Foo<br />:')).must_equal '<span class="label">Foo<br />:</span><label class="option"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label><label class="option"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label><label class="option"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label>'
    @b.input(:tracks, :as=>:checkbox, :label=>'Foo<br />').must_equal '<span class="label">Foo&lt;br /&gt;</span><label class="option"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label><label class="option"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label><label class="option"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label>'
  end
  
  it "should correctly use the forms wrapper for wrapping radio buttons for one_to_many associations with :as=>:checkbox option" do
    @b = Forme::Form.new(@ab, :wrapper=>:li)
    @b.input(:tracks, :as=>:checkbox).must_equal '<li class="one_to_many"><span class="label">Tracks</span><label class="option"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label><label class="option"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label><label class="option"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label></li>'
  end
  
  it "should support custom wrappers for one_to_many associations with :as=>:checkbox via :tag_wrapper option" do
    @b = Forme::Form.new(@ab, :wrapper=>:li)
    @b.input(:tracks, :as=>:checkbox, :wrapper=>proc{|t, i| i.tag(:div, i.opts[:wrapper_attr], [t])}, :tag_wrapper=>proc{|t, i| i.tag(:span, {}, [t])}).must_equal '<div class="one_to_many"><span class="label">Tracks</span><span><label class="option"><input checked="checked" id="album_track_pks_1" name="album[track_pks][]" type="checkbox" value="1"/> m</label></span><span><label class="option"><input checked="checked" id="album_track_pks_2" name="album[track_pks][]" type="checkbox" value="2"/> n</label></span><span><label class="option"><input id="album_track_pks_3" name="album[track_pks][]" type="checkbox" value="3"/> o</label></span></div>'
  end
  
  it "should use a text field methods not backed by columns" do
    @b.input(:artist_name).must_equal '<label>Artist name: <input id="album_artist_name" name="album[artist_name]" type="text" value="a"/></label>'
    @c.input(:artist_name).must_equal '<label>Artist name: <input id="album_artist_name" name="album[artist_name]" type="text" value="d"/></label>'
  end

  it "should handle errors on methods not backed by columns" do
    @ab.errors.add(:artist_name, 'foo')
    @b.input(:artist_name).must_equal '<label>Artist name: <input aria-describedby="album_artist_name_error_message" aria-invalid="true" class="error" id="album_artist_name" name="album[artist_name]" type="text" value="a"/></label><span class="error_message" id="album_artist_name_error_message">foo</span>'
  end

  it "should respect a :type option with a schema type as the input type for methods not backed by columns" do
    def @ab.foo; false end
    @b.input(:foo, :type=>:boolean, :as=>:select).must_equal '<label>Foo: <select id="album_foo" name="album[foo]"><option value=""></option><option value="t">True</option><option selected="selected" value="f">False</option></select></label>'
  end

  it "should respect a :type option with an input type as the input type for methods not backed by columns" do
    def @ab.foo; "bar" end
    @b.input(:foo, :type=>:phone).must_equal '<label>Foo: <input id="album_foo" name="album[foo]" type="phone" value="bar"/></label>'
  end

  it "should not override an explicit :error setting" do
    @ab.errors.add(:name, 'tis not valid')
    @b.input(:name, :error=>nil).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" type="text" value="b"/></label>'
  end
  
  it "should correctly show an error message if there is one" do
    @ab.errors.add(:name, 'tis not valid')
    @b.input(:name).must_equal '<label>Name: <input aria-describedby="album_name_error_message" aria-invalid="true" class="error" id="album_name" maxlength="255" name="album[name]" type="text" value="b"/></label><span class="error_message" id="album_name_error_message">tis not valid</span>'
  end
  
  it "should correctly show an error message for many_to_one associations if there is one" do
    @ab.errors.add(:artist_id, 'tis not valid')
    @b.input(:artist).must_equal '<label>Artist: <select aria-describedby="album_artist_id_error_message" aria-invalid="true" class="error" id="album_artist_id" name="album[artist_id]"><option value=""></option><option selected="selected" value="1">a</option><option value="2">d</option></select></label><span class="error_message" id="album_artist_id_error_message">tis not valid</span>'
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
    @b.input(:foo, :type=>:string).must_equal '<label>Foo: <input id="album_foo" name="album[foo]" type="text"/></label>'
    @b.input(:password, :type=>:string).must_equal '<label>Password: <input id="album_password" name="album[password]" type="password"/></label>'
  end

  it "should respect a :type option with an input type as the input type for unhandled fields" do
    @b.input(:foo, :type=>:phone).must_equal '<label>Foo: <input id="album_foo" name="album[foo]" type="phone"/></label>'
  end

  it "should respect a :multiple option for the name attribute for unhandled fields" do
    @b.input(:foo, :type=>:phone, :multiple=>true).must_equal '<label>Foo: <input id="album_foo" name="album[foo][]" type="phone"/></label>'
  end

  it "should add required attribute if the column doesn't support nil values" do
    def @ab.db_schema; h = super.dup; h[:name] = h[:name].merge(:allow_null=>false); h end
    @b.input(:name).must_equal '<label>Name<abbr title="required">*</abbr>: <input id="album_name" maxlength="255" name="album[name]" required="required" type="text" value="b"/></label>'
  end
  
  it "should use allow nested forms with many_to_one associations" do
    Forme.form(@ab){|f| f.subform(:artist){f.input(:name)}}.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Artist</legend><label>Name: <input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></label></fieldset></form>'
  end
  
  it "should have #subform respect an :inputs option" do
    Forme.form(@ab){|f| f.subform(:artist, :inputs=>[:name])}.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Artist</legend><label>Name: <input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></label></fieldset></form>'
  end
  
  it "should have #subform respect an :obj option overriding the object to use" do
    Forme.form(@ab){|f| f.subform(:artist, :inputs=>[:name], :obj=>Artist.new(:name=>'b'))}.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Artist</legend><label>Name: <input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="b"/></label></fieldset></form>'
  end
  
  it "should have #subform respect a :legend option if :inputs is used" do
    Forme.form(@ab){|f| f.subform(:artist, :inputs=>[:name], :legend=>'Foo')}.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Foo</legend><label>Name: <input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></label></fieldset></form>'
  end
  
  it "should have #subform respect a callable :legend option if :inputs is used" do
    Forme.form(@ab){|f| f.subform(:artist, :inputs=>[:name], :legend=>proc{|o| "Foo - #{o.name}"})}.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Foo - a</legend><label>Name: <input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></label></fieldset></form>'
  end
  
  it "should not add hidden primary key field for new many_to_one associated objects" do
    @ab.associations[:artist] = Artist.new(:name=>'a')
    Forme.form(@ab){|f| f.subform(:artist){f.input(:name)}}.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Artist</legend><label>Name: <input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></label></fieldset></form>'
  end
  
  it "should use allow nested forms with one_to_one associations" do
    Forme.form(@ab){|f| f.subform(:album_info, :obj=>AlbumInfo.new(:info=>'a')){f.input(:info)}}.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Album info</legend><label>Info: <input id="album_album_info_attributes_info" maxlength="255" name="album[album_info_attributes][info]" type="text" value="a"/></label></fieldset></form>'
  end
  
  it "should use allow nested forms with one_to_many associations" do
    Forme.form(@ab){|f| f.subform(:tracks){f.input(:name)}}.must_equal '<form class="forme album" method="post"><input id="album_tracks_attributes_0_id" name="album[tracks_attributes][0][id]" type="hidden" value="1"/><input id="album_tracks_attributes_1_id" name="album[tracks_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Track #1</legend><label>Name: <input id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="m"/></label></fieldset><fieldset class="inputs"><legend>Track #2</legend><label>Name: <input id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="n"/></label></fieldset></form>'
  end
  
  it "should support :obj option for *_to_many associations" do
    Forme.form(@ab){|f| f.subform(:tracks, :obj=>[Track.new(:name=>'x'), Track.load(:id=>5, :name=>'y')]){f.input(:name)}}.must_equal '<form class="forme album" method="post"><input id="album_tracks_attributes_1_id" name="album[tracks_attributes][1][id]" type="hidden" value="5"/><fieldset class="inputs"><legend>Track #1</legend><label>Name: <input id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="x"/></label></fieldset><fieldset class="inputs"><legend>Track #2</legend><label>Name: <input id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="y"/></label></fieldset></form>'
  end
  
  it "should auto number legends when using subform with inputs for *_to_many associations" do
    Forme.form(@ab){|f| f.subform(:tracks, :inputs=>[:name])}.must_equal '<form class="forme album" method="post"><input id="album_tracks_attributes_0_id" name="album[tracks_attributes][0][id]" type="hidden" value="1"/><input id="album_tracks_attributes_1_id" name="album[tracks_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Track #1</legend><label>Name: <input id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="m"/></label></fieldset><fieldset class="inputs"><legend>Track #2</legend><label>Name: <input id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="n"/></label></fieldset></form>'
  end
  
  it "should support callable :legend option when using subform with inputs for *_to_many associations" do
    Forme.form(@ab){|f| f.subform(:tracks, :inputs=>[:name], :legend=>proc{|o, i| "Track #{i} (#{o.name})"})}.must_equal '<form class="forme album" method="post"><input id="album_tracks_attributes_0_id" name="album[tracks_attributes][0][id]" type="hidden" value="1"/><input id="album_tracks_attributes_1_id" name="album[tracks_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Track 0 (m)</legend><label>Name: <input id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="m"/></label></fieldset><fieldset class="inputs"><legend>Track 1 (n)</legend><label>Name: <input id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="n"/></label></fieldset></form>'
  end
  
  it "should not add hidden primary key field for nested forms with one_to_many associations with new objects" do
    @ab.associations[:tracks] = [Track.new(:name=>'m'), Track.new(:name=>'n')]
    Forme.form(@ab){|f| f.subform(:tracks){f.input(:name)}}.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Track #1</legend><label>Name: <input id="album_tracks_attributes_0_name" maxlength="255" name="album[tracks_attributes][0][name]" type="text" value="m"/></label></fieldset><fieldset class="inputs"><legend>Track #2</legend><label>Name: <input id="album_tracks_attributes_1_name" maxlength="255" name="album[tracks_attributes][1][name]" type="text" value="n"/></label></fieldset></form>'
  end
  
  it "should use allow nested forms with many_to_many associations" do
    Forme.form(@ab){|f| f.subform(:tags){f.input(:name)}}.must_equal '<form class="forme album" method="post"><input id="album_tags_attributes_0_id" name="album[tags_attributes][0][id]" type="hidden" value="1"/><input id="album_tags_attributes_1_id" name="album[tags_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Tag #1</legend><label>Name: <input id="album_tags_attributes_0_name" maxlength="255" name="album[tags_attributes][0][name]" type="text" value="s"/></label></fieldset><fieldset class="inputs"><legend>Tag #2</legend><label>Name: <input id="album_tags_attributes_1_name" maxlength="255" name="album[tags_attributes][1][name]" type="text" value="t"/></label></fieldset></form>'
  end
  
  it "should not add hidden primary key field for nested forms with many_to_many associations with new objects" do
    @ab.associations[:tags] = [Tag.new(:name=>'s'), Tag.new(:name=>'t')]
    Forme.form(@ab){|f| f.subform(:tags){f.input(:name)}}.must_equal '<form class="forme album" method="post"><fieldset class="inputs"><legend>Tag #1</legend><label>Name: <input id="album_tags_attributes_0_name" maxlength="255" name="album[tags_attributes][0][name]" type="text" value="s"/></label></fieldset><fieldset class="inputs"><legend>Tag #2</legend><label>Name: <input id="album_tags_attributes_1_name" maxlength="255" name="album[tags_attributes][1][name]" type="text" value="t"/></label></fieldset></form>'
  end

  it "should handle multiple nested levels" do
    Forme.form(Artist[1]){|f| f.subform(:albums){f.input(:name); f.subform(:tracks){f.input(:name)}}}.to_s.must_equal '<form class="forme artist" method="post"><input id="artist_albums_attributes_0_id" name="artist[albums_attributes][0][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Album #1</legend><label>Name: <input id="artist_albums_attributes_0_name" maxlength="255" name="artist[albums_attributes][0][name]" type="text" value="b"/></label><input id="artist_albums_attributes_0_tracks_attributes_0_id" name="artist[albums_attributes][0][tracks_attributes][0][id]" type="hidden" value="1"/><input id="artist_albums_attributes_0_tracks_attributes_1_id" name="artist[albums_attributes][0][tracks_attributes][1][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Track #1</legend><label>Name: <input id="artist_albums_attributes_0_tracks_attributes_0_name" maxlength="255" name="artist[albums_attributes][0][tracks_attributes][0][name]" type="text" value="m"/></label></fieldset><fieldset class="inputs"><legend>Track #2</legend><label>Name: <input id="artist_albums_attributes_0_tracks_attributes_1_name" maxlength="255" name="artist[albums_attributes][0][tracks_attributes][1][name]" type="text" value="n"/></label></fieldset></fieldset></form>'
  end

  it "should have #subform :grid option create a grid" do
    Forme.form(@ab){|f| f.subform(:artist, :inputs=>[:name], :grid=>true)}.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><table><caption>Artist</caption><thead><tr><th>Name</th></tr></thead><tbody><tr><td class="string"><input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end
  
  it "should have #subform :grid option respect :inputs_opts option to pass options to inputs" do
    Forme.form(@ab){|f| f.subform(:artist, :inputs=>[:name], :grid=>true, :inputs_opts=>{:attr=>{:class=>'foo'}})}.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><table class="foo"><caption>Artist</caption><thead><tr><th>Name</th></tr></thead><tbody><tr><td class="string"><input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end
  
  it "should have #subform :grid option handle :legend and :labels options" do
    Forme.form(@ab){|f| f.subform(:artist, :inputs=>[:name], :grid=>true, :legend=>'Foo', :labels=>%w'Bar')}.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><table><caption>Foo</caption><thead><tr><th>Bar</th></tr></thead><tbody><tr><td class="string"><input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end
  
  it "should have #subform :grid option handle :legend and :labels nil values" do
    Forme.form(@ab){|f| f.subform(:artist, :inputs=>[:name], :grid=>true, :legend=>nil, :labels=>nil)}.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><table><tbody><tr><td class="string"><input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end

  it "should have #subform :grid option handle :skip_primary_key option" do
    Forme.form(@ab){|f| f.subform(:artist, :inputs=>[:name], :grid=>true, :skip_primary_key=>true)}.must_equal '<form class="forme album" method="post"><table><caption>Artist</caption><thead><tr><th>Name</th></tr></thead><tbody><tr><td class="string"><input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end
  
  it "should have #subform :grid option handle no :inputs or :labels" do
    Forme.form(@ab){|f| f.subform(:artist, :grid=>true){f.input(:name)}}.must_equal '<form class="forme album" method="post"><input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="1"/><table><caption>Artist</caption><tbody><tr><td class="string"><input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="a"/></td></tr></tbody></table></form>'
  end
  
  it "should handle non-Sequel forms with Sequel inputs" do
    Forme.form{|f| f.input(:name, :obj=>@ab).must_equal '<label>Name: <input id="name" maxlength="255" name="name" type="text" value="b"/></label>'}
  end
end

describe "Forme Sequel plugin default input types based on column names" do
  def f(name)
    DB.create_table!(:test){String name}
    Forme::Form.new(Class.new(Sequel::Model).class_eval{def self.name; 'Test' end; set_dataset :test}.new).input(name, :value=>'foo')
  end

  it "should use password input with no value for string columns with name password" do
    f(:password).must_equal '<label>Password: <input id="test_password" maxlength="255" name="test[password]" type="password"/></label>'
  end

  it "should use email input for string columns with name email" do
    f(:email).must_equal '<label>Email: <input id="test_email" maxlength="255" name="test[email]" type="email" value="foo"/></label>'
  end

  it "should use tel input for string columns with name phone or fax" do
    f(:phone).must_equal '<label>Phone: <input id="test_phone" maxlength="255" name="test[phone]" type="tel" value="foo"/></label>'
    f(:fax).must_equal '<label>Fax: <input id="test_fax" maxlength="255" name="test[fax]" type="tel" value="foo"/></label>'
  end

  it "should use url input for string columns with name url, uri, or website" do
    f(:url).must_equal '<label>Url: <input id="test_url" maxlength="255" name="test[url]" type="url" value="foo"/></label>'
    f(:uri).must_equal '<label>Uri: <input id="test_uri" maxlength="255" name="test[uri]" type="url" value="foo"/></label>'
    f(:website).must_equal '<label>Website: <input id="test_website" maxlength="255" name="test[website]" type="url" value="foo"/></label>'
  end
end 

describe "Forme Sequel plugin default input types based on column type" do
  def f(type)
    DB.create_table!(:test){column :foo, type}
    Forme::Form.new(Class.new(Sequel::Model).class_eval{def self.name; 'Test' end; set_dataset :test}.new).input(:foo, :value=>'foo')
  end

  it "should use a file input for blob types" do
    f(File).must_equal '<label>Foo: <input id="test_foo" name="test[foo]" type="file"/></label>'
  end
end

describe "Forme Sequel::Model validation parsing" do
  def f(*a)
    c = Class.new(Album){def self.name; "Album"; end}
    c.plugin :validation_class_methods
    c.send(*a)
    Forme::Form.new(c.new)
  end

  it "should turn format into a pattern" do
    f(:validates_format_of, :name, :with=>/[A-z]+/).input(:name).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" pattern="[A-z]+" type="text"/></label>'
  end

  it "should not override given :pattern for format validation" do
    f(:validates_format_of, :name, :with=>/[A-z]+/).input(:name, :attr=>{:pattern=>'[A-Z]+'}).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" pattern="[A-Z]+" type="text"/></label>'
  end

  it "should respect :title option for format" do
    f(:validates_format_of, :name, :with=>/[A-z]+/, :title=>'Foo').input(:name).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" pattern="[A-z]+" title="Foo" type="text"/></label>'
  end

  it "should not override given :title for format validation" do
    f(:validates_format_of, :name, :with=>/[A-z]+/, :title=>'Foo').input(:name, :attr=>{:title=>'Bar'}).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" pattern="[A-z]+" title="Bar" type="text"/></label>'
  end

  it "should use maxlength for length :maximum, :is, and :within" do
    f(:validates_length_of, :name, :maximum=>10).input(:name).must_equal '<label>Name: <input id="album_name" maxlength="10" name="album[name]" type="text"/></label>'
    f(:validates_length_of, :name, :is=>10).input(:name).must_equal '<label>Name: <input id="album_name" maxlength="10" name="album[name]" type="text"/></label>'
    f(:validates_length_of, :name, :within=>2..10).input(:name).must_equal '<label>Name: <input id="album_name" maxlength="10" name="album[name]" type="text"/></label>'
    f(:validates_length_of, :name, :within=>2...11).input(:name).must_equal '<label>Name: <input id="album_name" maxlength="10" name="album[name]" type="text"/></label>'
  end

  it "should not override given :maxlength" do
    f(:validates_length_of, :name, :maximum=>10).input(:name, :attr=>{:maxlength=>20}).must_equal '<label>Name: <input id="album_name" maxlength="20" name="album[name]" type="text"/></label>'
  end

  it "should not use maxlength for :within that is not a range" do
    f(:validates_length_of, :name, :within=>(2..10).to_a).input(:name).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" type="text"/></label>'
  end

  it "should turn numericality into a pattern" do
    f(:validates_numericality_of, :name).input(:name).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" pattern="^[+\-]?\d+(\.\d+)?$" title="must be a number" type="text"/></label>'
  end

  it "should turn numericality :only_integer into a pattern" do
    f(:validates_numericality_of, :name, :only_integer=>true).input(:name).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" pattern="^[+\-]?\d+$" title="must be a number" type="text"/></label>'
  end

  it "should not override given :pattern for numericality validation" do
    f(:validates_numericality_of, :name).input(:name, :attr=>{:pattern=>'[0-9]+'}).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" pattern="[0-9]+" title="must be a number" type="text"/></label>'
  end

  it "should respect :title option for numericality" do
    f(:validates_numericality_of, :name, :title=>'Foo').input(:name).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" pattern="^[+\-]?\d+(\.\d+)?$" title="Foo" type="text"/></label>'
  end

  it "should not override given :title for numericality validation" do
    f(:validates_numericality_of, :name, :title=>'Foo').input(:name, :attr=>{:title=>'Bar'}).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" pattern="^[+\-]?\d+(\.\d+)?$" title="Bar" type="text"/></label>'
  end

  it "should respect :placeholder option for any validation" do
    f(:validates_uniqueness_of, :name, :placeholder=>'must be unique').input(:name).must_equal '<label>Name: <input id="album_name" maxlength="255" name="album[name]" placeholder="must be unique" type="text"/></label>'
  end
end

describe "Forme Sequel::Model default namespacing" do
  before do
    module Foo
      class Album < ::Album
      end
    end

    @ab = Foo::Album[1]
    @b = Forme::Form.new(@ab)
  end
  after do
    Object.send(:remove_const, :Foo)
  end

  it "namespaces the form class" do
    @b.form.must_equal '<form class="forme foo/album" method="post"></form>'
  end

  it "namespaces the input id and name" do
    @b.input(:name).must_equal '<label>Name: <input id="foo/album_name" maxlength="255" name="foo/album[name]" type="text" value="b"/></label>'
  end
end

describe "Forme Sequel::Model custom namespacing" do
  before do
    module Bar
      class Album < ::Album
        def forme_namespace
          'bar_album'
        end
      end
    end

    @ab = Bar::Album[1]
    @b = Forme::Form.new(@ab)
  end
  after do
    Object.send(:remove_const, :Bar)
  end

  it "namespaces the form class" do
    @b.form.must_equal '<form class="forme bar_album" method="post"></form>'
  end

  it "namespaces the form input and name" do
    @b.input(:name).must_equal '<label>Name: <input id="bar_album_name" maxlength="255" name="bar_album[name]" type="text" value="b"/></label>'
  end
end
