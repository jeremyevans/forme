require_relative 'spec_helper'

describe "Forme plain forms" do
  def sel(opts, s)
    opts.map{|o| "<option #{'selected="selected" ' if o == s}value=\"#{o}\">#{sprintf("%02i", o)}</option>"}.join
  end

  before do
    @f = Forme::Form.new
  end

  it "Forme.version should return version string" do
    Forme.version.must_match(/\A\d+\.\d+\.\d+\z/)
  end

  it "should create a simple input tags" do
    @f.input(:text).must_equal '<input type="text"/>'
    @f.input(:radio).must_equal '<input type="radio"/>'
    @f.input(:password).must_equal '<input type="password"/>'
    @f.input(:checkbox).must_equal '<input type="checkbox"/>'
    @f.input(:submit).must_equal '<input type="submit"/>'
  end

  it "should use :html option if given" do
    @f.input(:text, :html=>"<a>foo</a>").must_equal '<a>foo</a>'
  end

  it "should support a callable :html option" do
    @f.input(:text, :html=>proc{|i| "<a>#{i.type}</a>"}).must_equal '<a>text</a>'
  end

  it "should still use labeler, wrapper, error_handler, and helper if :html option is given" do
    @f.input(:text, :html=>"<a>foo</a>", :label=>'a', :error=>'b', :help=>'c', :wrapper=>:div).must_equal '<div><label>a: <a>foo</a></label><span class="error_message">b</span><span class="helper">c</span></div>'
  end

  it "should use :name option as attribute" do
    @f.input(:text, :name=>"foo").must_equal '<input name="foo" type="text"/>'
  end

  it "should use :id option as attribute" do
    @f.input(:text, :id=>"foo").must_equal '<input id="foo" type="text"/>'
  end

  it "should use :class option as attribute" do
    @f.input(:text, :class=>"foo").must_equal '<input class="foo" type="text"/>'
  end

  it "should use :value option as attribute" do
    @f.input(:text, :value=>"foo").must_equal '<input type="text" value="foo"/>'
  end

  it "should use :placeholder option as attribute" do
    @f.input(:text, :placeholder=>"foo").must_equal '<input placeholder="foo" type="text"/>'
  end

  it "should use :style option as attribute" do
    @f.input(:text, :style=>"foo").must_equal '<input style="foo" type="text"/>'
  end

  it "should use :key option as name and id attributes" do
    @f.input(:text, :key=>"foo").must_equal '<input id="foo" name="foo" type="text"/>'
  end

  it "should use :key_id option as suffix for :key option id attributes" do
    @f.input(:text, :key=>"foo", :key_id=>'bar').must_equal '<input id="foo_bar" name="foo" type="text"/>'
  end

  it "should have :key option respect :multiple option" do
    @f.input(:text, :key=>"foo", :multiple=>true).must_equal '<input id="foo" name="foo[]" type="text"/>'
  end

  it "should use :key option respect form's current namespace" do
    @f.with_opts(:namespace=>['bar']) do
      @f.input(:text, :key=>"foo").must_equal '<input id="bar_foo" name="bar[foo]" type="text"/>'
      @f.input(:text, :key=>"foo", :multiple=>true).must_equal '<input id="bar_foo" name="bar[foo][]" type="text"/>'
      @f.with_opts(:namespace=>['bar', 'baz']) do
        @f.input(:text, :key=>"foo").must_equal '<input id="bar_baz_foo" name="bar[baz][foo]" type="text"/>'
      end
    end
  end

  it "should consider form's :values hash for default values based on the :key option if :value is not present" do
    @f.opts[:values] = {'foo'=>'baz'}
    @f.input(:text, :key=>"foo").must_equal '<input id="foo" name="foo" type="text" value="baz"/>'
    @f.input(:text, :key=>"foo", :value=>'x').must_equal '<input id="foo" name="foo" type="text" value="x"/>'

    @f.input(:text, :key=>:foo).must_equal '<input id="foo" name="foo" type="text" value="baz"/>'
    @f.opts[:values] = {:foo=>'baz'}
    @f.input(:text, :key=>:foo).must_equal '<input id="foo" name="foo" type="text" value="baz"/>'
  end

  it "should consider form's :values hash for default values based on the :key option when using namespaces" do
    @f.opts[:values] = {'bar'=>{'foo'=>'baz'}}
    @f.with_opts(:namespace=>['bar']) do
      @f.input(:text, :key=>"foo").must_equal '<input id="bar_foo" name="bar[foo]" type="text" value="baz"/>'
      @f.input(:text, :key=>"foo", :value=>'x').must_equal '<input id="bar_foo" name="bar[foo]" type="text" value="x"/>'
      @f.input(:text, :key=>:foo).must_equal '<input id="bar_foo" name="bar[foo]" type="text" value="baz"/>'
    end

    @f.with_opts(:namespace=>[:bar]) do
      @f.input(:text, :key=>:foo).must_equal '<input id="bar_foo" name="bar[foo]" type="text" value="baz"/>'

      @f.opts[:values] = {:bar=>{:foo=>'baz'}}
      @f.input(:text, :key=>:foo).must_equal '<input id="bar_foo" name="bar[foo]" type="text" value="baz"/>'
      @f.opts[:values] = {:bar=>{}}
      @f.input(:text, :key=>:foo).must_equal '<input id="bar_foo" name="bar[foo]" type="text"/>'
      @f.opts[:values] = {}
      @f.input(:text, :key=>:foo).must_equal '<input id="bar_foo" name="bar[foo]" type="text"/>'

      @f.opts[:values] = {'bar'=>{'quux'=>{'foo'=>'baz'}}}
      @f.with_opts(:namespace=>['bar', 'quux']) do
        @f.input(:text, :key=>"foo").must_equal '<input id="bar_quux_foo" name="bar[quux][foo]" type="text" value="baz"/>'
      end
    end
  end

  it "should consider form's :errors hash based on the :key option" do
    @f.opts[:errors] = { 'foo' => 'must be present' }
    @f.input(:text, :key=>"foo").must_equal "<input aria-describedby=\"foo_error_message\" aria-invalid=\"true\" class=\"error\" id=\"foo\" name=\"foo\" type=\"text\"/><span class=\"error_message\" id=\"foo_error_message\">must be present</span>"
  end

  it "should consider form's :errors hash based on the :key option when using namespaces" do
    @f.opts[:errors] = { 'bar' => { 'foo' => 'must be present' } }
    @f.with_opts(:namespace=>['bar']) do
      @f.input(:text, :key=>"foo").must_equal "<input aria-describedby=\"bar_foo_error_message\" aria-invalid=\"true\" class=\"error\" id=\"bar_foo\" name=\"bar[foo]\" type=\"text\"/><span class=\"error_message\" id=\"bar_foo_error_message\">must be present</span>"
    end
  end

  it "should handle case where form has errors not for the input" do
    @f.opts[:errors] = { 'baz' => { 'foo' => 'must be present' } }
    @f.input(:text, :key=>"foo").must_equal '<input id="foo" name="foo" type="text"/>'
    @f.with_opts(:namespace=>['bar']) do
      @f.input(:text, :key=>"foo").must_equal '<input id="bar_foo" name="bar[foo]" type="text"/>'
    end
  end

  it "should support a with_obj method that changes the object and namespace for the given block" do
    @f.with_obj([:a, :c], 'bar') do
      @f.input(:first).must_equal '<input id="bar_first" name="bar[first]" type="text" value="a"/>'
      @f.with_obj([:b], 'baz') do
        @f.input(:first).must_equal '<input id="bar_baz_first" name="bar[baz][first]" type="text" value="b"/>'
      end
      @f.with_obj([:b], %w'baz quux') do
        @f.input(:first).must_equal '<input id="bar_baz_quux_first" name="bar[baz][quux][first]" type="text" value="b"/>'
      end
      @f.with_obj([:b]) do
        @f.input(:first).must_equal '<input id="bar_first" name="bar[first]" type="text" value="b"/>'
      end
      @f.input(:last).must_equal '<input id="bar_last" name="bar[last]" type="text" value="c"/>'
    end
  end

  it "should support a each_obj method that changes the object and namespace for multiple objects for the given block" do
    @f.tag(:form) do
      @f.each_obj([[:a, :c], [:b, :d]], 'bar') do
        @f.input(:first)
        @f.input(:last)
      end
    end.must_equal '<form><input id="bar_0_first" name="bar[0][first]" type="text" value="a"/><input id="bar_0_last" name="bar[0][last]" type="text" value="c"/><input id="bar_1_first" name="bar[1][first]" type="text" value="b"/><input id="bar_1_last" name="bar[1][last]" type="text" value="d"/></form>'

    @f.tag(:form) do
      @f.each_obj([[:a, :c], [:b, :d]], %w'bar baz') do
        @f.input(:first)
        @f.input(:last)
      end
    end.must_equal '<form><input id="bar_baz_0_first" name="bar[baz][0][first]" type="text" value="a"/><input id="bar_baz_0_last" name="bar[baz][0][last]" type="text" value="c"/><input id="bar_baz_1_first" name="bar[baz][1][first]" type="text" value="b"/><input id="bar_baz_1_last" name="bar[baz][1][last]" type="text" value="d"/></form>'

    @f.tag(:form) do
      @f.each_obj([[:a, :c], [:b, :d]]) do
        @f.input(:first)
        @f.input(:last)
      end
    end.must_equal '<form><input id="0_first" name="0[first]" type="text" value="a"/><input id="0_last" name="0[last]" type="text" value="c"/><input id="1_first" name="1[first]" type="text" value="b"/><input id="1_last" name="1[last]" type="text" value="d"/></form>'
  end

  it "should allow overriding form inputs on a per-block basis" do
    @f.input(:text).must_equal '<input type="text"/>'
    @f.with_opts(:wrapper=>:div){@f.input(:text)}.must_equal '<div><input type="text"/></div>'
    @f.with_opts(:wrapper=>:div){@f.input(:text).must_equal '<div><input type="text"/></div>'}
    @f.with_opts(:wrapper=>:div) do
      @f.input(:text).must_equal '<div><input type="text"/></div>'
      @f.with_opts(:wrapper=>:li){@f.input(:text).must_equal '<li><input type="text"/></li>'}
      @f.input(:text).must_equal '<div><input type="text"/></div>'
    end
    @f.input(:text).must_equal '<input type="text"/>'
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
    end.must_equal '<form><input type="text"/><div><input type="text"/></div><li><input type="text"/></li><div><input type="text"/></div><input type="text"/></form>'
  end

  it "should support :obj method to with_opts for changing the obj inside the block" do
    @f.form do
      @f.with_opts(:obj=>[:a, :c]) do
        @f.input(:first)
        @f.with_opts(:obj=>[:b]){@f.input(:first)}
        @f.input(:last)
      end
    end.must_equal '<form><input id="first" name="first" type="text" value="a"/><input id="first" name="first" type="text" value="b"/><input id="last" name="last" type="text" value="c"/></form>'
  end

  it "should allow arbitrary attributes using the :attr option" do
    @f.input(:text, :attr=>{:bar=>"foo"}).must_equal '<input bar="foo" type="text"/>'
  end

  it "should convert the :data option into attributes" do
    @f.input(:text, :data=>{:bar=>"foo"}).must_equal '<input data-bar="foo" type="text"/>'
  end

  it "should replace underscores with hyphens in symbol :data keys when :dasherize_data is set" do
    @f.input(:text, :data=>{:foo_bar=>"baz"}).must_equal '<input data-foo_bar="baz" type="text"/>'
    @f.input(:text, :data=>{"foo_bar"=>"baz"}).must_equal '<input data-foo_bar="baz" type="text"/>'

    @f.input(:text, :data=>{:foo_bar=>"baz"}, :dasherize_data => true).must_equal '<input data-foo-bar="baz" type="text"/>'
    @f.input(:text, :data=>{"foo_bar"=>"baz"}, :dasherize_data => true).must_equal '<input data-foo_bar="baz" type="text"/>'
  end

  it "should not have standard options override the :attr option" do
    @f.input(:text, :name=>:bar, :attr=>{:name=>"foo"}).must_equal '<input name="foo" type="text"/>'
  end

  it "should combine :class standard option with :attr option" do
    @f.input(:text, :class=>:bar, :attr=>{:class=>"foo"}).must_equal '<input class="foo bar" type="text"/>'
  end

  it "should not have :data options override the :attr option" do
    @f.input(:text, :data=>{:bar=>"baz"}, :attr=>{:"data-bar"=>"foo"}).must_equal '<input data-bar="foo" type="text"/>'
  end

  it "should use :size and :maxlength options as attributes for text inputs" do
    @f.input(:text, :size=>5, :maxlength=>10).must_equal '<input maxlength="10" size="5" type="text"/>'
    @f.input(:textarea, :size=>5, :maxlength=>10).must_equal '<textarea></textarea>'
  end

  it "should create hidden input with value 0 for each checkbox with a name" do
    @f.input(:checkbox, :name=>"foo").must_equal '<input name="foo" type="hidden" value="0"/><input name="foo" type="checkbox"/>'
  end

  it "should not create hidden input with value 0 for readonly or disabled checkboxes" do
    @f.input(:checkbox, :name=>"foo", :formatter=>:disabled).must_equal '<input disabled="disabled" name="foo" type="checkbox"/>'
    @f.input(:checkbox, :name=>"foo", :formatter=>:readonly).must_equal '<input disabled="disabled" name="foo" type="checkbox"/>'
  end

  it "should create hidden input with value 0 for readonly or disabled checkboxes if no_hidden is explicitly given and not true" do
    @f.input(:checkbox, :name=>"foo", :formatter=>:disabled, :no_hidden=>false).must_equal '<input name="foo" type="hidden" value="0"/><input disabled="disabled" name="foo" type="checkbox"/>'
    @f.input(:checkbox, :name=>"foo", :formatter=>:readonly, :no_hidden=>false).must_equal '<input name="foo" type="hidden" value="0"/><input disabled="disabled" name="foo" type="checkbox"/>'
  end

  it "should not create hidden input with value 0 for each checkbox with a name if :no_hidden option is used" do
    @f.input(:checkbox, :name=>"foo", :no_hidden=>true).must_equal '<input name="foo" type="checkbox"/>'
  end

  it "should create hidden input with _hidden appened to id for each checkbox with a name and id" do
    @f.input(:checkbox, :name=>"foo", :id=>"bar").must_equal '<input id="bar_hidden" name="foo" type="hidden" value="0"/><input id="bar" name="foo" type="checkbox"/>'
  end

  it "should create hidden input with value f for each checkbox with a name and value t" do
    @f.input(:checkbox, :name=>"foo", :value=>"t").must_equal '<input name="foo" type="hidden" value="f"/><input name="foo" type="checkbox" value="t"/>'
  end

  it "should use :hidden_value option for value of hidden input for checkbox" do
    @f.input(:checkbox, :name=>"foo", :hidden_value=>"no").must_equal '<input name="foo" type="hidden" value="no"/><input name="foo" type="checkbox"/>'
  end

  it "should handle :checked option" do
    @f.input(:checkbox, :checked=>true).must_equal '<input checked="checked" type="checkbox"/>'
    @f.input(:checkbox, :checked=>false).must_equal '<input type="checkbox"/>'
  end

  it "should create textarea tag" do
    @f.input(:textarea).must_equal '<textarea></textarea>'
    @f.input(:textarea, :value=>'a').must_equal '<textarea>a</textarea>'
  end

  it "should use :cols and :rows options as attributes for textarea inputs" do
    @f.input(:text, :cols=>5, :rows=>10).must_equal '<input type="text"/>'
    @f.input(:textarea, :cols=>5, :rows=>10).must_equal '<textarea cols="5" rows="10"></textarea>'
  end

  it "should create select tag" do
    @f.input(:select).must_equal '<select></select>'
  end

  it "should respect multiple and size options in select tag" do
    @f.input(:select, :multiple=>true, :size=>10).must_equal '<select multiple="multiple" size="10"></select>'
  end

  it "should create date tag" do
    @f.input(:date).must_equal '<input type="date"/>'
  end

  it "should create datetime-local tag" do
    @f.input(:datetime).must_equal '<input type="datetime-local"/>'
  end

  it "should not error for input type :input" do
    @f.input(:input).must_equal '<input type="input"/>'
  end

  it "should use multiple select boxes for dates if the :as=>:select option is given" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5)).must_equal %{<select id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>}
  end

  it "should parse :value given as non-Date when using :as=>:select option for date inputs" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>"2011-06-05").must_equal %{<select id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>}
  end

  it "should support not using :value when using :as=>:select option for date inputs" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select).must_equal %{<select id="bar" name="foo[year]">#{sel(1900..2050, nil)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, nil)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, nil)}</select>}
  end

  it "should use labels for select boxes for dates if the :as=>:select and :select_labels options are given" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :select_labels=>{:year=>'Y', :month=>'M', :day=>'D'}, :labeler=>:explicit).must_equal %{<label class="label-before" for="bar">Y</label><select id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<label class="label-before" for="bar_month">M</label><select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<label class="label-before" for="bar_day">D</label><select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>}
  end

  it "should allow ordering date select boxes via :order" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :order=>[:month, '/', :day, '/', :year]).must_equal %{<select id="bar" name="foo[month]">#{sel(1..12, 6)}</select>/<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>/<select id="bar_year" name="foo[year]">#{sel(1900..2050, 2011)}</select>}
  end

  it "should allow only using specific date select boxes via :order" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :order=>[:month, :year]).must_equal %{<select id="bar" name="foo[month]">#{sel(1..12, 6)}</select><select id="bar_year" name="foo[year]">#{sel(1900..2050, 2011)}</select>}
  end

  it "should support :select_options for dates when :as=>:select is given" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :select_options=>{:year=>1970..2020}).must_equal %{<select id="bar" name="foo[year]">#{sel(1970..2020, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>}
  end

  it "should support :select_options with both values and text for dates when :as=>:select is given" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :select_options=>{:year=>[[2011, 'A'], [2012, 'B']]}).must_equal %{<select id="bar" name="foo[year]"><option selected="selected" value="2011">A</option><option value="2012">B</option></select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>}
  end

  it "should have explicit labeler and trtd wrapper work with multiple select boxes for dates" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :wrapper=>:trtd, :labeler=>:explicit, :label=>'Baz').must_equal %{<tr><td><label class="label-before" for="bar">Baz</label></td><td><select id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select></td></tr>}
  end

  it "should use multiple select boxes for datetimes if the :as=>:select option is given" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>DateTime.new(2011, 6, 5, 4, 3, 2)).must_equal %{<select id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select> <select id="bar_hour" name="foo[hour]">#{sel(0..23, 4)}</select>:<select id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select>:<select id="bar_second" name="foo[second]">#{sel(0..59, 2)}</select>}
  end

  it "should parse :value given as non-DateTime when using :as=>:select option for datetime inputs" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>'2011-06-05 04:03:02').must_equal %{<select id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select> <select id="bar_hour" name="foo[hour]">#{sel(0..23, 4)}</select>:<select id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select>:<select id="bar_second" name="foo[second]">#{sel(0..59, 2)}</select>}
  end

  it "should support not using :value when using :as=>:select option for datetime inputs" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select).must_equal %{<select id="bar" name="foo[year]">#{sel(1900..2050, nil)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, nil)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, nil)}</select> <select id="bar_hour" name="foo[hour]">#{sel(0..23, nil)}</select>:<select id="bar_minute" name="foo[minute]">#{sel(0..59, nil)}</select>:<select id="bar_second" name="foo[second]">#{sel(0..59, nil)}</select>}
  end

  it "should allow ordering select boxes for datetimes via :order" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>DateTime.new(2011, 6, 5, 4, 3, 2), :order=>[:day, '/', :month, 'T', :hour, ':', :minute]).must_equal %{<select id="bar" name="foo[day]">#{sel(1..31, 5)}</select>/<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>T<select id="bar_hour" name="foo[hour]">#{sel(0..23, 4)}</select>:<select id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select>}
  end

  it "should support :select_options for datetimes when :as=>:select option is given" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>DateTime.new(2011, 6, 5, 10, 3, 2), :select_options=>{:year=>1970..2020, :hour=>9..17}).must_equal %{<select id="bar" name="foo[year]">#{sel(1970..2020, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select> <select id="bar_hour" name="foo[hour]">#{sel(9..17, 10)}</select>:<select id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select>:<select id="bar_second" name="foo[second]">#{sel(0..59, 2)}</select>}
  end

  it "should create select tag with options" do
    @f.input(:select, :options=>[1, 2, 3], :selected=>2).must_equal '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
    @f.input(:select, :options=>[1, 2, 3], :value=>2).must_equal '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
  end

  it "should create select tag with options and values" do
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).must_equal '<select><option value="1">a</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  it "should have select work with false values" do
    @f.input(:select, :options=>[[1, true], [2, false]], :value=>false).must_equal '<select><option value="true">1</option><option selected="selected" value="false">2</option></select>'
  end

  it "should create select tag with option groups" do
    @f.input(:select, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :selected=>2).must_equal '<select><optgroup label="d"><option value="1">a</option><option selected="selected" value="2">b</option></optgroup><optgroup label="e"><option value="3">c</option></optgroup></select>'
  end

  it "should create select tag with option groups and specified value" do
    @f.input(:select, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :value=>3).must_equal '<select><optgroup label="d"><option value="1">a</option><option value="2">b</option></optgroup><optgroup label="e"><option selected="selected" value="3">c</option></optgroup></select>'
  end

  it "should create select tag with option groups with attributes" do
    @f.input(:select, :optgroups=>[[{:label=>'d', :class=>'f'}, [[:a, 1], [:b, 2]]], [{:label=>'e', :class=>'g'}, [[:c, 3]]]], :selected=>2).must_equal '<select><optgroup class="f" label="d"><option value="1">a</option><option selected="selected" value="2">b</option></optgroup><optgroup class="g" label="e"><option value="3">c</option></optgroup></select>'
  end

  it "should create select tag with options and values with hashes" do
    @f.input(:select, :options=>[[:a, {:foo=>1}], [:b, {:bar=>4, :value=>2}], [:c, {:baz=>3}]], :selected=>2).must_equal '<select><option foo="1">a</option><option bar="4" selected="selected" value="2">b</option><option baz="3">c</option></select>'
  end

  it "should create select tag with options and values using given method" do
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).must_equal '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).must_equal '<select><option value="a">1</option><option selected="selected" value="b">2</option><option value="c">3</option></select>'
  end

  it "should use html attributes specified in options" do
    @f.input(:text, :value=>'foo', :name=>'bar').must_equal '<input name="bar" type="text" value="foo"/>'
    @f.input(:textarea, :value=>'foo', :name=>'bar').must_equal '<textarea name="bar">foo</textarea>'
    @f.input(:select, :name=>'bar', :options=>[1, 2, 3]).must_equal '<select name="bar"><option>1</option><option>2</option><option>3</option></select>'
  end

  it "should support :add_blank option for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).must_equal '<select><option value=""></option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  it "should use Forme.default_add_blank_prompt value if :add_blank option is true" do
    begin
      Forme.default_add_blank_prompt = 'foo'
      @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).must_equal '<select><option value="">foo</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
    ensure
      Forme.default_add_blank_prompt = nil
    end
  end

  it "should use :add_blank option value as prompt if it is a String" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).must_equal '<select><option value="">Prompt Here</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  it "should support :add_blank option with :blank_position :after for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :blank_position=>:after, :value=>2).must_equal '<select><option selected="selected" value="2">b</option><option value="3">c</option><option value=""></option></select>'
  end

  it "should support :add_blank option with :blank_attr option for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :blank_attr=>{:foo=>:bar}, :value=>2).must_equal '<select><option foo="bar" value=""></option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  it "should create set of radio buttons" do
    @f.input(:radioset, :options=>[1, 2, 3], :selected=>2).must_equal '<label class="option"><input type="radio" value="1"/> 1</label><label class="option"><input checked="checked" type="radio" value="2"/> 2</label><label class="option"><input type="radio" value="3"/> 3</label>'
    @f.input(:radioset, :options=>[1, 2, 3], :value=>2).must_equal '<label class="option"><input type="radio" value="1"/> 1</label><label class="option"><input checked="checked" type="radio" value="2"/> 2</label><label class="option"><input type="radio" value="3"/> 3</label>'
  end

  it "should handle nil option value" do
    @f.input(:radioset, :options=>[1, 2, nil], :selected=>2).must_equal '<label class="option"><input type="radio" value="1"/> 1</label><label class="option"><input checked="checked" type="radio" value="2"/> 2</label><input type="radio"/>'
  end

  it "should raise error for an radioset without options" do
    proc{@f.input(:radioset)}.must_raise Forme::Error
  end

  it "should have radioset work with false values" do
    @f.input(:radioset, :options=>[[1, true], [2, false]], :value=>false).must_equal '<label class="option"><input type="radio" value="true"/> 1</label><label class="option"><input checked="checked" type="radio" value="false"/> 2</label>'
  end

  it "should create set of radio buttons with options and values" do
    @f.input(:radioset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).must_equal '<label class="option"><input type="radio" value="1"/> a</label><label class="option"><input checked="checked" type="radio" value="2"/> b</label><label class="option"><input type="radio" value="3"/> c</label>'
  end

  it "should create set of radio buttons with options and values with hashes" do
    @f.input(:radioset, :options=>[[:a, {:attr=>{:foo=>1}}], [:b, {:class=>'foo', :value=>2}], [:c, {:id=>:baz}]], :selected=>2).must_equal '<label class="option"><input foo="1" type="radio" value="a"/> a</label><label class="option"><input checked="checked" class="foo" type="radio" value="2"/> b</label><label class="option"><input id="baz" type="radio" value="c"/> c</label>'
  end

  it "should create set of radio buttons with options and values using given method" do
    @f.input(:radioset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).must_equal '<label class="option"><input type="radio" value="1"/> 1</label><label class="option"><input checked="checked" type="radio" value="2"/> 2</label><label class="option"><input type="radio" value="3"/> 3</label>'
    @f.input(:radioset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).must_equal '<label class="option"><input type="radio" value="a"/> 1</label><label class="option"><input checked="checked" type="radio" value="b"/> 2</label><label class="option"><input type="radio" value="c"/> 3</label>'
  end

  it "should support :add_blank option for radioset inputs" do
    @f.input(:radioset, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).must_equal '<label class="option"><input type="radio" value=""/> </label><label class="option"><input checked="checked" type="radio" value="2"/> b</label><label class="option"><input type="radio" value="3"/> c</label>'
  end

  it "should use :add_blank option value as prompt if it is a String" do
    @f.input(:radioset, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).must_equal '<label class="option"><input type="radio" value=""/> Prompt Here</label><label class="option"><input checked="checked" type="radio" value="2"/> b</label><label class="option"><input type="radio" value="3"/> c</label>'
  end

  it "should respect the :key option for radio sets" do
    @f.input(:radioset, :options=>[1, 2, 3], :key=>:foo, :value=>2).must_equal '<label class="option"><input id="foo_1" name="foo" type="radio" value="1"/> 1</label><label class="option"><input checked="checked" id="foo_2" name="foo" type="radio" value="2"/> 2</label><label class="option"><input id="foo_3" name="foo" type="radio" value="3"/> 3</label>'
  end

  it "should create set of radio buttons with fieldsets and legends for :optgroups" do
    @f.input(:radioset, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :selected=>2).must_equal '<fieldset><legend>d</legend><label class="option"><input type="radio" value="1"/> a</label><label class="option"><input checked="checked" type="radio" value="2"/> b</label></fieldset><fieldset><legend>e</legend><label class="option"><input type="radio" value="3"/> c</label></fieldset>'
  end

  it "should create set of radio buttons with label attributes" do
    @f.input(:radioset, :options=>[1, 2, 3], :selected=>2, :label_attr=>{:foo=>:bar}).must_equal '<label class="option" foo="bar"><input type="radio" value="1"/> 1</label><label class="option" foo="bar"><input checked="checked" type="radio" value="2"/> 2</label><label class="option" foo="bar"><input type="radio" value="3"/> 3</label>'
  end

  it "should create set of radio buttons with :error and :error_attr options" do
    @f.input(:radioset, :options=>[1, 2, 3], :selected=>2, :error=>'foo', :error_attr=>{'bar'=>'baz'}).must_equal '<label class="option"><input type="radio" value="1"/> 1</label><label class="option"><input checked="checked" type="radio" value="2"/> 2</label><label class="option"><input aria-invalid="true" class="error" type="radio" value="3"/> 3</label><span bar="baz" class="error_message">foo</span>'
  end

  it "should support custom error_handler for set of radio buttons" do
    @f.input(:radioset, :options=>[1, 2, 3], :selected=>2, :error=>'foo', :error_attr=>{'bar'=>'baz'}, :error_handler=>lambda{|tag, input| input.tag(:div, {}, tag)}).must_equal '<div><label class="option"><input type="radio" value="1"/> 1</label><label class="option"><input checked="checked" type="radio" value="2"/> 2</label><label class="option"><input type="radio" value="3"/> 3</label></div>'
  end

  it "should create set of checkbox buttons" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :selected=>2).must_equal '<label class="option"><input type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option"><input type="checkbox" value="3"/> 3</label>'
    @f.input(:checkboxset, :options=>[1, 2, 3], :value=>2).must_equal '<label class="option"><input type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option"><input type="checkbox" value="3"/> 3</label>'
  end

  it "should support :multiple option for checkboxset buttons" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :selected=>[1,2], :multiple=>false).must_equal '<label class="option"><input type="checkbox" value="1"/> 1</label><label class="option"><input type="checkbox" value="2"/> 2</label><label class="option"><input type="checkbox" value="3"/> 3</label>'
    @f.input(:checkboxset, :options=>[1, 2, 3], :selected=>[1,2], :multiple=>true).must_equal '<label class="option"><input checked="checked" type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option"><input type="checkbox" value="3"/> 3</label>'
  end

  it "should create set of checkbox buttons with options and values" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).must_equal '<label class="option"><input type="checkbox" value="1"/> a</label><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label><label class="option"><input type="checkbox" value="3"/> c</label>'
  end

  it "should have radioset work with false values" do
    @f.input(:checkboxset, :options=>[[1, true], [2, false]], :value=>false).must_equal '<label class="option"><input type="checkbox" value="true"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="false"/> 2</label>'
  end

  it "should support :wrapper and :tag_wrapper for checkboxsets" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :tag_wrapper=>:div, :wrapper=>:li).must_equal '<li><div><label class="option"><input type="checkbox" value="1"/> a</label></div><div><label class="option"><input type="checkbox" value="2"/> b</label></div><div><label class="option"><input type="checkbox" value="3"/> c</label></div></li>'
  end

  it "should support :label for checkboxsets" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :label=>'foo').must_equal '<span class="label">foo</span><label class="option"><input type="checkbox" value="1"/> a</label><label class="option"><input type="checkbox" value="2"/> b</label><label class="option"><input type="checkbox" value="3"/> c</label>'
  end

  it "should support fieldset/legend for checkboxsets" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :label=>'foo', :labeler=>:legend, :wrapper=>:fieldset).must_equal '<fieldset><legend>foo</legend><label class="option"><input type="checkbox" value="1"/> a</label><label class="option"><input type="checkbox" value="2"/> b</label><label class="option"><input type="checkbox" value="3"/> c</label></fieldset>'
  end

  it "should support legend with attributes for checkboxsets" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :label=>'foo', :label_attr=>{:class=>"baz"}, :tag_label_attr=>{:class=>"bar"}, :labeler=>:legend, :wrapper=>:fieldset).must_equal '<fieldset><legend class="baz">foo</legend><label class="bar"><input type="checkbox" value="1"/> a</label><label class="bar"><input type="checkbox" value="2"/> b</label><label class="bar"><input type="checkbox" value="3"/> c</label></fieldset>'
  end

  it "should support legend with attributes for checkboxsets, handling errors with :error_handler=>:after_legend" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :id=>:quux, :label=>'foo', :label_attr=>{:class=>"baz"}, :tag_label_attr=>{:class=>"bar"}, :labeler=>:legend, :wrapper=>:fieldset, :error=>'bar2', :error_handler=>:after_legend).must_equal '<fieldset><legend class="baz">foo</legend><span class="error_message" id="quux_1_error_message">bar2</span><label class="bar"><input aria-describedby="quux_1_error_message" aria-invalid="true" class="error" id="quux_1" type="checkbox" value="1"/> a</label><label class="bar"><input id="quux_2" type="checkbox" value="2"/> b</label><label class="bar"><input id="quux_3" type="checkbox" value="3"/> c</label></fieldset>'
  end

  it "should have :error_handler=>:after_legend funfction like regular error handler if first tag is not a legend" do
    @f.input(:text, :error_handler=>:after_legend, :error=>'a', :id=>'b').must_equal '<input aria-describedby="b_error_message" aria-invalid="true" class="error" id="b" type="text"/><span class="error_message" id="b_error_message">a</span>'
  end

  it "should support :tag_labeler for checkboxsets" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :tag_labeler=>:explicit).must_equal '<input type="checkbox" value="1"/><label class="option label-after">a</label><input type="checkbox" value="2"/><label class="option label-after">b</label><input type="checkbox" value="3"/><label class="option label-after">c</label>'
  end

  it "should support custom :labeler for checkboxsets" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :label=>'foo', :labeler=>lambda{|tag, input| input.tag(:div, {}, tag)}).must_equal '<div><label class="option"><input type="checkbox" value="1"/> a</label><label class="option"><input type="checkbox" value="2"/> b</label><label class="option"><input type="checkbox" value="3"/> c</label></div>'
  end

  it "should create set of checkbox buttons with options and values with hashes" do
    @f.input(:checkboxset, :options=>[[:a, {:attr=>{:foo=>1}}], [:b, {:class=>'foo', :value=>2}], [:c, {:id=>:baz}]], :selected=>2).must_equal '<label class="option"><input foo="1" type="checkbox" value="a"/> a</label><label class="option"><input checked="checked" class="foo" type="checkbox" value="2"/> b</label><label class="option"><input id="baz" type="checkbox" value="c"/> c</label>'
  end

  it "should create set of checkbox buttons with options and values using given method" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).must_equal '<label class="option"><input type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option"><input type="checkbox" value="3"/> 3</label>'
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).must_equal '<label class="option"><input type="checkbox" value="a"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="b"/> 2</label><label class="option"><input type="checkbox" value="c"/> 3</label>'
  end

  it "should support :add_blank option for checkboxset inputs" do
    @f.input(:checkboxset, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).must_equal '<label class="option"><input type="checkbox" value=""/> </label><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label><label class="option"><input type="checkbox" value="3"/> c</label>'
  end

  it "should use :add_blank option value as prompt if it is a String" do
    @f.input(:checkboxset, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).must_equal '<label class="option"><input type="checkbox" value=""/> Prompt Here</label><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label><label class="option"><input type="checkbox" value="3"/> c</label>'
  end

  it "should respect the :key option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :key=>:foo, :value=>2).must_equal '<label class="option"><input id="foo_1" name="foo[]" type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" id="foo_2" name="foo[]" type="checkbox" value="2"/> 2</label><label class="option"><input id="foo_3" name="foo[]" type="checkbox" value="3"/> 3</label>'
  end

  it "should prefer the :name option to :key option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :key=>:foo, :name=>'bar[]', :value=>2).must_equal '<label class="option"><input id="foo_1" name="bar[]" type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" id="foo_2" name="bar[]" type="checkbox" value="2"/> 2</label><label class="option"><input id="foo_3" name="bar[]" type="checkbox" value="3"/> 3</label>'
  end

  it "should prefer the :name and :id option to :key option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :key=>:foo, :name=>'bar[]', :id=>:baz, :value=>2).must_equal '<label class="option"><input id="baz_1" name="bar[]" type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" id="baz_2" name="bar[]" type="checkbox" value="2"/> 2</label><label class="option"><input id="baz_3" name="bar[]" type="checkbox" value="3"/> 3</label>'
  end

  it "should respect the :error option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :error=>'foo', :value=>2).must_equal '<label class="option"><input type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option"><input aria-invalid="true" class="error" type="checkbox" value="3"/> 3</label><span class="error_message">foo</span>'
  end

  it "should create set of checkbox buttons with fieldsets and legends for optgroups" do
    @f.input(:checkboxset, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :selected=>2).must_equal '<fieldset><legend>d</legend><label class="option"><input type="checkbox" value="1"/> a</label><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label></fieldset><fieldset><legend>e</legend><label class="option"><input type="checkbox" value="3"/> c</label></fieldset>'
  end

  it "should create set of checkbox buttons with label attributes" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :selected=>2, :label_attr=>{:foo=>:bar}).must_equal '<label class="option" foo="bar"><input type="checkbox" value="1"/> 1</label><label class="option" foo="bar"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option" foo="bar"><input type="checkbox" value="3"/> 3</label>'
  end

  it "should raise an Error for empty checkbox sets" do
    @f.input(:checkboxset, :options=>[], :error=>'foo', :value=>2).must_equal '<span class="error_message">foo</span>'
  end

  it "radio and checkbox inputs should handle :checked option" do
    @f.input(:radio, :checked=>true).must_equal '<input checked="checked" type="radio"/>'
    @f.input(:radio, :checked=>false).must_equal '<input type="radio"/>'
    @f.input(:checkbox, :checked=>true).must_equal '<input checked="checked" type="checkbox"/>'
    @f.input(:checkbox, :checked=>false).must_equal '<input type="checkbox"/>'
  end

  it "inputs should handle :autofocus option" do
    @f.input(:text, :autofocus=>true).must_equal '<input autofocus="autofocus" type="text"/>'
    @f.input(:text, :autofocus=>false).must_equal '<input type="text"/>'
  end

  it "inputs should handle :required option" do
    @f.input(:text, :required=>true).must_equal '<input required="required" type="text"/>'
    @f.input(:text, :required=>false).must_equal '<input type="text"/>'
  end

  it "inputs should handle :disabled option" do
    @f.input(:text, :disabled=>true).must_equal '<input disabled="disabled" type="text"/>'
    @f.input(:text, :disabled=>false).must_equal '<input type="text"/>'
  end

  it "inputs should not include options with nil values" do
    @f.input(:text, :name=>nil).must_equal '<input type="text"/>'
    @f.input(:textarea, :name=>nil).must_equal '<textarea></textarea>'
  end

  it "inputs should include options with false values" do
    @f.input(:text, :name=>false).must_equal '<input name="false" type="text"/>'
  end

  it "should automatically create a label if a :label option is used" do
    @f.input(:text, :label=>'Foo', :value=>'foo').must_equal '<label>Foo: <input type="text" value="foo"/></label>'
  end

  it "should set label attributes with :label_attr option" do
    @f.input(:text, :label=>'Foo', :value=>'foo', :label_attr=>{:class=>'bar'}).must_equal '<label class="bar">Foo: <input type="text" value="foo"/></label>'
  end

  it "should handle implicit labels with checkboxes" do
    @f.input(:checkbox, :label=>'Foo', :value=>'foo', :name=>'a').must_equal '<input name="a" type="hidden" value="0"/><label><input name="a" type="checkbox" value="foo"/> Foo</label>'
  end

  it "should handle implicit labels with :label_position=>:after" do
    @f.input(:text, :label=>'Foo', :value=>'foo', :label_position=>:after).must_equal '<label><input type="text" value="foo"/> Foo</label>'
  end

  it "should handle implicit labels with checkboxes with :label_position=>:before" do
    @f.input(:checkbox, :label=>'Foo', :value=>'foo', :name=>'a', :label_position=>:before).must_equal '<input name="a" type="hidden" value="0"/><label>Foo <input name="a" type="checkbox" value="foo"/></label>'
  end

  it "should automatically note the input has errors if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo').must_equal '<input aria-invalid="true" class="error" type="text" value="foo"/><span class="error_message">Bad Stuff!</span>'
  end

  it "should add an error message after the label" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo', :label=>"Foo").must_equal '<label>Foo: <input aria-invalid="true" class="error" type="text" value="foo"/></label><span class="error_message">Bad Stuff!</span>'
  end

  it "should add to existing :class option if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :class=>'bar', :value=>'foo').must_equal '<input aria-invalid="true" class="bar error" type="text" value="foo"/><span class="error_message">Bad Stuff!</span>'
  end

  it "should respect :error_attr option for setting the attributes for the error message span" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo', :error_attr=>{:class=>'foo'}).must_equal '<input aria-invalid="true" class="error" type="text" value="foo"/><span class="foo error_message">Bad Stuff!</span>'
  end

  it "should use aria-describedby and aria-invalid tags for errors with where the id attribute can be determined" do
    @f.input(:text, :error=>'Bad Stuff!', :id=>:bar, :value=>'foo', :error_attr=>{:class=>'foo'}).must_equal '<input aria-describedby="bar_error_message" aria-invalid="true" class="error" id="bar" type="text" value="foo"/><span class="foo error_message" id="bar_error_message">Bad Stuff!</span>'
  end

  it "should support :error_id option for errors to specify id of error" do
    @f.input(:text, :error=>'Bad Stuff!', :error_id=>:baz, :id=>:bar, :value=>'foo', :error_attr=>{:class=>'foo'}).must_equal '<input aria-describedby="baz" aria-invalid="true" class="error" id="bar" type="text" value="foo"/><span class="foo error_message" id="baz">Bad Stuff!</span>'
  end

  it "should have :error_attr :id take precedence over :error_id option" do
    @f.input(:text, :error=>'Bad Stuff!', :error_id=>:baz, :id=>:bar, :value=>'foo', :error_attr=>{:class=>'foo', :id=>'q'}).must_equal '<input aria-describedby="baz" aria-invalid="true" class="error" id="bar" type="text" value="foo"/><span class="foo error_message" id="q">Bad Stuff!</span>'
  end

  it "#open should return an opening tag" do
    @f.open(:action=>'foo', :method=>'post').must_equal '<form action="foo" method="post">'
  end

  it "#close should return a closing tag" do
    @f.close.must_equal '</form>'
  end

  it "#button should return a submit tag" do
    @f.button.must_equal '<input type="submit"/>'
  end

  it "#button should accept an options hash" do
    @f.button(:name=>'foo', :value=>'bar').must_equal '<input name="foo" type="submit" value="bar"/>'
  end

  it "#button should accept a string to use as a value" do
    @f.button('foo').must_equal '<input type="submit" value="foo"/>'
  end

  it "#tag should return a serialized_tag" do
    @f.tag(:textarea).must_equal '<textarea></textarea>'
    @f.tag(:textarea, :name=>:foo).must_equal '<textarea name="foo"></textarea>'
    @f.tag(:textarea, {:name=>:foo}, :bar).must_equal '<textarea name="foo">bar</textarea>'
  end

  it "#tag should accept a block" do
    @f.tag(:div){@f.tag(:textarea)}.must_equal '<div><textarea></textarea></div>'
    @f.tag(:div, :name=>'a'){@f.tag(:textarea)}.must_equal '<div name="a"><textarea></textarea></div>'
    @f.tag(:div, {:name=>'a'}, ["text"]){@f.tag(:textarea)}.must_equal '<div name="a">text<textarea></textarea></div>'
  end

  it "#tag should accept children as procs" do
    @f.tag(:div, {:class=>"foo"}, lambda{|t| t.tag(:input, :class=>t.attr[:class])}).must_equal '<div class="foo"><input class="foo"/></div>'
  end

  it "#tag should accept children as methods" do
    o = Object.new
    def o.foo(t) t.tag(:input, :class=>t.attr[:class]) end
    @f.tag(:div, {:class=>"foo"}, o.method(:foo)).must_equal '<div class="foo"><input class="foo"/></div>'
  end

  it "should have an #inputs method for multiple inputs wrapped in a fieldset" do
    @f.inputs([:textarea, :text]).must_equal '<fieldset class="inputs"><textarea></textarea><input type="text"/></fieldset>'
  end

  it "should have an #inputs method for multiple inputs wrapped in a fieldset when using an empty block" do
    @f.inputs([:textarea, :text]){}.must_equal '<fieldset class="inputs"><textarea></textarea><input type="text"/></fieldset>'
  end

  it "should have default #inputs method accept an :attr option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs', :attr=>{:class=>'foo', :bar=>'baz'}).must_equal '<fieldset bar="baz" class="foo inputs"><legend>Inputs</legend><textarea></textarea><input type="text"/></fieldset>'
  end

  it "should have default #inputs method accept a :legend option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs').must_equal '<fieldset class="inputs"><legend>Inputs</legend><textarea></textarea><input type="text"/></fieldset>'
  end

  it "should have default #inputs method accept a :legend_attr option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs', :legend_attr=>{:class=>'foo'}).must_equal '<fieldset class="inputs"><legend class="foo">Inputs</legend><textarea></textarea><input type="text"/></fieldset>'
  end

  it "should have an #inputs method take a block and yield to it" do
    @f.inputs{@f.input(:textarea); @f.input(:text)}.must_equal '<fieldset class="inputs"><textarea></textarea><input type="text"/></fieldset>'
  end

  it "should have an #inputs method work with both args and block" do
    @f.inputs([:textarea]){@f.input(:text)}.must_equal '<fieldset class="inputs"><textarea></textarea><input type="text"/></fieldset>'
  end

  it "should have an #inputs method support array arguments and creating inputs with the array as argument list" do
    @f.inputs([[:textarea, {:name=>'foo'}], [:text, {:id=>'bar'}]]).must_equal '<fieldset class="inputs"><textarea name="foo"></textarea><input id="bar" type="text"/></fieldset>'
  end

  it "should have #inputs accept transformer options to modify the options inside the inputs" do
    @f.inputs([:textarea, :text], :wrapper=>:div).must_equal '<fieldset class="inputs"><div><textarea></textarea></div><div><input type="text"/></div></fieldset>'
  end

  it "should have #inputs accept :nested_inputs_wrapper options to modify the :input_wrapper option inside the inputs" do
    @f.inputs(:nested_inputs_wrapper=>:div){@f.inputs([:textarea, :text])}.must_equal '<fieldset class="inputs"><div><textarea></textarea><input type="text"/></div></fieldset>'
  end

  it "should escape tag content" do
    @f.tag(:div, {}, ['<p></p>']).must_equal '<div>&lt;p&gt;&lt;/p&gt;</div>'
  end

  it "should not escape raw tag content using Forme::Raw" do
    @f.tag(:div, {}, ['<p></p>'.dup.extend(Forme::Raw)]).must_equal '<div><p></p></div>'
  end

  it "should not escape raw tag content using Forme.raw" do
    @f.tag(:div, {}, [Forme.raw('<p></p>')]).must_equal '<div><p></p></div>'
  end

  it "should not escape raw tag content using Form#raw" do
    @f.tag(:div, {}, [@f.raw('<p></p>')]).must_equal '<div><p></p></div>'
  end

  it "should escape tag content in attribute values" do
    @f.tag(:div, :foo=>'<p></p>').must_equal '<div foo="&lt;p&gt;&lt;/p&gt;"></div>'
  end

  it "should not escape raw tag content in attribute values" do
    @f.tag(:div, :foo=>Forme.raw('<p></p>')).must_equal '<div foo="<p></p>"></div>'
  end

  it "should format dates, times, and datetimes in ISO format" do
    @f.tag(:div, :foo=>Date.new(2011, 6, 5)).must_equal '<div foo="2011-06-05"></div>'
    @f.tag(:div, :foo=>DateTime.new(2011, 6, 5, 4, 3, 2)).must_equal '<div foo="2011-06-05T04:03:02.000"></div>'
    @f.tag(:div, :foo=>Time.utc(2011, 6, 5, 4, 3, 2)).must_equal '<div foo="2011-06-05T04:03:02.000"></div>'
  end

  it "should format bigdecimals in standard notation" do
    @f.tag(:div, :foo=>BigDecimal('10000.010')).must_equal '<div foo="10000.01"></div>'
  end

  it "inputs should accept a :wrapper option to use a custom wrapper" do
    @f.input(:text, :wrapper=>:li).must_equal '<li><input type="text"/></li>'
  end

  it "inputs should accept a :wrapper_attr option to use custom wrapper attributes" do
    @f.input(:text, :wrapper=>:li, :wrapper_attr=>{:class=>"foo"}).must_equal '<li class="foo"><input type="text"/></li>'
  end

  it "inputs should accept a :help option to use custom helper text" do
    @f.input(:text, :help=>"List type of foo").must_equal '<input type="text"/><span class="helper">List type of foo</span>'
  end

  it "inputs should accept a :helper_attr option for custom helper attributes" do
    @f.input(:text, :help=>"List type of foo", :helper_attr=>{:class=>'foo'}).must_equal '<input type="text"/><span class="foo helper">List type of foo</span>'
  end

  it "inputs should have helper displayed inside wrapper, after error" do
    @f.input(:text, :help=>"List type of foo", :error=>'bad', :wrapper=>:li).must_equal '<li><input aria-invalid="true" class="error" type="text"/><span class="error_message">bad</span><span class="helper">List type of foo</span></li>'
  end

  it "inputs should accept a :formatter option to use a custom formatter" do
    @f.input(:text, :formatter=>:readonly, :value=>'1', :label=>'Foo').must_equal '<label>Foo: <span class="readonly-text">1</span></label>'
    @f.input(:text, :formatter=>:default, :value=>'1', :label=>'Foo').must_equal '<label>Foo: <input type="text" value="1"/></label>'
  end

  it "inputs should accept a :labeler option to use a custom labeler" do
    @f.input(:textarea, :labeler=>:explicit, :label=>'bar', :id=>:foo).must_equal '<label class="label-before" for="foo">bar</label><textarea id="foo"></textarea>'
  end

  it "inputs handle explicit labels with :label_position=>:after" do
    @f.input(:textarea, :labeler=>:explicit, :label=>'bar', :id=>:foo, :label_position=>:after).must_equal '<textarea id="foo"></textarea><label class="label-after" for="foo">bar</label>'
  end

  it "inputs handle explicit labels with :key_id" do
    @f.input(:textarea, :labeler=>:explicit, :label=>'bar', :key=>:bar, :key_id=>:foo).must_equal '<label class="label-before" for="bar_foo">bar</label><textarea id="bar_foo" name="bar"></textarea>'
  end

  it "should handle explicit labels with checkboxes" do
    @f.input(:checkbox, :labeler=>:explicit, :label=>'Foo', :value=>'foo', :name=>'a', :id=>'bar').must_equal '<input id="bar_hidden" name="a" type="hidden" value="0"/><input id="bar" name="a" type="checkbox" value="foo"/><label class="label-after" for="bar">Foo</label>'
  end

  it "should handle explicit labels with checkboxes with :label_position=>:before" do
    @f.input(:checkbox, :labeler=>:explicit, :label=>'Foo', :value=>'foo', :name=>'a', :id=>'bar', :label_position=>:before).must_equal '<label class="label-before" for="bar">Foo</label><input id="bar_hidden" name="a" type="hidden" value="0"/><input id="bar" name="a" type="checkbox" value="foo"/>'
  end

  it "inputs handle implicit labels or checkboxes without hidden fields with :label_position=>:before" do
    @f.input(:checkbox, :label=>'Foo', :value=>'foo', :name=>'a', :id=>'bar', :label_position=>:before, :no_hidden=>true).must_equal '<label>Foo <input id="bar" name="a" type="checkbox" value="foo"/></label>'
  end

  it "inputs should accept a :error_handler option to use a custom error_handler" do
    @f.input(:textarea, :error_handler=>proc{|t, i| [t, "!!! #{i.opts[:error]}"]}, :error=>'bar', :id=>:foo).must_equal '<textarea aria-describedby="foo_error_message" aria-invalid="true" class="error" id="foo"></textarea>!!! bar'
  end

  it "#inputs should accept a :inputs_wrapper option to use a custom inputs_wrapper" do
    @f.inputs([:textarea], :inputs_wrapper=>:ol).must_equal '<ol><textarea></textarea></ol>'
  end

  it "inputs should accept a :wrapper=>nil option to not use a wrapper" do
    Forme::Form.new(:wrapper=>:li).input(:text, :wrapper=>nil).must_equal '<input type="text"/>'
  end

  it "inputs should accept a :labeler=>nil option to not use a labeler" do
    @f.input(:textarea, :labeler=>nil, :label=>'bar', :id=>:foo).must_equal '<textarea id="foo"></textarea>'
  end

  it "inputs should accept a :error_handler=>nil option to not use an error_handler" do
    @f.input(:textarea, :error_handler=>nil, :error=>'bar', :id=>:foo).must_equal '<textarea aria-invalid="true" class="error" id="foo"></textarea>'
  end

  it "#inputs should accept a :inputs_wrapper=>nil option to not use an inputs_wrapper" do
    @f.form{|f| f.inputs([:textarea], :inputs_wrapper=>nil)}.must_equal '<form><textarea></textarea></form>'
  end

  it "#inputs should treat a single hash argument as an options hash with no default inputs" do
    @f.inputs(:inputs_wrapper=>:ol){@f.input(:textarea)}.must_equal '<ol><textarea></textarea></ol>'
  end

  it "should support setting defaults for inputs at the form level" do
    f = Forme::Form.new(:input_defaults=>{'text'=>{:size=>20}, 'textarea'=>{:cols=>80, :rows=>6}})
    f.input(:text, :name=>"foo").must_equal '<input name="foo" size="20" type="text"/>'
    f.input(:textarea, :name=>"foo").must_equal '<textarea cols="80" name="foo" rows="6"></textarea>'
  end

  it "should work with input_defaults with symbol keys using using inputs with symbol keys" do
    f = Forme::Form.new(:input_defaults=>{:text=>{:size=>20}, 'text'=>{:size=>30}})
    f.input(:text, :name=>"foo").must_equal '<input name="foo" size="20" type="text"/>'
    f.input('text', :name=>"foo").must_equal '<input name="foo" size="30" type="text"/>'
  end

  it "invalid custom transformers should raise an Error" do
    proc{Forme::Form.new(:wrapper=>Object.new).input(:text)}.must_raise(Forme::Error)
    proc{@f.input(:textarea, :wrapper=>Object.new)}.must_raise(Forme::Error)
    proc{@f.input(:textarea, :formatter=>nil)}.must_raise(Forme::Error)
  end

  it "should handle :before and :after hook options" do
    Forme.form({}, :before=>lambda{|f| f.tag(:input, :type=>:hidden, :name=>:a, :value=>'b')}, :after=>lambda{|f| f.tag(:input, :type=>:hidden, :name=>:c, :value=>'d')}){|f| f.tag(:input)}.must_equal '<form><input name="a" type="hidden" value="b"/><input/><input name="c" type="hidden" value="d"/></form>'
  end
end

describe "Forme custom" do
  it "formatters can be specified as a proc" do
    Forme::Form.new(:formatter=>proc{|i| i.tag(:textarea, i.opts[:name]=>:name)}).input(:text, :name=>'foo').must_equal '<textarea foo="name"></textarea>'
  end

  it "serializers can be specified as a proc" do
    Forme::Form.new(:serializer=>proc{|t| "#{t.type} = #{t.opts[:name]}"}).input(:textarea, :name=>'foo').must_equal 'textarea = foo'
  end

  it "labelers can be specified as a proc" do
    Forme::Form.new(:labeler=>proc{|t, i| ["#{i.opts[:label]}: ", t]}).input(:textarea, :name=>'foo', :label=>'bar').must_equal 'bar: <textarea name="foo"></textarea>'
  end

  it "error_handlers can be specified as a proc" do
    Forme::Form.new(:error_handler=>proc{|t, i| [t, "!!! #{i.opts[:error]}"]}).input(:textarea, :name=>'foo', :error=>'bar').must_equal '<textarea aria-invalid="true" class="error" name="foo"></textarea>!!! bar'
  end

  it "wrappers can be specified as a proc" do
    Forme::Form.new(:wrapper=>proc{|t, i| t.tag(:div, {:bar=>i.opts[:name]}, t)}).input(:textarea, :name=>'foo').must_equal '<div bar="foo"><textarea name="foo"></textarea></div>'
  end

  it "inputs_wrappers can be specified as a proc" do
    Forme::Form.new(:inputs_wrapper=>proc{|f, opts, &block| f.tag(:div, &block)}).inputs([:textarea]).must_equal '<div><textarea></textarea></div>'
  end

  it "can use nil as value to disable default transformer" do
    Forme::Form.new(:labeler=>nil).input(:textarea, :label=>'foo').must_equal '<textarea></textarea>'
  end
end

describe "Forme built-in custom" do
  it "transformers should raise if the there is no matching transformer" do
    proc{Forme::Form.new(:formatter=>:foo).input(:text)}.must_raise(Forme::Error)
  end

  it "formatter: disabled disables all inputs unless :disabled=>false option" do
    Forme::Form.new(:formatter=>:disabled).input(:textarea).must_equal '<textarea disabled="disabled"></textarea>'
    Forme::Form.new(:formatter=>:disabled).input(:textarea, :disabled=>false).must_equal '<textarea></textarea>'
  end

  it "formatter: readonly uses spans for text input fields and disables radio/checkbox fields" do
    Forme::Form.new(:formatter=>:readonly).input(:text, :label=>"Foo", :value=>"Bar").must_equal "<label>Foo: <span class=\"readonly-text\">Bar</span></label>"
    Forme::Form.new(:formatter=>:readonly).input(:radio, :label=>"Foo", :value=>"Bar").must_equal "<label><input disabled=\"disabled\" type=\"radio\" value=\"Bar\"/> Foo</label>"
    Forme::Form.new(:formatter=>:readonly).input(:radio, :label=>"Foo", :value=>"Bar", :checked=>true).must_equal "<label><input checked=\"checked\" disabled=\"disabled\" type=\"radio\" value=\"Bar\"/> Foo</label>"
    Forme::Form.new(:formatter=>:readonly).input(:checkbox, :label=>"Foo", :value=>"Bar").must_equal "<label><input disabled=\"disabled\" type=\"checkbox\" value=\"Bar\"/> Foo</label>"
    Forme::Form.new(:formatter=>:readonly).input(:checkbox, :label=>"Foo", :value=>"Bar", :checked=>true).must_equal "<label><input checked=\"checked\" disabled=\"disabled\" type=\"checkbox\" value=\"Bar\"/> Foo</label>"
    Forme::Form.new(:formatter=>:readonly).input(:select, :label=>"Foo", :options=>[1, 2, 3], :value=>2).must_equal "<label>Foo: <span>2</span></label>"
    Forme::Form.new(:formatter=>:readonly).input(:select, :label=>"Foo").must_equal "<label>Foo: <span></span></label>"
  end

  it "formatter: readonly removes hidden inputs" do
    Forme::Form.new(:formatter=>:readonly).input(:hidden, :value=>"Bar").must_equal ""
  end

  it "formatter: readonly formats text into paragraphs for textarea inputs" do
    Forme::Form.new(:formatter=>:readonly).input(:textarea, :label=>"Foo", :value=>"\n Bar\nBaz\n\nQuuz\n\n1\n2 \n").must_equal "<label>Foo: <div class=\"readonly-textarea\"><p> Bar<br />Baz</p><p>Quuz</p><p>1<br />2 </p></div></label>"
  end

  it "formatter: readonly does not format nil, raw string, or non-string inputs" do
    Forme::Form.new(:formatter=>:readonly).input(:textarea, :label=>"Foo").must_equal "<label>Foo: <div class=\"readonly-textarea\"></div></label>"
    Forme::Form.new(:formatter=>:readonly).input(:textarea, :label=>"Foo", :value=>Forme.raw("Bar\n\nBaz")).must_equal "<label>Foo: <div class=\"readonly-textarea\">Bar\n\nBaz</div></label>"
    Forme::Form.new(:formatter=>:readonly).input(:textarea, :label=>"Foo", :value=>1).must_equal "<label>Foo: <div class=\"readonly-textarea\">1</div></label>"
  end

  it "formatter: readonly should ignore submit buttons" do
    Forme.form({}, :formatter=>:readonly, :button=>'a').must_equal '<form></form>'
  end

  it "labeler: explicit uses an explicit label with for attribute" do
    Forme::Form.new(:labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'bar').must_equal '<label class="label-before" for="foo">bar</label><textarea id="foo"></textarea>'
  end

  it "labeler: explicit handles the key option correctly" do
    Forme::Form.new(:labeler=>:explicit, :namespace=>:baz).input(:textarea, :key=>'foo', :label=>'bar').must_equal '<label class="label-before" for="baz_foo">bar</label><textarea id="baz_foo" name="baz[foo]"></textarea>'
  end

  it "labeler: explicit should handle tags with errors" do
    Forme::Form.new(:labeler=>:explicit).input(:text, :error=>'Bad Stuff!', :value=>'f', :id=>'foo', :label=>'bar').must_equal '<label class="label-before" for="foo">bar</label><input aria-describedby="foo_error_message" aria-invalid="true" class="error" id="foo" type="text" value="f"/><span class="error_message" id="foo_error_message">Bad Stuff!</span>'
  end

  it "labeler: span should add a span with label class before the tag" do
    Forme::Form.new(:labeler=>:span).input(:text, :label=>'A').must_equal '<span class="label">A</span><input type="text"/>'
  end

  it "labeler: span should support :label_attr" do
    Forme::Form.new(:labeler=>:span).input(:text, :label=>'A', :label_attr=>{:foo=>'bar', :class=>"baz"}).must_equal '<span class="baz label" foo="bar">A</span><input type="text"/>'
  end

  it "wrapper: li wraps tag in an li" do
    Forme::Form.new(:wrapper=>:li).input(:textarea, :id=>'foo').must_equal '<li><textarea id="foo"></textarea></li>'
    Forme::Form.new(:wrapper=>:li).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).must_equal '<li id="bar"><textarea id="foo"></textarea></li>'
  end

  it "wrapper: p wraps tag in an p" do
    Forme::Form.new(:wrapper=>:p).input(:textarea, :id=>'foo').must_equal '<p><textarea id="foo"></textarea></p>'
    Forme::Form.new(:wrapper=>:p).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).must_equal '<p id="bar"><textarea id="foo"></textarea></p>'
  end

  it "wrapper: div wraps tag in an div" do
    Forme::Form.new(:wrapper=>:div).input(:textarea, :id=>'foo').must_equal '<div><textarea id="foo"></textarea></div>'
    Forme::Form.new(:wrapper=>:div).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).must_equal '<div id="bar"><textarea id="foo"></textarea></div>'
  end

  it "wrapper: span wraps tag in an span" do
    Forme::Form.new(:wrapper=>:span).input(:textarea, :id=>'foo').must_equal '<span><textarea id="foo"></textarea></span>'
    Forme::Form.new(:wrapper=>:span).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).must_equal '<span id="bar"><textarea id="foo"></textarea></span>'
  end

  it "wrapper: td wraps tag in an td" do
    Forme::Form.new(:wrapper=>:td).input(:textarea, :id=>'foo').must_equal '<td><textarea id="foo"></textarea></td>'
    Forme::Form.new(:wrapper=>:td).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).must_equal '<td id="bar"><textarea id="foo"></textarea></td>'
  end

  it "wrapper: trtd wraps tag in an tr/td" do
    Forme::Form.new(:wrapper=>:trtd).input(:textarea, :id=>'foo').must_equal '<tr><td><textarea id="foo"></textarea></td><td></td></tr>'
    Forme::Form.new(:wrapper=>:trtd).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).must_equal '<tr id="bar"><td><textarea id="foo"></textarea></td><td></td></tr>'
  end

  it "wrapper: trtd supports multiple tags in separate tds" do
    Forme::Form.new(:wrapper=>:trtd, :labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'Foo').must_equal '<tr><td><label class="label-before" for="foo">Foo</label></td><td><textarea id="foo"></textarea></td></tr>'
  end

  it "wrapper: trtd should use at most 2 td tags" do
    Forme::Form.new(:wrapper=>:trtd, :labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'Foo', :error=>'Bar').must_equal '<tr><td><label class="label-before" for="foo">Foo</label></td><td><textarea aria-describedby="foo_error_message" aria-invalid="true" class="error" id="foo"></textarea><span class="error_message" id="foo_error_message">Bar</span></td></tr>'
  end

  it "wrapper: trtd should handle inputs with label after" do
    Forme::Form.new(:wrapper=>:trtd, :labeler=>:explicit).input(:checkbox, :id=>'foo', :name=>'foo', :label=>'Foo').must_equal '<tr><td><label class="label-after" for="foo">Foo</label></td><td><input id="foo_hidden" name="foo" type="hidden" value="0"/><input id="foo" name="foo" type="checkbox"/></td></tr>'
  end

  it "wrapper: tr should use a td wrapper and tr inputs_wrapper" do
    Forme::Form.new(:wrapper=>:tr).inputs([:textarea]).must_equal '<tr><td><textarea></textarea></td></tr>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:tr){f.inputs([:textarea])}.must_equal '<tr><td><textarea></textarea></td></tr>'
  end

  it "wrapper: table should use a trtd wrapper and table inputs_wrapper" do
    Forme::Form.new(:wrapper=>:table).inputs([:textarea]).must_equal '<table><tbody><tr><td><textarea></textarea></td><td></td></tr></tbody></table>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:table){f.inputs([:textarea])}.must_equal '<table><tbody><tr><td><textarea></textarea></td><td></td></tr></tbody></table>'
  end

  it "wrapper: ol should use an li wrapper and ol inputs_wrapper" do
    Forme::Form.new(:wrapper=>:ol).inputs([:textarea]).must_equal '<ol><li><textarea></textarea></li></ol>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:ol){f.inputs([:textarea])}.must_equal '<ol><li><textarea></textarea></li></ol>'
  end

  it "wrapper: fieldset_ol should use an li wrapper and fieldset_ol inputs_wrapper" do
    Forme::Form.new(:wrapper=>:fieldset_ol).inputs([:textarea]).must_equal '<fieldset class="inputs"><ol><li><textarea></textarea></li></ol></fieldset>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:fieldset_ol){f.inputs([:textarea])}.must_equal '<fieldset class="inputs"><ol><li><textarea></textarea></li></ol></fieldset>'
  end

  it "wrapper should not override inputs_wrapper if both given" do
    Forme::Form.new(:wrapper=>:tr, :inputs_wrapper=>:div).inputs([:textarea]).must_equal '<div><td><textarea></textarea></td></div>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:tr, :inputs_wrapper=>:div){f.inputs([:textarea])}.must_equal '<div><td><textarea></textarea></td></div>'
  end

  it "inputs_wrapper: ol wraps tags in an ol" do
    Forme::Form.new(:inputs_wrapper=>:ol, :wrapper=>:li).inputs([:textarea]).must_equal '<ol><li><textarea></textarea></li></ol>'
    Forme::Form.new(:inputs_wrapper=>:ol, :wrapper=>:li).inputs([:textarea], :attr=>{:foo=>1}).must_equal '<ol foo="1"><li><textarea></textarea></li></ol>'
  end

  it "inputs_wrapper: fieldset_ol wraps tags in a fieldset and an ol" do
    Forme::Form.new(:inputs_wrapper=>:fieldset_ol, :wrapper=>:li).inputs([:textarea]).must_equal '<fieldset class="inputs"><ol><li><textarea></textarea></li></ol></fieldset>'
    Forme::Form.new(:inputs_wrapper=>:fieldset_ol, :wrapper=>:li).inputs([:textarea], :attr=>{:foo=>1}).must_equal '<fieldset class="inputs" foo="1"><ol><li><textarea></textarea></li></ol></fieldset>'
  end

  it "inputs_wrapper: fieldset_ol supports a :legend option" do
    Forme.form({}, :inputs_wrapper=>:fieldset_ol, :wrapper=>:li, :legend=>'Foo', :inputs=>[:textarea]).must_equal '<form><fieldset class="inputs"><legend>Foo</legend><ol><li><textarea></textarea></li></ol></fieldset></form>'
  end

  it "inputs_wrapper: div wraps tags in a div" do
    Forme::Form.new(:inputs_wrapper=>:div, :wrapper=>:span).inputs([:textarea]).must_equal '<div><span><textarea></textarea></span></div>'
    Forme::Form.new(:inputs_wrapper=>:div, :wrapper=>:span).inputs([:textarea], :attr=>{:foo=>1}).must_equal '<div foo="1"><span><textarea></textarea></span></div>'
  end

  it "inputs_wrapper: tr wraps tags in an tr" do
    Forme::Form.new(:inputs_wrapper=>:tr, :wrapper=>:td).inputs([:textarea]).must_equal '<tr><td><textarea></textarea></td></tr>'
    Forme::Form.new(:inputs_wrapper=>:tr, :wrapper=>:td).inputs([:textarea], :attr=>{:foo=>1}).must_equal '<tr foo="1"><td><textarea></textarea></td></tr>'
  end

  it "inputs_wrapper: table wraps tags in an table" do
    Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs([:textarea]).must_equal '<table><tbody><tr><td><textarea></textarea></td><td></td></tr></tbody></table>'
    Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs([:textarea], :attr=>{:foo=>1}).must_equal '<table foo="1"><tbody><tr><td><textarea></textarea></td><td></td></tr></tbody></table>'
  end

  it "inputs_wrapper: table accepts a :legend option" do
   Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs([:textarea], :legend=>'Inputs').must_equal '<table><caption>Inputs</caption><tbody><tr><td><textarea></textarea></td><td></td></tr></tbody></table>'
  end

  it "inputs_wrapper: table accepts a :legend_attr option" do
    Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs([:textarea], :legend=>'Inputs', :legend_attr=>{:class=>'foo'}).must_equal '<table><caption class="foo">Inputs</caption><tbody><tr><td><textarea></textarea></td><td></td></tr></tbody></table>'
  end

  it "inputs_wrapper: table accepts a :labels option" do
    Forme::Form.new(:inputs_wrapper=>:table).inputs(:labels=>%w'A B C').must_equal '<table><thead><tr><th>A</th><th>B</th><th>C</th></tr></thead><tbody></tbody></table>'
  end

  it "inputs_wrapper: table doesn't add empty header row for :labels=>[]" do
    Forme::Form.new(:inputs_wrapper=>:table).inputs(:labels=>[]).must_equal '<table><tbody></tbody></table>'
  end

  it "serializer: html_usa formats dates and datetimes in American format without timezones" do
    Forme::Form.new(:serializer=>:html_usa).tag(:div, :foo=>Date.new(2011, 6, 5)).must_equal '<div foo="06/05/2011"></div>'
    Forme::Form.new(:serializer=>:html_usa).tag(:div, :foo=>DateTime.new(2011, 6, 5, 16, 3, 2)).must_equal '<div foo="06/05/2011 04:03:02PM"></div>'
    Forme::Form.new(:serializer=>:html_usa).tag(:div, :foo=>Time.utc(2011, 6, 5, 4, 3, 2)).must_equal '<div foo="06/05/2011 04:03:02AM"></div>'
  end

  it "serializer: html_usa should convert date and datetime inputs into text inputs" do
    Forme::Form.new(:serializer=>:html_usa).input(:date, :value=>Date.new(2011, 6, 5)).must_equal '<input type="text" value="06/05/2011"/>'
    Forme::Form.new(:serializer=>:html_usa).input(:datetime, :value=>DateTime.new(2011, 6, 5, 16, 3, 2)).must_equal '<input type="text" value="06/05/2011 04:03:02PM"/>'
  end

  it "serializer: text uses plain text output instead of html" do
    Forme::Form.new(:serializer=>:text).input(:textarea, :label=>"Foo", :value=>"Bar").must_equal "Foo: Bar\n\n"
    Forme::Form.new(:serializer=>:text).input(:text, :label=>"Foo", :value=>"Bar").must_equal "Foo: Bar\n\n"
    Forme::Form.new(:serializer=>:text).input(:radio, :label=>"Foo", :value=>"Bar").must_equal "___ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:radio, :label=>"Foo", :value=>"Bar", :checked=>true).must_equal "_X_ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:checkbox, :label=>"Foo", :value=>"Bar").must_equal "___ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:checkbox, :label=>"Foo", :value=>"Bar", :checked=>true).must_equal "_X_ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:select, :label=>"Foo", :options=>[1, 2, 3], :value=>2).must_equal "Foo: \n___ 1\n_X_ 2\n___ 3\n\n"
    Forme::Form.new(:serializer=>:text).input(:password, :label=>"Pass").must_equal "Pass: ********\n\n"
    Forme::Form.new(:serializer=>:text).button().must_equal ""
    Forme::Form.new(:serializer=>:text).inputs([[:textarea, {:label=>"Foo", :value=>"Bar"}]], :legend=>'Baz').must_equal "Baz\n---\nFoo: Bar\n\n"
    Forme::Form.new(:serializer=>:text).tag(:p){|f| f.input(:textarea, :label=>"Foo", :value=>"Bar")}.must_equal "Foo: Bar\n\n"
    Forme::Form.new(:serializer=>:text).tag(:p, {}, ['a']).must_equal "a"
  end

  it "Form#open and #close return empty string when using serializer: text" do
    f = Forme::Form.new(:serializer=>:text)
    f.open({}).must_be_nil
    f.close.must_be_nil
  end
end

describe "Forme registering custom transformers" do
  it "should have #register_transformer register a transformer object for later use" do
    Forme.register_transformer(:wrapper, :div2, proc{|t, i| i.tag(:div2, {}, [t])})
    Forme::Form.new(:wrapper=>:div2).input(:textarea).must_equal '<div2><textarea></textarea></div2>'
  end

  it "should have #register_transformer register a transformer block for later use" do
    Forme.register_transformer(:wrapper, :div1){|t, i| i.tag(:div1, {}, [t])}
    Forme::Form.new(:wrapper=>:div1).input(:textarea).must_equal '<div1><textarea></textarea></div1>'
  end

  it "should have #register_transformer raise an error if given a block and an object" do
    proc do
      Forme.register_transformer(:wrapper, :div1, proc{|t, i| t}){|t, i| i.tag(:div1, {}, [t])}
    end.must_raise(Forme::Error)
  end

  it "should have #register_transformer raise an error for invalid transformer" do
    proc do
      Forme.register_transformer(:foo, :div1){}
    end.must_raise(Forme::Error)
  end
end

describe "Forme configurations" do
  after do
    Forme.default_config = :default
  end

  it "config: :formastic uses fieldset_ol inputs_wrapper and li wrapper, and explicit labeler" do
    Forme::Form.new(:config=>:formtastic).inputs([[:textarea, {:id=>:foo, :label=>'Foo'}]]).must_equal '<fieldset class="inputs"><ol><li><label class="label-before" for="foo">Foo</label><textarea id="foo"></textarea></li></ol></fieldset>'
  end

  it "should be able to set a default configuration with Forme.default_config=" do
    Forme.default_config = :formtastic
    Forme::Form.new.inputs([[:textarea, {:id=>:foo, :label=>'Foo'}]]).must_equal '<fieldset class="inputs"><ol><li><label class="label-before" for="foo">Foo</label><textarea id="foo"></textarea></li></ol></fieldset>'
  end

  it "should have #register_config register a configuration for later use" do
    Forme.register_config(:foo, :wrapper=>:li, :labeler=>:explicit)
    Forme::Form.new(:config=>:foo).input(:textarea, :id=>:foo, :label=>'Foo').must_equal '<li><label class="label-before" for="foo">Foo</label><textarea id="foo"></textarea></li>'
  end

  it "should have #register_config support a :base option to base it on an existing config" do
    Forme.register_config(:foo2, :labeler=>:default, :base=>:formtastic)
    Forme::Form.new(:config=>:foo2).inputs([[:textarea, {:id=>:foo, :label=>'Foo'}]]).must_equal '<fieldset class="inputs"><ol><li><label>Foo: <textarea id="foo"></textarea></label></li></ol></fieldset>'
  end

end

describe "Forme object forms" do
  it "should handle a simple case" do
    obj = Class.new{def forme_input(form, field, opts) form._input(:text, :name=>"obj[#{field}]", :id=>"obj_#{field}", :value=>"#{field}_foo") end}.new 
    Forme::Form.new(obj).input(:field).must_equal  '<input id="obj_field" name="obj[field]" type="text" value="field_foo"/>'
  end

  it "should handle more complex case with multiple different types and opts" do
    obj = Class.new do 
      def self.name() "Foo" end

      attr_reader :x, :y

      def initialize(x, y)
        @x, @y = x, y
      end
      def forme_input(form, field, opts={})
        t = opts[:type]
        t ||= (field == :x ? :textarea : :text)
        s = field
        form._input(t, {:label=>s.upcase, :name=>"foo[#{s}]", :id=>"foo_#{s}", :value=>send(field)}.merge!(opts))
      end
    end.new('&foo', 3)
    f = Forme::Form.new(obj)
    f.input(:x).must_equal '<label>X: <textarea id="foo_x" name="foo[x]">&amp;foo</textarea></label>'
    f.input(:y, :attr=>{:brain=>'no'}).must_equal '<label>Y: <input brain="no" id="foo_y" name="foo[y]" type="text" value="3"/></label>'
  end

  it "should handle case where obj doesn't respond to forme_input" do
    Forme::Form.new([:foo]).input(:first).must_equal  '<input id="first" name="first" type="text" value="foo"/>'
    obj = Class.new{attr_accessor :foo}.new
    obj.foo = 'bar'
    Forme::Form.new(obj).input(:foo).must_equal  '<input id="foo" name="foo" type="text" value="bar"/>'
  end

  it "should respect opts hash when obj doesn't respond to forme_input" do
    Forme::Form.new([:foo]).input(:first, :name=>'bar').must_equal  '<input id="first" name="bar" type="text" value="foo"/>'
    Forme::Form.new([:foo]).input(:first, :id=>'bar').must_equal  '<input id="bar" name="first" type="text" value="foo"/>'
    Forme::Form.new([:foo]).input(:first, :value=>'bar').must_equal  '<input id="first" name="first" type="text" value="bar"/>'
    Forme::Form.new([:foo]).input(:first, :attr=>{:x=>'bar'}).must_equal  '<input id="first" name="first" type="text" value="foo" x="bar"/>'
  end

  it "should respect current namespace" do
    Forme::Form.new([:foo], :namespace=>'a').input(:first).must_equal  '<input id="a_first" name="a[first]" type="text" value="foo"/>'
  end

  it "should get values for hashes using #[]" do
    Forme::Form.new(:obj=>{:bar=>:foo}, :namespace=>'a').input(:bar).must_equal  '<input id="a_bar" name="a[bar]" type="text" value="foo"/>'
  end

  it "should handle obj passed in via :obj hash key" do
    Forme::Form.new(:obj=>[:foo]).input(:first).must_equal  '<input id="first" name="first" type="text" value="foo"/>'
  end

  it "should be able to turn off obj handling per input using :obj=>nil option" do
    Forme::Form.new([:foo]).input(:checkbox, :name=>"foo", :hidden_value=>"no", :obj=>nil).must_equal '<input name="foo" type="hidden" value="no"/><input name="foo" type="checkbox"/>'
  end

  it "should be able to change input type" do
    Forme::Form.new([:foo]).input(:first, :type=>:email).must_equal  '<input id="first" name="first" type="email" value="foo"/>'
  end

  it "should not have default value for file input" do
    Forme::Form.new([:foo]).input(:first, :type=>:file).must_equal  '<input id="first" name="first" type="file"/>'
  end

  it "should be able to set value for file input" do
    Forme::Form.new([:foo]).input(:first, :type=>:file, :value=>"foo").must_equal  '<input id="first" name="first" type="file" value="foo"/>'
  end

  it "should respect given :key option" do
    Forme::Form.new([:foo]).input(:first, :key=>'a').must_equal  '<input id="a" name="a" type="text" value="foo"/>'
  end

  it "should not accept 3 hash arguments" do
    proc{Forme.form({:a=>'1'}, {:b=>'2'}, {:c=>'3'})}.must_raise Forme::Error
  end
end

describe "Forme.form DSL" do
  it "should return a form tag" do
    Forme.form.must_equal  '<form></form>'
  end

  it "should yield a Form object to the block" do
    Forme.form{|f| f.must_be_kind_of(Forme::Form)}
  end

  it "should respect an array of classes" do
    Forme.form(:class=>[:foo, :bar]).must_equal  '<form class="foo bar"></form>'
    Forme.form(:class=>[:foo, [:bar, :baz]]).must_equal  '<form class="foo bar baz"></form>'
  end

  it "should have inputs called instead the block be added to the existing form" do
    Forme.form{|f| f.input(:text)}.must_equal  '<form><input type="text"/></form>'
  end

  it "should be able to nest inputs inside tags" do
    Forme.form{|f| f.tag(:div){f.input(:text)}}.must_equal  '<form><div><input type="text"/></div></form>'
    Forme.form{|f| f.tag(:div){f.tag(:fieldset){f.input(:text)}}}.must_equal  '<form><div><fieldset><input type="text"/></fieldset></div></form>'
    Forme.form{|f| f.tag(:div){f.tag(:fieldset){f.tag(:span){f.input(:text)}}}}.must_equal  '<form><div><fieldset><span><input type="text"/></span></fieldset></div></form>'
    Forme.form{|f| f.tag(:div){f.input(:text)}; f.input(:radio)}.must_equal  '<form><div><input type="text"/></div><input type="radio"/></form>'
    Forme.form{|f| f.tag(:div){f.tag(:fieldset){f.input(:text);  f.input(:radio)};  f.input(:checkbox)}}.must_equal  '<form><div><fieldset><input type="text"/><input type="radio"/></fieldset><input type="checkbox"/></div></form>'
  end

  it "should handle an :inputs option to automatically create inputs" do
    Forme.form({}, :inputs=>[:text, :textarea]).must_equal  '<form><fieldset class="inputs"><input type="text"/><textarea></textarea></fieldset></form>'
  end

  it "should handle a :legend option if inputs is used" do
    Forme.form({}, :inputs=>[:text, :textarea], :legend=>'Foo').must_equal  '<form><fieldset class="inputs"><legend>Foo</legend><input type="text"/><textarea></textarea></fieldset></form>'
  end

  it "should still work with a block if :inputs is used" do
    Forme.form({}, :inputs=>[:text]){|f| f.input(:textarea)}.must_equal  '<form><fieldset class="inputs"><input type="text"/></fieldset><textarea></textarea></form>'
  end

  it "should handle an :button option to automatically create a button" do
    Forme.form({}, :button=>'Foo').must_equal  '<form><input type="submit" value="Foo"/></form>'
  end

  it "should allow :button option value to be a hash" do
    Forme.form({}, :button=>{:value=>'Foo', :name=>'bar'}).must_equal  '<form><input name="bar" type="submit" value="Foo"/></form>'
  end

  it "should handle an :button option work with a block" do
    Forme.form({}, :button=>'Foo'){|f| f.input(:textarea)}.must_equal  '<form><textarea></textarea><input type="submit" value="Foo"/></form>'
  end

  it "should have an :button and :inputs option work together" do
    Forme.form({}, :inputs=>[:text, :textarea], :button=>'Foo').must_equal  '<form><fieldset class="inputs"><input type="text"/><textarea></textarea></fieldset><input type="submit" value="Foo"/></form>'
  end
end
