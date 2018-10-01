require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require 'forme/bs3'

describe "Forme Bootstrap3 (BS3) forms" do
  def sel(opts, s)
    opts.map{|o| "<option #{'selected="selected" ' if o == s}value=\"#{o}\">#{sprintf("%02i", o)}</option>"}.join
  end

  before do
    @f = Forme::Form.new(:config=>:bs3)
  end

  it "should create a simple input tags" do
    @f.input(:text).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/></div>'
    @f.input(:radio).to_s.must_equal '<div class="radio"><input type="radio"/></div>'
    @f.input(:password).to_s.must_equal '<div class="form-group"><input class="form-control" type="password"/></div>'
    @f.input(:checkbox).to_s.must_equal '<div class="checkbox"><input type="checkbox"/></div>'
    @f.input(:submit).to_s.must_equal '<input class="btn btn-default" type="submit"/>'
  end

  it "should use :name option as attribute" do
    @f.input(:text, :name=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" name="foo" type="text"/></div>'
  end

  it "should use :id option as attribute" do
    @f.input(:text, :id=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" id="foo" type="text"/></div>'
  end

  it "should use :class option as attribute" do
    @f.input(:text, :class=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control foo" type="text"/></div>'
  end

  it "should use :value option as attribute" do
    @f.input(:text, :value=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" type="text" value="foo"/></div>'
  end

  it "should use :placeholder option as attribute" do
    @f.input(:text, :placeholder=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" placeholder="foo" type="text"/></div>'
  end

  it "should use :style option as attribute" do
    @f.input(:text, :style=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" style="foo" type="text"/></div>'
  end

  it "should use :key option as name and id attributes" do
    @f.input(:text, :key=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" id="foo" name="foo" type="text"/></div>'
  end

  it "should use :key_id option as suffix for :key option id attributes" do
    @f.input(:text, :key=>"foo", :key_id=>'bar').to_s.must_equal '<div class="form-group"><input class="form-control" id="foo_bar" name="foo" type="text"/></div>'
  end

  it "should have :key option respect :multiple option" do
    @f.input(:text, :key=>"foo", :multiple=>true).to_s.must_equal '<div class="form-group"><input class="form-control" id="foo" name="foo[]" type="text"/></div>'
  end

  it "should use :key option respect form's current namespace" do
    @f.with_opts(:namespace=>['bar']) do
      @f.input(:text, :key=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_foo" name="bar[foo]" type="text"/></div>'
      @f.input(:text, :key=>"foo", :multiple=>true).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_foo" name="bar[foo][]" type="text"/></div>'
      @f.with_opts(:namespace=>['bar', 'baz']) do
        @f.input(:text, :key=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_baz_foo" name="bar[baz][foo]" type="text"/></div>'
      end
    end
  end

  it "should consider form's :values hash for default values based on the :key option if :value is not present" do
    @f.opts[:values] = {'foo'=>'baz'}
    @f.input(:text, :key=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" id="foo" name="foo" type="text" value="baz"/></div>'
    @f.input(:text, :key=>"foo", :value=>'x').to_s.must_equal '<div class="form-group"><input class="form-control" id="foo" name="foo" type="text" value="x"/></div>'

    @f.input(:text, :key=>:foo).to_s.must_equal '<div class="form-group"><input class="form-control" id="foo" name="foo" type="text" value="baz"/></div>'
    @f.opts[:values] = {:foo=>'baz'}
    @f.input(:text, :key=>:foo).to_s.must_equal '<div class="form-group"><input class="form-control" id="foo" name="foo" type="text" value="baz"/></div>'
  end

  it "should consider form's :values hash for default values based on the :key option when using namespaces" do
    @f.opts[:values] = {'bar'=>{'foo'=>'baz'}}
    @f.with_opts(:namespace=>['bar']) do
      @f.input(:text, :key=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_foo" name="bar[foo]" type="text" value="baz"/></div>'
      @f.input(:text, :key=>"foo", :value=>'x').to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_foo" name="bar[foo]" type="text" value="x"/></div>'
      @f.input(:text, :key=>:foo).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_foo" name="bar[foo]" type="text" value="baz"/></div>'
    end

    @f.with_opts(:namespace=>[:bar]) do
      @f.input(:text, :key=>:foo).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_foo" name="bar[foo]" type="text" value="baz"/></div>'

      @f.opts[:values] = {:bar=>{:foo=>'baz'}}
      @f.input(:text, :key=>:foo).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_foo" name="bar[foo]" type="text" value="baz"/></div>'
      @f.opts[:values] = {:bar=>{}}
      @f.input(:text, :key=>:foo).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_foo" name="bar[foo]" type="text"/></div>'
      @f.opts[:values] = {}
      @f.input(:text, :key=>:foo).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_foo" name="bar[foo]" type="text"/></div>'

      @f.opts[:values] = {'bar'=>{'quux'=>{'foo'=>'baz'}}}
      @f.with_opts(:namespace=>['bar', 'quux']) do
        @f.input(:text, :key=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_quux_foo" name="bar[quux][foo]" type="text" value="baz"/></div>'
      end
    end
  end

  it "should support a with_obj method that changes the object and namespace for the given block" do
    @f.with_obj([:a, :c], 'bar') do
      @f.input(:first).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_first" name="bar[first]" type="text" value="a"/></div>'
      @f.with_obj([:b], 'baz') do
        @f.input(:first).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_baz_first" name="bar[baz][first]" type="text" value="b"/></div>'
      end
      @f.with_obj([:b], %w'baz quux') do
        @f.input(:first).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_baz_quux_first" name="bar[baz][quux][first]" type="text" value="b"/></div>'
      end
      @f.with_obj([:b]) do
        @f.input(:first).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_first" name="bar[first]" type="text" value="b"/></div>'
      end
      @f.input(:last).to_s.must_equal '<div class="form-group"><input class="form-control" id="bar_last" name="bar[last]" type="text" value="c"/></div>'
    end
  end

  it "should support a each_obj method that changes the object and namespace for multiple objects for the given block" do
    @f.tag(:form) do
      @f.each_obj([[:a, :c], [:b, :d]], 'bar') do
        @f.input(:first)
        @f.input(:last)
      end
    end.to_s.must_equal '<form><div class="form-group"><input class="form-control" id="bar_0_first" name="bar[0][first]" type="text" value="a"/></div><div class="form-group"><input class="form-control" id="bar_0_last" name="bar[0][last]" type="text" value="c"/></div><div class="form-group"><input class="form-control" id="bar_1_first" name="bar[1][first]" type="text" value="b"/></div><div class="form-group"><input class="form-control" id="bar_1_last" name="bar[1][last]" type="text" value="d"/></div></form>'

    @f.tag(:form) do
      @f.each_obj([[:a, :c], [:b, :d]], %w'bar baz') do
        @f.input(:first)
        @f.input(:last)
      end
    end.to_s.must_equal '<form><div class="form-group"><input class="form-control" id="bar_baz_0_first" name="bar[baz][0][first]" type="text" value="a"/></div><div class="form-group"><input class="form-control" id="bar_baz_0_last" name="bar[baz][0][last]" type="text" value="c"/></div><div class="form-group"><input class="form-control" id="bar_baz_1_first" name="bar[baz][1][first]" type="text" value="b"/></div><div class="form-group"><input class="form-control" id="bar_baz_1_last" name="bar[baz][1][last]" type="text" value="d"/></div></form>'

    @f.tag(:form) do
      @f.each_obj([[:a, :c], [:b, :d]]) do
        @f.input(:first)
        @f.input(:last)
      end
    end.to_s.must_equal '<form><div class="form-group"><input class="form-control" id="0_first" name="0[first]" type="text" value="a"/></div><div class="form-group"><input class="form-control" id="0_last" name="0[last]" type="text" value="c"/></div><div class="form-group"><input class="form-control" id="1_first" name="1[first]" type="text" value="b"/></div><div class="form-group"><input class="form-control" id="1_last" name="1[last]" type="text" value="d"/></div></form>'
  end

  it "should allow overriding form inputs on a per-block basis" do
    @f.input(:text).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/></div>'
    @f.with_opts(:wrapper=>:div){@f.input(:text).to_s}.must_equal '<div><input class="form-control" type="text"/></div>'
    @f.with_opts(:wrapper=>:div){@f.input(:text).to_s.must_equal '<div><input class="form-control" type="text"/></div>'}
    @f.with_opts(:wrapper=>:div) do
      @f.input(:text).to_s.must_equal '<div><input class="form-control" type="text"/></div>'
      @f.with_opts(:wrapper=>:li){@f.input(:text).to_s.must_equal '<li><input class="form-control" type="text"/></li>'}
      @f.input(:text).to_s.must_equal '<div><input class="form-control" type="text"/></div>'
    end
    @f.input(:text).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/></div>'
  end

  it "should handle delayed formatting when overriding form inputs on a per-block basis" do
    @f.form do
      @f.input(:text)
      @f.with_opts(:wrapper=>:div) do
        @f.input(:text)
        @f.with_opts(:wrapper=>:li){@f.input(:text)}
        @f.input(:text)
      end
      @f.input(:text)
    end.to_s.must_equal '<form><div class="form-group"><input class="form-control" type="text"/></div><div><input class="form-control" type="text"/></div><li><input class="form-control" type="text"/></li><div><input class="form-control" type="text"/></div><div class="form-group"><input class="form-control" type="text"/></div></form>'
  end

  it "should support :obj method to with_opts for changing the obj inside the block" do
    @f.form do
      @f.with_opts(:obj=>[:a, :c]) do
        @f.input(:first)
        @f.with_opts(:obj=>[:b]){@f.input(:first)}
        @f.input(:last)
      end
    end.to_s.must_equal '<form><div class="form-group"><input class="form-control" id="first" name="first" type="text" value="a"/></div><div class="form-group"><input class="form-control" id="first" name="first" type="text" value="b"/></div><div class="form-group"><input class="form-control" id="last" name="last" type="text" value="c"/></div></form>'
  end
  
  it "should allow arbitrary attributes using the :attr option" do
    @f.input(:text, :attr=>{:bar=>"foo"}).to_s.must_equal '<div class="form-group"><input bar="foo" class="form-control" type="text"/></div>'
  end

  it "should convert the :data option into attributes" do
    @f.input(:text, :data=>{:bar=>"foo"}).to_s.must_equal '<div class="form-group"><input class="form-control" data-bar="foo" type="text"/></div>'
  end

  it "should not have standard options override the :attr option" do
    @f.input(:text, :name=>:bar, :attr=>{:name=>"foo"}).to_s.must_equal '<div class="form-group"><input class="form-control" name="foo" type="text"/></div>'
  end

  it "should combine :class standard option with :attr option" do
    @f.input(:text, :class=>:bar, :attr=>{:class=>"foo"}).to_s.must_equal '<div class="form-group"><input class="form-control foo bar" type="text"/></div>'
  end

  it "should not have :data options override the :attr option" do
    @f.input(:text, :data=>{:bar=>"baz"}, :attr=>{:"data-bar"=>"foo"}).to_s.must_equal '<div class="form-group"><input class="form-control" data-bar="foo" type="text"/></div>'
  end

  it "should use :size and :maxlength options as attributes for text inputs" do
    @f.input(:text, :size=>5, :maxlength=>10).to_s.must_equal '<div class="form-group"><input class="form-control" maxlength="10" size="5" type="text"/></div>'
    @f.input(:textarea, :size=>5, :maxlength=>10).to_s.must_equal '<div class="form-group"><textarea class="form-control"></textarea></div>'
  end

  it "should create hidden input with value 0 for each checkbox with a name" do
    @f.input(:checkbox, :name=>"foo").to_s.must_equal '<div class="checkbox"><input name="foo" type="hidden" value="0"/><input name="foo" type="checkbox"/></div>'
  end

  it "should not create hidden input with value 0 for each checkbox with a name if :no_hidden option is used" do
    @f.input(:checkbox, :name=>"foo", :no_hidden=>true).to_s.must_equal '<div class="checkbox"><input name="foo" type="checkbox"/></div>'
  end

  it "should create hidden input with _hidden appended to id for each checkbox with a name and id" do
    @f.input(:checkbox, :name=>"foo", :id=>"bar").to_s.must_equal '<div class="checkbox"><input id="bar_hidden" name="foo" type="hidden" value="0"/><input id="bar" name="foo" type="checkbox"/></div>'
  end
  
  it "should create hidden input with value f for each checkbox with a name and value t" do
    @f.input(:checkbox, :name=>"foo", :value=>"t").to_s.must_equal '<div class="checkbox"><input name="foo" type="hidden" value="f"/><input name="foo" type="checkbox" value="t"/></div>'
  end

  it "should use :hidden_value option for value of hidden input for checkbox" do
    @f.input(:checkbox, :name=>"foo", :hidden_value=>"no").to_s.must_equal '<div class="checkbox"><input name="foo" type="hidden" value="no"/><input name="foo" type="checkbox"/></div>'
  end

  it "should create hidden input" do
    @f.input(:hidden).to_s.must_equal '<input type="hidden"/>'
  end

  it "should handle :checked option" do
    @f.input(:checkbox, :checked=>true).to_s.must_equal '<div class="checkbox"><input checked="checked" type="checkbox"/></div>'
    @f.input(:checkbox, :checked=>false).to_s.must_equal '<div class="checkbox"><input type="checkbox"/></div>'
  end

  it "should create textarea tag" do
    @f.input(:textarea).to_s.must_equal '<div class="form-group"><textarea class="form-control"></textarea></div>'
    @f.input(:textarea, :value=>'a').to_s.must_equal '<div class="form-group"><textarea class="form-control">a</textarea></div>'
  end

  it "should use :cols and :rows options as attributes for textarea inputs" do
    @f.input(:text, :cols=>5, :rows=>10).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/></div>'
    @f.input(:textarea, :cols=>5, :rows=>10).to_s.must_equal '<div class="form-group"><textarea class="form-control" cols="5" rows="10"></textarea></div>'
  end

  it "should create select tag" do
    @f.input(:select).to_s.must_equal '<div class="form-group"><select class="form-control"></select></div>'
  end

  it "should respect multiple and size options in select tag" do
    @f.input(:select, :multiple=>true, :size=>10).to_s.must_equal '<div class="form-group"><select class="form-control" multiple="multiple" size="10"></select></div>'
  end

  it "should create date tag" do
    @f.input(:date).to_s.must_equal '<div class="form-group"><input class="form-control" type="date"/></div>'
  end

  it "should create datetime-local tag" do
    @f.input(:datetime).to_s.must_equal '<div class="form-group"><input class="form-control" type="datetime-local"/></div>'
  end

  it "should not error for input type :input" do
    @f.input(:input).to_s.must_equal '<div class="form-group"><input class="form-control" type="input"/></div>'
  end

  it "should use multiple select boxes for dates if the :as=>:select option is given" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5)).to_s.must_equal %{<div class="form-group"><select class="form-control" id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select class="form-control" id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select class="form-control" id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select></div>}
  end

  it "should allow ordering date select boxes via :order" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :order=>[:month, '/', :day, '/', :year]).to_s.must_equal %{<div class="form-group"><select class="form-control" id="bar" name="foo[month]">#{sel(1..12, 6)}</select>/<select class="form-control" id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>/<select class="form-control" id="bar_year" name="foo[year]">#{sel(1900..2050, 2011)}</select></div>}
  end

  it "should allow only using specific date select boxes via :order" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :order=>[:month, :year]).to_s.must_equal %{<div class="form-group"><select class="form-control" id="bar" name="foo[month]">#{sel(1..12, 6)}</select><select class="form-control" id="bar_year" name="foo[year]">#{sel(1900..2050, 2011)}</select></div>}
  end

  it "should support :select_options for dates when :as=>:select is given" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :select_options=>{:year=>1970..2020}).to_s.must_equal %{<div class=\"form-group\"><select class="form-control" id="bar" name="foo[year]">#{sel(1970..2020, 2011)}</select>-<select class="form-control" id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select class="form-control" id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select></div>}
  end

  it "should have explicit labeler and trtd wrapper work with multiple select boxes for dates" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :wrapper=>:trtd, :labeler=>:explicit, :label=>'Baz').to_s.must_equal %{<tr><td><label class="label-before" for="bar">Baz</label></td><td><select class="form-control" id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select class="form-control" id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select class="form-control" id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select></td></tr>}
  end

  it "should use multiple select boxes for datetimes if the :as=>:select option is given" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>DateTime.new(2011, 6, 5, 4, 3, 2)).to_s.must_equal %{<div class=\"form-group\"><select class="form-control" id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select class="form-control" id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select class="form-control" id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select> <select class="form-control" id="bar_hour" name="foo[hour]">#{sel(0..23, 4)}</select>:<select class="form-control" id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select>:<select class="form-control" id="bar_second" name="foo[second]">#{sel(0..59, 2)}</select></div>}
  end
  
  it "should allow ordering select boxes for datetimes via :order" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>DateTime.new(2011, 6, 5, 4, 3, 2), :order=>[:day, '/', :month, 'T', :hour, ':', :minute]).to_s.must_equal %{<div class=\"form-group\"><select class="form-control" id="bar" name="foo[day]">#{sel(1..31, 5)}</select>/<select class="form-control" id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>T<select class="form-control" id="bar_hour" name="foo[hour]">#{sel(0..23, 4)}</select>:<select class="form-control" id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select></div>}
  end

  it "should support :select_options for datetimes when :as=>:select option is given" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>DateTime.new(2011, 6, 5, 10, 3, 2), :select_options=>{:year=>1970..2020, :hour=>9..17}).to_s.must_equal %{<div class="form-group"><select class="form-control" id="bar" name="foo[year]">#{sel(1970..2020, 2011)}</select>-<select class="form-control" id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select class="form-control" id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select> <select class="form-control" id="bar_hour" name="foo[hour]">#{sel(9..17, 10)}</select>:<select class="form-control" id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select>:<select class="form-control" id="bar_second" name="foo[second]">#{sel(0..59, 2)}</select></div>}
  end

  it "should create select tag with options" do
    @f.input(:select, :options=>[1, 2, 3], :selected=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option>1</option><option selected="selected">2</option><option>3</option></select></div>'
    @f.input(:select, :options=>[1, 2, 3], :value=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option>1</option><option selected="selected">2</option><option>3</option></select></div>'
  end

  it "should create select tag with options and values" do
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option value="1">a</option><option selected="selected" value="2">b</option><option value="3">c</option></select></div>'
  end

  it "should create select tag with option groups" do
    @f.input(:select, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :selected=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><optgroup label="d"><option value="1">a</option><option selected="selected" value="2">b</option></optgroup><optgroup label="e"><option value="3">c</option></optgroup></select></div>'
  end

  it "should create select tag with option groups with attributes" do
    @f.input(:select, :optgroups=>[[{:label=>'d', :class=>'f'}, [[:a, 1], [:b, 2]]], [{:label=>'e', :class=>'g'}, [[:c, 3]]]], :selected=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><optgroup class="f" label="d"><option value="1">a</option><option selected="selected" value="2">b</option></optgroup><optgroup class="g" label="e"><option value="3">c</option></optgroup></select></div>'
  end

  it "should create select tag with options and values with hashes" do
    @f.input(:select, :options=>[[:a, {:foo=>1}], [:b, {:bar=>4, :value=>2}], [:c, {:baz=>3}]], :selected=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option foo="1">a</option><option bar="4" selected="selected" value="2">b</option><option baz="3">c</option></select></div>'
  end

  it "should create select tag with options and values using given method" do
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option>1</option><option selected="selected">2</option><option>3</option></select></div>'
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).to_s.must_equal '<div class="form-group"><select class="form-control"><option value="a">1</option><option selected="selected" value="b">2</option><option value="c">3</option></select></div>'
  end

  it "should use html attributes specified in options" do
    @f.input(:text, :value=>'foo', :name=>'bar').to_s.must_equal '<div class="form-group"><input class="form-control" name="bar" type="text" value="foo"/></div>'
    @f.input(:textarea, :value=>'foo', :name=>'bar').to_s.must_equal '<div class="form-group"><textarea class="form-control" name="bar">foo</textarea></div>'
    @f.input(:select, :name=>'bar', :options=>[1, 2, 3]).to_s.must_equal '<div class="form-group"><select class="form-control" name="bar"><option>1</option><option>2</option><option>3</option></select></div>'
  end

  it "should support :add_blank option for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option value=""></option><option selected="selected" value="2">b</option><option value="3">c</option></select></div>'
  end
  
  it "should use Forme.default_add_blank_prompt value if :add_blank option is true" do
    begin
      Forme.default_add_blank_prompt = 'foo'
      @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option value="">foo</option><option selected="selected" value="2">b</option><option value="3">c</option></select></div>'
    ensure
      Forme.default_add_blank_prompt = nil
    end
  end

  it "should use :add_blank option value as prompt if it is a String" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option value="">Prompt Here</option><option selected="selected" value="2">b</option><option value="3">c</option></select></div>'
  end

  it "should support :add_blank option with :blank_position :after for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :blank_position=>:after, :value=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option selected="selected" value="2">b</option><option value="3">c</option><option value=""></option></select></div>'
  end

  it "should support :add_blank option with :blank_attr option for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :blank_attr=>{:foo=>:bar}, :value=>2).to_s.must_equal '<div class="form-group"><select class="form-control"><option foo="bar" value=""></option><option selected="selected" value="2">b</option><option value="3">c</option></select></div>'
  end

  it "should create set of radio buttons" do
    @f.input(:radioset, :options=>[1, 2, 3], :selected=>2).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option"><input type="radio" value="1"/> 1</label></div><div class="radio"><label class="option"><input checked="checked" type="radio" value="2"/> 2</label></div><div class="radio"><label class="option"><input type="radio" value="3"/> 3</label></div></div>'
    @f.input(:radioset, :options=>[1, 2, 3], :value=>2).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option"><input type="radio" value="1"/> 1</label></div><div class="radio"><label class="option"><input checked="checked" type="radio" value="2"/> 2</label></div><div class="radio"><label class="option"><input type="radio" value="3"/> 3</label></div></div>'
  end

  it "should create set of radio buttons with options and values" do
    @f.input(:radioset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option"><input type="radio" value="1"/> a</label></div><div class="radio"><label class="option"><input checked="checked" type="radio" value="2"/> b</label></div><div class="radio"><label class="option"><input type="radio" value="3"/> c</label></div></div>'
  end

  it "should create set of radio buttons with options and values with hashes" do
    @f.input(:radioset, :options=>[[:a, {:attr=>{:foo=>1}}], [:b, {:class=>'foo', :value=>2}], [:c, {:id=>:baz}]], :selected=>2).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option"><input foo="1" type="radio" value="a"/> a</label></div><div class="radio"><label class="option"><input checked="checked" class="foo" type="radio" value="2"/> b</label></div><div class="radio"><label class="option" for="baz"><input id="baz" type="radio" value="c"/> c</label></div></div>'
  end

  it "should create set of radio buttons with options and values using given method" do
    @f.input(:radioset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option"><input type="radio" value="1"/> 1</label></div><div class="radio"><label class="option"><input checked="checked" type="radio" value="2"/> 2</label></div><div class="radio"><label class="option"><input type="radio" value="3"/> 3</label></div></div>'
    @f.input(:radioset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option"><input type="radio" value="a"/> 1</label></div><div class="radio"><label class="option"><input checked="checked" type="radio" value="b"/> 2</label></div><div class="radio"><label class="option"><input type="radio" value="c"/> 3</label></div></div>'
  end

  it "should support :add_blank option for radioset inputs" do
    @f.input(:radioset, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option"><input type="radio" value=""/> </label></div><div class="radio"><label class="option"><input checked="checked" type="radio" value="2"/> b</label></div><div class="radio"><label class="option"><input type="radio" value="3"/> c</label></div></div>'
  end

  it "should use :add_blank option value as prompt if it is a String" do
    @f.input(:radioset, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option"><input type="radio" value=""/> Prompt Here</label></div><div class="radio"><label class="option"><input checked="checked" type="radio" value="2"/> b</label></div><div class="radio"><label class="option"><input type="radio" value="3"/> c</label></div></div>'
  end

  it "should respect the :key option for radio sets" do
    @f.input(:radioset, :options=>[1, 2, 3], :key=>:foo, :value=>2).to_s.must_equal '<div class="radioset"><div class="radio"><label class="option" for="foo_1"><input id="foo_1" name="foo" type="radio" value="1"/> 1</label></div><div class="radio"><label class="option" for="foo_2"><input checked="checked" id="foo_2" name="foo" type="radio" value="2"/> 2</label></div><div class="radio"><label class="option" for="foo_3"><input id="foo_3" name="foo" type="radio" value="3"/> 3</label></div></div>'
  end

  it "should create set of radio buttons with fieldsets and legends for :optgroups" do
    @f.input(:radioset, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :selected=>2).to_s.must_equal '<div class="radioset"><fieldset><legend>d</legend><div class="radio"><label class="option"><input type="radio" value="1"/> a</label></div><div class="radio"><label class="option"><input checked="checked" type="radio" value="2"/> b</label></div></fieldset><fieldset><legend>e</legend><div class="radio"><label class="option"><input type="radio" value="3"/> c</label></div></fieldset></div>'
  end
  
  it "should create set of radio buttons with set label" do
    @f.input(:radioset, :options=>[1, 2, 3], :selected=>2, :label=>'foo').to_s.must_equal '<div class="radioset"><label>foo</label><div class="radio"><label class="option"><input type="radio" value="1"/> 1</label></div><div class="radio"><label class="option"><input checked="checked" type="radio" value="2"/> 2</label></div><div class="radio"><label class="option"><input type="radio" value="3"/> 3</label></div></div>'
  end

  it "should create set of checkbox buttons" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :selected=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option"><input type="checkbox" value="1"/> 1</label></div><div class="checkbox"><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="3"/> 3</label></div></div>'
    @f.input(:checkboxset, :options=>[1, 2, 3], :value=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option"><input type="checkbox" value="1"/> 1</label></div><div class="checkbox"><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="3"/> 3</label></div></div>'
  end

  it "should create set of checkbox buttons with options and values" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option"><input type="checkbox" value="1"/> a</label></div><div class="checkbox"><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="3"/> c</label></div></div>'
  end

  it "should create set of checkbox buttons with options and values with hashes" do
    @f.input(:checkboxset, :options=>[[:a, {:attr=>{:foo=>1}}], [:b, {:class=>'foo', :value=>2}], [:c, {:id=>:baz}]], :selected=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option"><input foo="1" type="checkbox" value="a"/> a</label></div><div class="checkbox"><label class="option"><input checked="checked" class="foo" type="checkbox" value="2"/> b</label></div><div class="checkbox"><label class="option" for="baz"><input id="baz" type="checkbox" value="c"/> c</label></div></div>'
  end
  
  it "should create set of checkbox buttons with options and values using given method" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option"><input type="checkbox" value="1"/> 1</label></div><div class="checkbox"><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="3"/> 3</label></div></div>'
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option"><input type="checkbox" value="a"/> 1</label></div><div class="checkbox"><label class="option"><input checked="checked" type="checkbox" value="b"/> 2</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="c"/> 3</label></div></div>'
  end
  
  it "should support :add_blank option for checkboxset inputs" do
    @f.input(:checkboxset, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option"><input type="checkbox" value=""/> </label></div><div class="checkbox"><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="3"/> c</label></div></div>'
  end

  it "should use :add_blank option value as prompt if it is a String" do
    @f.input(:checkboxset, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option"><input type="checkbox" value=""/> Prompt Here</label></div><div class="checkbox"><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="3"/> c</label></div></div>'
  end

  it "should respect the :key option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :key=>:foo, :value=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option" for="foo_1"><input id="foo_1" name="foo[]" type="checkbox" value="1"/> 1</label></div><div class="checkbox"><label class="option" for="foo_2"><input checked="checked" id="foo_2" name="foo[]" type="checkbox" value="2"/> 2</label></div><div class="checkbox"><label class="option" for="foo_3"><input id="foo_3" name="foo[]" type="checkbox" value="3"/> 3</label></div></div>'
  end

  it "should prefer the :name option to :key option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :key=>:foo, :name=>'bar[]', :value=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option" for="foo_1"><input id="foo_1" name="bar[]" type="checkbox" value="1"/> 1</label></div><div class="checkbox"><label class="option" for="foo_2"><input checked="checked" id="foo_2" name="bar[]" type="checkbox" value="2"/> 2</label></div><div class="checkbox"><label class="option" for="foo_3"><input id="foo_3" name="bar[]" type="checkbox" value="3"/> 3</label></div></div>'
  end
  
  it "should prefer the :name and :id option to :key option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :key=>:foo, :name=>'bar[]', :id=>:baz, :value=>2).to_s.must_equal '<div class="checkboxset"><div class="checkbox"><label class="option" for="baz_1"><input id="baz_1" name="bar[]" type="checkbox" value="1"/> 1</label></div><div class="checkbox"><label class="option" for="baz_2"><input checked="checked" id="baz_2" name="bar[]" type="checkbox" value="2"/> 2</label></div><div class="checkbox"><label class="option" for="baz_3"><input id="baz_3" name="bar[]" type="checkbox" value="3"/> 3</label></div></div>'
  end

  it "should respect the :error option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :error=>'foo-checkboxset', :value=>2).to_s.must_equal '<div class="checkboxset has-error"><div class="checkbox"><label class="option"><input type="checkbox" value="1"/> 1</label></div><div class="checkbox"><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label></div><div class="checkbox"><label class="option"><input type="checkbox" value="3"/> 3</label></div><span class="help-block with-errors">foo-checkboxset</span></div>'
  end

  it "should create set of checkbox buttons with fieldsets and legends for optgroups" do
    @f.input(:checkboxset, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :selected=>2).to_s.must_equal '<div class="checkboxset"><fieldset><legend>d</legend><div class="checkbox"><label class="option"><input type="checkbox" value="1"/> a</label></div><div class="checkbox"><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label></div></fieldset><fieldset><legend>e</legend><div class="checkbox"><label class="option"><input type="checkbox" value="3"/> c</label></div></fieldset></div>'
  end

  it "radio and checkbox inputs should handle :checked option" do
    @f.input(:radio, :checked=>true).to_s.must_equal '<div class="radio"><input checked="checked" type="radio"/></div>'
    @f.input(:radio, :checked=>false).to_s.must_equal '<div class="radio"><input type="radio"/></div>'
    @f.input(:checkbox, :checked=>true).to_s.must_equal '<div class="checkbox"><input checked="checked" type="checkbox"/></div>'
    @f.input(:checkbox, :checked=>false).to_s.must_equal '<div class="checkbox"><input type="checkbox"/></div>'
  end

  it "inputs should handle :autofocus option" do
    @f.input(:text, :autofocus=>true).to_s.must_equal '<div class="form-group"><input autofocus="autofocus" class="form-control" type="text"/></div>'
    @f.input(:text, :autofocus=>false).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/></div>'
  end

  it "inputs should handle :required option" do
    @f.input(:text, :required=>true).to_s.must_equal '<div class="form-group"><input class="form-control" required="required" type="text"/></div>'
    @f.input(:text, :required=>false).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/></div>'
  end

  it "inputs should handle :disabled option" do
    @f.input(:text, :disabled=>true).to_s.must_equal '<div class="form-group"><input class="form-control" disabled="disabled" type="text"/></div>'
    @f.input(:text, :disabled=>false).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/></div>'
  end

  it "inputs should not include options with nil values" do
    @f.input(:text, :name=>nil).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/></div>'
    @f.input(:textarea, :name=>nil).to_s.must_equal '<div class="form-group"><textarea class="form-control"></textarea></div>'
  end

  it "inputs should include options with false values" do
    @f.input(:text, :name=>false).to_s.must_equal '<div class="form-group"><input class="form-control" name="false" type="text"/></div>'
  end

  it "should automatically create a label if a :label option is used" do
    @f.input(:text, :label=>'Foo', :value=>'foo').to_s.must_equal '<div class="form-group"><label>Foo</label> <input class="form-control" type="text" value="foo"/></div>'
  end

  it "should set label attributes with :label_attr option" do
    @f.input(:text, :label=>'Foo', :value=>'foo', :label_attr=>{:class=>'bar'}).to_s.must_equal '<div class="form-group"><label class="bar">Foo</label> <input class="form-control" type="text" value="foo"/></div>'
  end

  it "should handle implicit labels with checkboxes" do
    @f.input(:checkbox, :label=>'Foo', :value=>'foo', :name=>'a').to_s.must_equal '<div class="checkbox"><label><input name="a" type="hidden" value="0"/><input name="a" type="checkbox" value="foo"/> Foo</label></div>'
  end

  it "should handle implicit labels with :label_position=>:after" do
    @f.input(:text, :label=>'Foo', :value=>'foo', :label_position=>:after).to_s.must_equal '<div class="form-group"><input class="form-control" type="text" value="foo"/> <label>Foo</label></div>'
  end

  it "should handle implicit labels with checkboxes with :label_position=>:before" do
    @f.input(:checkbox, :label=>'Foo', :value=>'foo', :name=>'a', :label_position=>:before).to_s.must_equal '<div class="checkbox"><label>Foo <input name="a" type="hidden" value="0"/><input name="a" type="checkbox" value="foo"/></label></div>'
  end

  it "should automatically note the input has errors if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo').to_s.must_equal '<div class="form-group has-error"><input class="form-control" type="text" value="foo"/><span class="help-block with-errors">Bad Stuff!</span></div>'
  end

  it "should add an error message after the label" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo', :label=>"Foo").to_s.must_equal '<div class="form-group has-error"><label>Foo</label> <input class="form-control" type="text" value="foo"/><span class="help-block with-errors">Bad Stuff!</span></div>'
  end

  it "should add to existing :class option if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :class=>'bar', :value=>'foo').to_s.must_equal '<div class="form-group has-error"><input class="form-control bar" type="text" value="foo"/><span class="help-block with-errors">Bad Stuff!</span></div>'
  end

  it "should respect :error_attr option for setting the attributes for the error message span" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo', :error_attr=>{:class=>'foo'}).to_s.must_equal '<div class="form-group has-error"><input class="form-control" type="text" value="foo"/><span class="foo help-block with-errors">Bad Stuff!</span></div>'
  end

  it "#open should return an opening tag" do
    @f.open(:action=>'foo', :method=>'post').to_s.must_equal '<form action="foo" method="post">'
  end
  
  it "#close should return a closing tag" do
    @f.close.to_s.must_equal '</form>'
  end

  it "#button should return a submit tag" do
    @f.button.to_s.must_equal '<input class="btn btn-default" type="submit"/>'
  end

  it "#button should return a submit tag without label" do
    @f.button(:label=>'foo').to_s.must_equal '<input class="btn btn-default" type="submit"/>'
  end

  it "#button should accept an options hash" do
    @f.button(:name=>'foo', :value=>'bar').to_s.must_equal '<input class="btn btn-default" name="foo" type="submit" value="bar"/>'
  end
  
  it "#button should handle added classes" do
    @f.button(:class=>'btn btn-primary').to_s.must_equal '<input class="btn btn-primary" type="submit"/>'
    @f.button(:class=>'btn-danger').to_s.must_equal '<input class="btn btn-danger" type="submit"/>'
    @f.button(:class=>'btn-success btn-lg').to_s.must_equal '<input class="btn btn-success btn-lg" type="submit"/>'
  end

  it "#button should accept a string to use as a value" do
    @f.button('foo').to_s.must_equal '<input class="btn btn-default" type="submit" value="foo"/>'
  end

  it "#tag should accept children as procs" do
    @f.tag(:div, {:class=>"foo"}, lambda{|t| t.form.tag(:input, :class=>t.attr[:class])}).to_s.must_equal '<div class="foo"><input class="form-control foo" type="text"/></div>'
  end

  it "#tag should accept children as methods" do
    o = Object.new
    def o.foo(t) t.form.tag(:input, :class=>t.attr[:class]) end
    @f.tag(:div, {:class=>"foo"}, o.method(:foo)).to_s.must_equal '<div class="foo"><input class="form-control foo" type="text"/></div>'
  end

  it "should have an #inputs method for multiple inputs wrapped in a fieldset" do
    @f.inputs([:textarea, :text]).to_s.must_equal '<fieldset class="inputs"><div class="form-group"><textarea class="form-control"></textarea></div><div class="form-group"><input class="form-control" type="text"/></div></fieldset>'
  end

  it "should have default #inputs method accept an :attr option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs', :attr=>{:class=>'foo', :bar=>'baz'}).to_s.must_equal '<fieldset bar="baz" class="foo inputs"><legend>Inputs</legend><div class="form-group"><textarea class="form-control"></textarea></div><div class="form-group"><input class="form-control" type="text"/></div></fieldset>'
  end

  it "should have default #inputs method accept a :legend option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs').to_s.must_equal '<fieldset class="inputs"><legend>Inputs</legend><div class="form-group"><textarea class="form-control"></textarea></div><div class="form-group"><input class="form-control" type="text"/></div></fieldset>'
  end

  it "should have default #inputs method accept a :legend_attr option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs', :legend_attr=>{:class=>'foo'}).to_s.must_equal '<fieldset class="inputs"><legend class="foo">Inputs</legend><div class="form-group"><textarea class="form-control"></textarea></div><div class="form-group"><input class="form-control" type="text"/></div></fieldset>'
  end

  it "should have an #inputs method take a block and yield to it" do
    @f.inputs{@f.input(:textarea); @f.input(:text)}.to_s.must_equal '<fieldset class="inputs"><div class="form-group"><textarea class="form-control"></textarea></div><div class="form-group"><input class="form-control" type="text"/></div></fieldset>'
  end

  it "should have an #inputs method work with both args and block" do
    @f.inputs([:textarea]){@f.input(:text)}.to_s.must_equal '<fieldset class="inputs"><div class="form-group"><textarea class="form-control"></textarea></div><div class="form-group"><input class="form-control" type="text"/></div></fieldset>'
  end

  it "should have an #inputs method support array arguments and creating inputs with the array as argument list" do
    @f.inputs([[:textarea, {:name=>'foo'}], [:text, {:id=>'bar'}]]).to_s.must_equal '<fieldset class="inputs"><div class="form-group"><textarea class="form-control" name="foo"></textarea></div><div class="form-group"><input class="form-control" id="bar" type="text"/></div></fieldset>'
  end

  it "should have #inputs accept transformer options to modify the options inside the inputs" do
    @f.inputs([:textarea, :text], :wrapper=>:div).to_s.must_equal '<fieldset class="inputs"><div><textarea class="form-control"></textarea></div><div><input class="form-control" type="text"/></div></fieldset>'
  end

  it "should have #inputs accept :nested_inputs_wrapper options to modify the :input_wrapper option inside the inputs" do
    @f.inputs(:nested_inputs_wrapper=>:div){@f.inputs([:textarea, :text])}.to_s.must_equal '<fieldset class="inputs"><div><div class="form-group"><textarea class="form-control"></textarea></div><div class="form-group"><input class="form-control" type="text"/></div></div></fieldset>'
  end
  
  
  it "should escape tag content" do
    @f.tag(:div, {}, ['<p></p>']).to_s.must_equal '<div>&lt;p&gt;&lt;/p&gt;</div>'
  end

  it "should not escape raw tag content using Forme::Raw" do
    @f.tag(:div, {}, ['<p></p>'.dup.extend(Forme::Raw)]).to_s.must_equal '<div><p></p></div>'
  end

  it "should not escape raw tag content using Forme.raw" do
    @f.tag(:div, {}, [Forme.raw('<p></p>')]).to_s.must_equal '<div><p></p></div>'
  end

  it "should not escape raw tag content using Form#raw" do
    @f.tag(:div, {}, [@f.raw('<p></p>')]).to_s.must_equal '<div><p></p></div>'
  end

  it "should escape tag content in attribute values" do
    @f.tag(:div, :foo=>'<p></p>').to_s.must_equal '<div foo="&lt;p&gt;&lt;/p&gt;"></div>'
  end

  it "should not escape raw tag content in attribute values" do
    @f.tag(:div, :foo=>Forme.raw('<p></p>')).to_s.must_equal '<div foo="<p></p>"></div>'
  end

  it "should format dates, times, and datetimes in ISO format" do
    @f.tag(:div, :foo=>Date.new(2011, 6, 5)).to_s.must_equal '<div foo="2011-06-05"></div>'
    @f.tag(:div, :foo=>DateTime.new(2011, 6, 5, 4, 3, 2)).to_s.must_equal '<div foo="2011-06-05T04:03:02.000"></div>'
    @f.tag(:div, :foo=>Time.utc(2011, 6, 5, 4, 3, 2)).to_s.must_equal '<div foo="2011-06-05T04:03:02.000"></div>'
  end

  it "should format bigdecimals in standard notation" do
    @f.tag(:div, :foo=>BigDecimal('10000.010')).to_s.must_equal '<div foo="10000.01"></div>'
  end

  it "inputs should accept a :wrapper option to use a custom wrapper" do
    @f.input(:text, :wrapper=>:li).to_s.must_equal '<li><input class="form-control" type="text"/></li>'
  end

  it "inputs should accept a :wrapper_attr option to use custom wrapper attributes" do
    @f.input(:text, :wrapper=>:li, :wrapper_attr=>{:class=>"foo"}).to_s.must_equal '<li class="foo"><input class="form-control" type="text"/></li>'
  end

  it "inputs should accept a :help option to use custom helper text" do
    @f.input(:text, :help=>"List type of foo").to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/><span class="helper">List type of foo</span></div>'
  end

  it "inputs should accept a :helper_attr option for custom helper attributes" do
    @f.input(:text, :help=>"List type of foo", :helper_attr=>{:class=>'foo'}).to_s.must_equal '<div class="form-group"><input class="form-control" type="text"/><span class="foo helper">List type of foo</span></div>'
  end

  it "inputs should have helper displayed inside wrapper, after error" do
    @f.input(:text, :help=>"List type of foo", :error=>'bad', :wrapper=>:li).to_s.must_equal '<li class="has-error"><input class="form-control" type="text"/><span class="help-block with-errors">bad</span><span class="helper">List type of foo</span></li>'
  end

  it "inputs should accept a :formatter option to use a custom formatter" do
    @f.input(:text, :formatter=>:readonly, :value=>'1', :label=>'Foo').to_s.must_equal '<div class="form-group"><label>Foo</label> <span class="readonly-text">1</span></div>'
    @f.input(:text, :formatter=>:default, :value=>'1', :label=>'Foo').to_s.must_equal  '<div class="form-group"><label>Foo</label> <input class="form-control" type="text" value="1"/></div>'
    @f.input(:text, :formatter=>:bs3_readonly, :value=>'1', :label=>'Foo').to_s.must_equal '<div class="form-group"><label>Foo</label> <input class="form-control" readonly="readonly" type="text" value="1"/></div>'
  end

  it "bs3_readonly formatter should disable checkbox, radio, select, and textarea inputs" do
    @f.input(:checkbox, :formatter=>:bs3_readonly).to_s.must_equal '<div class="checkbox"><input disabled="disabled" type="checkbox"/></div>'
    @f.input(:radio, :formatter=>:bs3_readonly).to_s.must_equal '<div class="radio"><input disabled="disabled" type="radio"/></div>'
    @f.input(:select, :formatter=>:bs3_readonly).to_s.must_equal '<div class="form-group"><select class="form-control" disabled="disabled"></select></div>'
    @f.input(:textarea, :formatter=>:bs3_readonly).to_s.must_equal '<div class="form-group"><textarea class="form-control" readonly="readonly"></textarea></div>' 
  end

  it "inputs should accept a :labeler option to use a custom labeler" do
    @f.input(:textarea, :labeler=>:explicit, :label=>'bar', :id=>:foo).to_s.must_equal '<div class="form-group"><label class="label-before" for="foo">bar</label><textarea class="form-control" id="foo"></textarea></div>'
  end

  it "inputs handle explicit labels with :label_position=>:after" do
    @f.input(:textarea, :labeler=>:explicit, :label=>'bar', :id=>:foo, :label_position=>:after).to_s.must_equal '<div class="form-group"><textarea class="form-control" id="foo"></textarea><label class="label-after" for="foo">bar</label></div>'
  end

  it "should handle explicit labels with checkboxes" do
    @f.input(:checkbox, :labeler=>:explicit, :label=>'Foo', :value=>'foo', :name=>'a', :id=>'bar').to_s.must_equal '<div class="checkbox"><input id="bar_hidden" name="a" type="hidden" value="0"/><input id="bar" name="a" type="checkbox" value="foo"/><label class="label-after" for="bar">Foo</label></div>'
  end

  it "should handle explicit labels with checkboxes with :label_position=>:before" do
    @f.input(:checkbox, :labeler=>:explicit, :label=>'Foo', :value=>'foo', :name=>'a', :id=>'bar', :label_position=>:before).to_s.must_equal '<div class="checkbox"><label class="label-before" for="bar">Foo</label><input id="bar_hidden" name="a" type="hidden" value="0"/><input id="bar" name="a" type="checkbox" value="foo"/></div>'
  end

  it "inputs handle implicit labels or checkboxes without hidden fields with :label_position=>:before" do
    @f.input(:checkbox, :label=>'Foo', :value=>'foo', :name=>'a', :id=>'bar', :label_position=>:before, :no_hidden=>true).to_s.must_equal '<div class="checkbox"><label for="bar">Foo <input id="bar" name="a" type="checkbox" value="foo"/></label></div>'
  end

  it "inputs should accept a :error_handler option to use a custom error_handler" do
    @f.input(:textarea, :error_handler=>proc{|t, i| [t, "!!! #{i.opts[:error]}"]}, :error=>'bar', :id=>:foo).to_s.must_equal '<div class="form-group"><textarea class="form-control" id="foo"></textarea>!!! bar</div>'
  end

  it "#inputs should accept a :inputs_wrapper option to use a custom inputs_wrapper" do
    @f.inputs([:textarea], :inputs_wrapper=>:ol).to_s.must_equal '<ol><div class="form-group"><textarea class="form-control"></textarea></div></ol>'
    @f.inputs([:textarea], :inputs_wrapper=>:bs3_table, :wrapper=>:trtd).to_s.must_equal '<table class="table table-bordered"><tr><td><textarea class="form-control"></textarea></td><td></td></tr></table>'
    @f.inputs([:textarea], :inputs_wrapper=>:bs3_table, :wrapper=>:trtd, :legend=>'Foo', :labels=>['bar']).to_s.must_equal '<table class="table table-bordered"><caption>Foo</caption><tr><th>bar</th></tr><tr><td><textarea class="form-control"></textarea></td><td></td></tr></table>'
  end

  it "inputs should accept a :wrapper=>nil option to not use a wrapper" do
    Forme::Form.new(:config=>:bs3,:wrapper=>:li).input(:text, :wrapper=>nil).to_s.must_equal '<input class="form-control" type="text"/>'
  end

  it "inputs should accept a :labeler=>nil option to not use a labeler" do
    @f.input(:textarea, :labeler=>nil, :label=>'bar', :id=>:foo).to_s.must_equal '<div class="form-group"><textarea class="form-control" id="foo"></textarea></div>'
  end

  it "inputs should accept a :error_handler=>nil option to not use an error_handler" do
    @f.input(:textarea, :error_handler=>nil, :error=>'bar', :id=>:foo).to_s.must_equal '<div class="form-group"><textarea class="form-control" id="foo"></textarea></div>'
  end

  it "#inputs should accept a :inputs_wrapper=>nil option to not use an inputs_wrapper" do
    @f.form{|f| f.inputs([:textarea], :inputs_wrapper=>nil)}.to_s.must_equal '<form><div class="form-group"><textarea class="form-control"></textarea></div></form>'
  end

  it "#inputs should treat a single hash argument as an options hash with no default inputs" do
    @f.inputs(:inputs_wrapper=>:ol){@f.input(:textarea)}.to_s.must_equal '<ol><div class="form-group"><textarea class="form-control"></textarea></div></ol>'
  end

  it "should support setting defaults for inputs at the form level" do
    f = Forme::Form.new(:config=>:bs3, :input_defaults=>{'text'=>{:size=>20}, 'textarea'=>{:cols=>80, :rows=>6}})
    f.input(:text, :name=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" name="foo" size="20" type="text"/></div>'
    f.input(:textarea, :name=>"foo").to_s.must_equal '<div class="form-group"><textarea class="form-control" cols="80" name="foo" rows="6"></textarea></div>'
  end

  it "should work with input_defaults with symbol keys using using inputs with symbol keys" do
    f = Forme::Form.new(:config=>:bs3, :input_defaults=>{:text=>{:size=>20}, 'text'=>{:size=>30}})
    f.input(:text, :name=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" name="foo" size="20" type="text"/></div>'
    f.input('text', :name=>"foo").to_s.must_equal '<div class="form-group"><input class="form-control" name="foo" size="30" type="text"/></div>'
  end

  it "invalid custom transformers should raise an Error" do
    proc{Forme::Form.new(:config=>:bs3, :wrapper=>Object.new).input(:text).to_s}.must_raise(Forme::Error)
    proc{@f.input(:textarea, :wrapper=>Object.new).to_s}.must_raise(Forme::Error)
    proc{@f.input(:textarea, :formatter=>nil).to_s}.must_raise(Forme::Error)
  end
end
