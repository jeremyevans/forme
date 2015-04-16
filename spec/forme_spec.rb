require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

describe "Forme plain forms" do
  def sel(opts, s)
    opts.map{|o| "<option #{'selected="selected" ' if o == s}value=\"#{o}\">#{sprintf("%02i", o)}</option>"}.join
  end

  before do
    @f = Forme::Form.new
  end

  specify "Forme.version should return version string" do
    Forme.version.should =~ /\A\d+\.\d+\.\d+\z/
  end

  specify "should create a simple input tags" do
    @f.input(:text).to_s.should == '<input type="text"/>'
    @f.input(:radio).to_s.should == '<input type="radio"/>'
    @f.input(:password).to_s.should == '<input type="password"/>'
    @f.input(:checkbox).to_s.should == '<input type="checkbox"/>'
    @f.input(:submit).to_s.should == '<input type="submit"/>'
  end

  specify "should use :name option as attribute" do
    @f.input(:text, :name=>"foo").to_s.should == '<input name="foo" type="text"/>'
  end

  specify "should use :id option as attribute" do
    @f.input(:text, :id=>"foo").to_s.should == '<input id="foo" type="text"/>'
  end

  specify "should use :class option as attribute" do
    @f.input(:text, :class=>"foo").to_s.should == '<input class="foo" type="text"/>'
  end

  specify "should use :value option as attribute" do
    @f.input(:text, :value=>"foo").to_s.should == '<input type="text" value="foo"/>'
  end

  specify "should use :placeholder option as attribute" do
    @f.input(:text, :placeholder=>"foo").to_s.should == '<input placeholder="foo" type="text"/>'
  end

  specify "should use :style option as attribute" do
    @f.input(:text, :style=>"foo").to_s.should == '<input style="foo" type="text"/>'
  end

  specify "should use :key option as name and id attributes" do
    @f.input(:text, :key=>"foo").to_s.should == '<input id="foo" name="foo" type="text"/>'
  end

  specify "should use :key_id option as suffix for :key option id attributes" do
    @f.input(:text, :key=>"foo", :key_id=>'bar').to_s.should == '<input id="foo_bar" name="foo" type="text"/>'
  end

  specify "should have :key option respect :multiple option" do
    @f.input(:text, :key=>"foo", :multiple=>true).to_s.should == '<input id="foo" name="foo[]" type="text"/>'
  end

  specify "should use :key option respect form's current namespace" do
    @f.with_opts(:namespace=>['bar']) do
      @f.input(:text, :key=>"foo").to_s.should == '<input id="bar_foo" name="bar[foo]" type="text"/>'
      @f.input(:text, :key=>"foo", :multiple=>true).to_s.should == '<input id="bar_foo" name="bar[foo][]" type="text"/>'
      @f.with_opts(:namespace=>['bar', 'baz']) do
        @f.input(:text, :key=>"foo").to_s.should == '<input id="bar_baz_foo" name="bar[baz][foo]" type="text"/>'
      end
    end
  end

  specify "should consider form's :values hash for default values based on the :key option if :value is not present" do
    @f.opts[:values] = {'foo'=>'baz'}
    @f.input(:text, :key=>"foo").to_s.should == '<input id="foo" name="foo" type="text" value="baz"/>'
    @f.input(:text, :key=>"foo", :value=>'x').to_s.should == '<input id="foo" name="foo" type="text" value="x"/>'

    @f.input(:text, :key=>:foo).to_s.should == '<input id="foo" name="foo" type="text" value="baz"/>'
    @f.opts[:values] = {:foo=>'baz'}
    @f.input(:text, :key=>:foo).to_s.should == '<input id="foo" name="foo" type="text" value="baz"/>'
  end

  specify "should consider form's :values hash for default values based on the :key option when using namespaces" do
    @f.opts[:values] = {'bar'=>{'foo'=>'baz'}}
    @f.with_opts(:namespace=>['bar']) do
      @f.input(:text, :key=>"foo").to_s.should == '<input id="bar_foo" name="bar[foo]" type="text" value="baz"/>'
      @f.input(:text, :key=>"foo", :value=>'x').to_s.should == '<input id="bar_foo" name="bar[foo]" type="text" value="x"/>'
      @f.input(:text, :key=>:foo).to_s.should == '<input id="bar_foo" name="bar[foo]" type="text" value="baz"/>'
    end

    @f.with_opts(:namespace=>[:bar]) do
      @f.input(:text, :key=>:foo).to_s.should == '<input id="bar_foo" name="bar[foo]" type="text" value="baz"/>'

      @f.opts[:values] = {:bar=>{:foo=>'baz'}}
      @f.input(:text, :key=>:foo).to_s.should == '<input id="bar_foo" name="bar[foo]" type="text" value="baz"/>'
      @f.opts[:values] = {:bar=>{}}
      @f.input(:text, :key=>:foo).to_s.should == '<input id="bar_foo" name="bar[foo]" type="text"/>'
      @f.opts[:values] = {}
      @f.input(:text, :key=>:foo).to_s.should == '<input id="bar_foo" name="bar[foo]" type="text"/>'

      @f.opts[:values] = {'bar'=>{'quux'=>{'foo'=>'baz'}}}
      @f.with_opts(:namespace=>['bar', 'quux']) do
        @f.input(:text, :key=>"foo").to_s.should == '<input id="bar_quux_foo" name="bar[quux][foo]" type="text" value="baz"/>'
      end
    end
  end

  specify "should support a with_obj method that changes the object and namespace for the given block" do
    @f.with_obj([:a, :c], 'bar') do
      @f.input(:first).to_s.should == '<input id="bar_first" name="bar[first]" type="text" value="a"/>'
      @f.with_obj([:b], 'baz') do
        @f.input(:first).to_s.should == '<input id="bar_baz_first" name="bar[baz][first]" type="text" value="b"/>'
      end
      @f.with_obj([:b], %w'baz quux') do
        @f.input(:first).to_s.should == '<input id="bar_baz_quux_first" name="bar[baz][quux][first]" type="text" value="b"/>'
      end
      @f.with_obj([:b]) do
        @f.input(:first).to_s.should == '<input id="bar_first" name="bar[first]" type="text" value="b"/>'
      end
      @f.input(:last).to_s.should == '<input id="bar_last" name="bar[last]" type="text" value="c"/>'
    end
  end

  specify "should support a each_obj method that changes the object and namespace for multiple objects for the given block" do
    @f.tag(:form) do
      @f.each_obj([[:a, :c], [:b, :d]], 'bar') do
        @f.input(:first)
        @f.input(:last)
      end
    end.to_s.should == '<form><input id="bar_0_first" name="bar[0][first]" type="text" value="a"/><input id="bar_0_last" name="bar[0][last]" type="text" value="c"/><input id="bar_1_first" name="bar[1][first]" type="text" value="b"/><input id="bar_1_last" name="bar[1][last]" type="text" value="d"/></form>'

    @f.tag(:form) do
      @f.each_obj([[:a, :c], [:b, :d]], %w'bar baz') do
        @f.input(:first)
        @f.input(:last)
      end
    end.to_s.should == '<form><input id="bar_baz_0_first" name="bar[baz][0][first]" type="text" value="a"/><input id="bar_baz_0_last" name="bar[baz][0][last]" type="text" value="c"/><input id="bar_baz_1_first" name="bar[baz][1][first]" type="text" value="b"/><input id="bar_baz_1_last" name="bar[baz][1][last]" type="text" value="d"/></form>'

    @f.tag(:form) do
      @f.each_obj([[:a, :c], [:b, :d]]) do
        @f.input(:first)
        @f.input(:last)
      end
    end.to_s.should == '<form><input id="0_first" name="0[first]" type="text" value="a"/><input id="0_last" name="0[last]" type="text" value="c"/><input id="1_first" name="1[first]" type="text" value="b"/><input id="1_last" name="1[last]" type="text" value="d"/></form>'
  end

  specify "should allow overriding form inputs on a per-block basis" do
    @f.input(:text).to_s.should == '<input type="text"/>'
    @f.with_opts(:wrapper=>:div){@f.input(:text).to_s}.should == '<div><input type="text"/></div>'
    @f.with_opts(:wrapper=>:div){@f.input(:text).to_s.should == '<div><input type="text"/></div>'}
    @f.with_opts(:wrapper=>:div) do
      @f.input(:text).to_s.should == '<div><input type="text"/></div>'
      @f.with_opts(:wrapper=>:li){@f.input(:text).to_s.should == '<li><input type="text"/></li>'}
      @f.input(:text).to_s.should == '<div><input type="text"/></div>'
    end
    @f.input(:text).to_s.should == '<input type="text"/>'
  end

  specify "should handle delayed formatting when overriding form inputs on a per-block basis" do
    @f.form do
      @f.input(:text)
      @f.with_opts(:wrapper=>:div) do
        @f.input(:text)
        @f.with_opts(:wrapper=>:li){@f.input(:text)}
        @f.input(:text)
      end
      @f.input(:text)
    end.to_s.should == '<form><input type="text"/><div><input type="text"/></div><li><input type="text"/></li><div><input type="text"/></div><input type="text"/></form>'
  end

  specify "should support :obj method to with_opts for changing the obj inside the block" do
    @f.form do
      @f.with_opts(:obj=>[:a, :c]) do
        @f.input(:first)
        @f.with_opts(:obj=>[:b]){@f.input(:first)}
        @f.input(:last)
      end
    end.to_s.should == '<form><input id="first" name="first" type="text" value="a"/><input id="first" name="first" type="text" value="b"/><input id="last" name="last" type="text" value="c"/></form>'
  end

  specify "should allow arbitrary attributes using the :attr option" do
    @f.input(:text, :attr=>{:bar=>"foo"}).to_s.should == '<input bar="foo" type="text"/>'
  end

  specify "should convert the :data option into attributes" do
    @f.input(:text, :data=>{:bar=>"foo"}).to_s.should == '<input data-bar="foo" type="text"/>'
  end

  specify "should not have standard options override the :attr option" do
    @f.input(:text, :name=>:bar, :attr=>{:name=>"foo"}).to_s.should == '<input name="foo" type="text"/>'
  end

  specify "should combine :class standard option with :attr option" do
    @f.input(:text, :class=>:bar, :attr=>{:class=>"foo"}).to_s.should == '<input class="foo bar" type="text"/>'
  end

  specify "should not have :data options override the :attr option" do
    @f.input(:text, :data=>{:bar=>"baz"}, :attr=>{:"data-bar"=>"foo"}).to_s.should == '<input data-bar="foo" type="text"/>'
  end

  specify "should use :size and :maxlength options as attributes for text inputs" do
    @f.input(:text, :size=>5, :maxlength=>10).to_s.should == '<input maxlength="10" size="5" type="text"/>'
    @f.input(:textarea, :size=>5, :maxlength=>10).to_s.should == '<textarea></textarea>'
  end

  specify "should create hidden input with value 0 for each checkbox with a name" do
    @f.input(:checkbox, :name=>"foo").to_s.should == '<input name="foo" type="hidden" value="0"/><input name="foo" type="checkbox"/>'
  end

  specify "should not create hidden input with value 0 for each checkbox with a name if :no_hidden option is used" do
    @f.input(:checkbox, :name=>"foo", :no_hidden=>true).to_s.should == '<input name="foo" type="checkbox"/>'
  end

  specify "should create hidden input with _hidden appened to id for each checkbox with a name and id" do
    @f.input(:checkbox, :name=>"foo", :id=>"bar").to_s.should == '<input id="bar_hidden" name="foo" type="hidden" value="0"/><input id="bar" name="foo" type="checkbox"/>'
  end

  specify "should create hidden input with value f for each checkbox with a name and value t" do
    @f.input(:checkbox, :name=>"foo", :value=>"t").to_s.should == '<input name="foo" type="hidden" value="f"/><input name="foo" type="checkbox" value="t"/>'
  end

  specify "should use :hidden_value option for value of hidden input for checkbox" do
    @f.input(:checkbox, :name=>"foo", :hidden_value=>"no").to_s.should == '<input name="foo" type="hidden" value="no"/><input name="foo" type="checkbox"/>'
  end

  specify "should handle :checked option" do
    @f.input(:checkbox, :checked=>true).to_s.should == '<input checked="checked" type="checkbox"/>'
    @f.input(:checkbox, :checked=>false).to_s.should == '<input type="checkbox"/>'
  end

  specify "should create textarea tag" do
    @f.input(:textarea).to_s.should == '<textarea></textarea>'
    @f.input(:textarea, :value=>'a').to_s.should == '<textarea>a</textarea>'
  end

  specify "should use :cols and :rows options as attributes for textarea inputs" do
    @f.input(:text, :cols=>5, :rows=>10).to_s.should == '<input type="text"/>'
    @f.input(:textarea, :cols=>5, :rows=>10).to_s.should == '<textarea cols="5" rows="10"></textarea>'
  end

  specify "should create select tag" do
    @f.input(:select).to_s.should == '<select></select>'
  end

  specify "should respect multiple and size options in select tag" do
    @f.input(:select, :multiple=>true, :size=>10).to_s.should == '<select multiple="multiple" size="10"></select>'
  end

  specify "should create date tag" do
    @f.input(:date).to_s.should == '<input type="date"/>'
  end

  specify "should create datetime-local tag" do
    @f.input(:datetime).to_s.should == '<input type="datetime-local"/>'
  end

  specify "should not error for input type :input" do
    @f.input(:input).to_s.should == '<input type="input"/>'
  end

  specify "should use multiple select boxes for dates if the :as=>:select option is given" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5)).to_s.should == %{<select id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>}
  end

  specify "should allow ordering date select boxes via :order" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :order=>[:month, '/', :day, '/', :year]).to_s.should == %{<select id="bar" name="foo[month]">#{sel(1..12, 6)}</select>/<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>/<select id="bar_year" name="foo[year]">#{sel(1900..2050, 2011)}</select>}
  end

  specify "should allow only using specific date select boxes via :order" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :order=>[:month, :year]).to_s.should == %{<select id="bar" name="foo[month]">#{sel(1..12, 6)}</select><select id="bar_year" name="foo[year]">#{sel(1900..2050, 2011)}</select>}
  end

  specify "should support :select_options for dates when :as=>:select is given" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :select_options=>{:year=>1970..2020}).to_s.should == %{<select id="bar" name="foo[year]">#{sel(1970..2020, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select>}
  end

  specify "should have explicit labeler and trtd wrapper work with multiple select boxes for dates" do
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :wrapper=>:trtd, :labeler=>:explicit, :label=>'Baz').to_s.should == %{<tr><td><label class="label-before" for="bar">Baz</label></td><td><select id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select></td></tr>}
  end

  specify "should use multiple select boxes for datetimes if the :as=>:select option is given" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>DateTime.new(2011, 6, 5, 4, 3, 2)).to_s.should == %{<select id="bar" name="foo[year]">#{sel(1900..2050, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select> <select id="bar_hour" name="foo[hour]">#{sel(0..23, 4)}</select>:<select id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select>:<select id="bar_second" name="foo[second]">#{sel(0..59, 2)}</select>}
  end

  specify "should allow ordering select boxes for datetimes via :order" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>DateTime.new(2011, 6, 5, 4, 3, 2), :order=>[:day, '/', :month, 'T', :hour, ':', :minute]).to_s.should == %{<select id="bar" name="foo[day]">#{sel(1..31, 5)}</select>/<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>T<select id="bar_hour" name="foo[hour]">#{sel(0..23, 4)}</select>:<select id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select>}
  end

  specify "should support :select_options for datetimes when :as=>:select option is given" do
    @f.input(:datetime, :name=>"foo", :id=>"bar", :as=>:select, :value=>DateTime.new(2011, 6, 5, 10, 3, 2), :select_options=>{:year=>1970..2020, :hour=>9..17}).to_s.should == %{<select id="bar" name="foo[year]">#{sel(1970..2020, 2011)}</select>-<select id="bar_month" name="foo[month]">#{sel(1..12, 6)}</select>-<select id="bar_day" name="foo[day]">#{sel(1..31, 5)}</select> <select id="bar_hour" name="foo[hour]">#{sel(9..17, 10)}</select>:<select id="bar_minute" name="foo[minute]">#{sel(0..59, 3)}</select>:<select id="bar_second" name="foo[second]">#{sel(0..59, 2)}</select>}
  end

  specify "should create select tag with options" do
    @f.input(:select, :options=>[1, 2, 3], :selected=>2).to_s.should == '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
    @f.input(:select, :options=>[1, 2, 3], :value=>2).to_s.should == '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
  end

  specify "should create select tag with options and values" do
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).to_s.should == '<select><option value="1">a</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  specify "should create select tag with option groups" do
    @f.input(:select, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :selected=>2).to_s.should == '<select><optgroup label="d"><option value="1">a</option><option selected="selected" value="2">b</option></optgroup><optgroup label="e"><option value="3">c</option></optgroup></select>'
  end

  specify "should create select tag with option groups with attributes" do
    @f.input(:select, :optgroups=>[[{:label=>'d', :class=>'f'}, [[:a, 1], [:b, 2]]], [{:label=>'e', :class=>'g'}, [[:c, 3]]]], :selected=>2).to_s.should == '<select><optgroup class="f" label="d"><option value="1">a</option><option selected="selected" value="2">b</option></optgroup><optgroup class="g" label="e"><option value="3">c</option></optgroup></select>'
  end

  specify "should create select tag with options and values with hashes" do
    @f.input(:select, :options=>[[:a, {:foo=>1}], [:b, {:bar=>4, :value=>2}], [:c, {:baz=>3}]], :selected=>2).to_s.should == '<select><option foo="1">a</option><option bar="4" selected="selected" value="2">b</option><option baz="3">c</option></select>'
  end

  specify "should create select tag with options and values using given method" do
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).to_s.should == '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).to_s.should == '<select><option value="a">1</option><option selected="selected" value="b">2</option><option value="c">3</option></select>'
  end

  specify "should use html attributes specified in options" do
    @f.input(:text, :value=>'foo', :name=>'bar').to_s.should == '<input name="bar" type="text" value="foo"/>'
    @f.input(:textarea, :value=>'foo', :name=>'bar').to_s.should == '<textarea name="bar">foo</textarea>'
    @f.input(:select, :name=>'bar', :options=>[1, 2, 3]).to_s.should == '<select name="bar"><option>1</option><option>2</option><option>3</option></select>'
  end

  specify "should support :add_blank option for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).to_s.should == '<select><option value=""></option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  specify "should use Forme.default_add_blank_prompt value if :add_blank option is true" do
    begin
      Forme.default_add_blank_prompt = 'foo'
      @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).to_s.should == '<select><option value="">foo</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
    ensure
      Forme.default_add_blank_prompt = nil
    end
  end

  specify "should use :add_blank option value as prompt if it is a String" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).to_s.should == '<select><option value="">Prompt Here</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  specify "should support :add_blank option with :blank_position :after for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :blank_position=>:after, :value=>2).to_s.should == '<select><option selected="selected" value="2">b</option><option value="3">c</option><option value=""></option></select>'
  end

  specify "should support :add_blank option with :blank_attr option for select inputs" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :blank_attr=>{:foo=>:bar}, :value=>2).to_s.should == '<select><option foo="bar" value=""></option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  specify "should create set of radio buttons" do
    @f.input(:radioset, :options=>[1, 2, 3], :selected=>2).to_s.should == '<label class="option"><input type="radio" value="1"/> 1</label><label class="option"><input checked="checked" type="radio" value="2"/> 2</label><label class="option"><input type="radio" value="3"/> 3</label>'
    @f.input(:radioset, :options=>[1, 2, 3], :value=>2).to_s.should == '<label class="option"><input type="radio" value="1"/> 1</label><label class="option"><input checked="checked" type="radio" value="2"/> 2</label><label class="option"><input type="radio" value="3"/> 3</label>'
  end

  specify "should create set of radio buttons with options and values" do
    @f.input(:radioset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).to_s.should == '<label class="option"><input type="radio" value="1"/> a</label><label class="option"><input checked="checked" type="radio" value="2"/> b</label><label class="option"><input type="radio" value="3"/> c</label>'
  end

  specify "should create set of radio buttons with options and values with hashes" do
    @f.input(:radioset, :options=>[[:a, {:attr=>{:foo=>1}}], [:b, {:class=>'foo', :value=>2}], [:c, {:id=>:baz}]], :selected=>2).to_s.should == '<label class="option"><input foo="1" type="radio" value="a"/> a</label><label class="option"><input checked="checked" class="foo" type="radio" value="2"/> b</label><label class="option"><input id="baz" type="radio" value="c"/> c</label>'
  end

  specify "should create set of radio buttons with options and values using given method" do
    @f.input(:radioset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).to_s.should == '<label class="option"><input type="radio" value="1"/> 1</label><label class="option"><input checked="checked" type="radio" value="2"/> 2</label><label class="option"><input type="radio" value="3"/> 3</label>'
    @f.input(:radioset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).to_s.should == '<label class="option"><input type="radio" value="a"/> 1</label><label class="option"><input checked="checked" type="radio" value="b"/> 2</label><label class="option"><input type="radio" value="c"/> 3</label>'
  end

  specify "should support :add_blank option for radioset inputs" do
    @f.input(:radioset, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).to_s.should == '<label class="option"><input type="radio" value=""/> </label><label class="option"><input checked="checked" type="radio" value="2"/> b</label><label class="option"><input type="radio" value="3"/> c</label>'
  end

  specify "should use :add_blank option value as prompt if it is a String" do
    @f.input(:radioset, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).to_s.should == '<label class="option"><input type="radio" value=""/> Prompt Here</label><label class="option"><input checked="checked" type="radio" value="2"/> b</label><label class="option"><input type="radio" value="3"/> c</label>'
  end

  specify "should respect the :key option for radio sets" do
    @f.input(:radioset, :options=>[1, 2, 3], :key=>:foo, :value=>2).to_s.should == '<label class="option"><input id="foo_1" name="foo" type="radio" value="1"/> 1</label><label class="option"><input checked="checked" id="foo_2" name="foo" type="radio" value="2"/> 2</label><label class="option"><input id="foo_3" name="foo" type="radio" value="3"/> 3</label>'
  end

  specify "should create set of radio buttons with fieldsets and legends for :optgroups" do
    @f.input(:radioset, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :selected=>2).to_s.should == '<fieldset><legend>d</legend><label class="option"><input type="radio" value="1"/> a</label><label class="option"><input checked="checked" type="radio" value="2"/> b</label></fieldset><fieldset><legend>e</legend><label class="option"><input type="radio" value="3"/> c</label></fieldset>'
  end

  specify "should create set of checkbox buttons" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :selected=>2).to_s.should == '<label class="option"><input type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option"><input type="checkbox" value="3"/> 3</label>'
    @f.input(:checkboxset, :options=>[1, 2, 3], :value=>2).to_s.should == '<label class="option"><input type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option"><input type="checkbox" value="3"/> 3</label>'
  end

  specify "should create set of checkbox buttons with options and values" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).to_s.should == '<label class="option"><input type="checkbox" value="1"/> a</label><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label><label class="option"><input type="checkbox" value="3"/> c</label>'
  end

  specify "should create set of checkbox buttons with options and values with hashes" do
    @f.input(:checkboxset, :options=>[[:a, {:attr=>{:foo=>1}}], [:b, {:class=>'foo', :value=>2}], [:c, {:id=>:baz}]], :selected=>2).to_s.should == '<label class="option"><input foo="1" type="checkbox" value="a"/> a</label><label class="option"><input checked="checked" class="foo" type="checkbox" value="2"/> b</label><label class="option"><input id="baz" type="checkbox" value="c"/> c</label>'
  end

  specify "should create set of checkbox buttons with options and values using given method" do
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :selected=>2).to_s.should == '<label class="option"><input type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option"><input type="checkbox" value="3"/> 3</label>'
    @f.input(:checkboxset, :options=>[[:a, 1], [:b, 2], [:c, 3]], :text_method=>:last, :value_method=>:first, :selected=>:b).to_s.should == '<label class="option"><input type="checkbox" value="a"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="b"/> 2</label><label class="option"><input type="checkbox" value="c"/> 3</label>'
  end

  specify "should support :add_blank option for checkboxset inputs" do
    @f.input(:checkboxset, :options=>[[:b, 2], [:c, 3]], :add_blank=>true, :value=>2).to_s.should == '<label class="option"><input type="checkbox" value=""/> </label><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label><label class="option"><input type="checkbox" value="3"/> c</label>'
  end

  specify "should use :add_blank option value as prompt if it is a String" do
    @f.input(:checkboxset, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).to_s.should == '<label class="option"><input type="checkbox" value=""/> Prompt Here</label><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label><label class="option"><input type="checkbox" value="3"/> c</label>'
  end

  specify "should respect the :key option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :key=>:foo, :value=>2).to_s.should == '<label class="option"><input id="foo_1" name="foo[]" type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" id="foo_2" name="foo[]" type="checkbox" value="2"/> 2</label><label class="option"><input id="foo_3" name="foo[]" type="checkbox" value="3"/> 3</label>'
  end

  specify "should prefer the :name option to :key option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :key=>:foo, :name=>'bar[]', :value=>2).to_s.should == '<label class="option"><input id="foo_1" name="bar[]" type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" id="foo_2" name="bar[]" type="checkbox" value="2"/> 2</label><label class="option"><input id="foo_3" name="bar[]" type="checkbox" value="3"/> 3</label>'
  end

  specify "should prefer the :name and :id option to :key option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :key=>:foo, :name=>'bar[]', :id=>:baz, :value=>2).to_s.should == '<label class="option"><input id="baz_1" name="bar[]" type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" id="baz_2" name="bar[]" type="checkbox" value="2"/> 2</label><label class="option"><input id="baz_3" name="bar[]" type="checkbox" value="3"/> 3</label>'
  end

  specify "should respect the :error option for checkbox sets" do
    @f.input(:checkboxset, :options=>[1, 2, 3], :error=>'foo', :value=>2).to_s.should == '<label class="option"><input type="checkbox" value="1"/> 1</label><label class="option"><input checked="checked" type="checkbox" value="2"/> 2</label><label class="option"><input class="error" type="checkbox" value="3"/> 3</label><span class="error_message">foo</span>'
  end

  specify "should create set of checkbox buttons with fieldsets and legends for optgroups" do
    @f.input(:checkboxset, :optgroups=>[['d', [[:a, 1], [:b, 2]]], ['e', [[:c, 3]]]], :selected=>2).to_s.should == '<fieldset><legend>d</legend><label class="option"><input type="checkbox" value="1"/> a</label><label class="option"><input checked="checked" type="checkbox" value="2"/> b</label></fieldset><fieldset><legend>e</legend><label class="option"><input type="checkbox" value="3"/> c</label></fieldset>'
  end

  specify "should raise an Error for empty checkbox sets" do
    @f.input(:checkboxset, :options=>[], :error=>'foo', :value=>2).to_s.should == '<span class="error_message">foo</span>'
  end

  specify "radio and checkbox inputs should handle :checked option" do
    @f.input(:radio, :checked=>true).to_s.should == '<input checked="checked" type="radio"/>'
    @f.input(:radio, :checked=>false).to_s.should == '<input type="radio"/>'
    @f.input(:checkbox, :checked=>true).to_s.should == '<input checked="checked" type="checkbox"/>'
    @f.input(:checkbox, :checked=>false).to_s.should == '<input type="checkbox"/>'
  end

  specify "inputs should handle :autofocus option" do
    @f.input(:text, :autofocus=>true).to_s.should == '<input autofocus="autofocus" type="text"/>'
    @f.input(:text, :autofocus=>false).to_s.should == '<input type="text"/>'
  end

  specify "inputs should handle :required option" do
    @f.input(:text, :required=>true).to_s.should == '<input required="required" type="text"/>'
    @f.input(:text, :required=>false).to_s.should == '<input type="text"/>'
  end

  specify "inputs should handle :disabled option" do
    @f.input(:text, :disabled=>true).to_s.should == '<input disabled="disabled" type="text"/>'
    @f.input(:text, :disabled=>false).to_s.should == '<input type="text"/>'
  end

  specify "inputs should not include options with nil values" do
    @f.input(:text, :name=>nil).to_s.should == '<input type="text"/>'
    @f.input(:textarea, :name=>nil).to_s.should == '<textarea></textarea>'
  end

  specify "inputs should include options with false values" do
    @f.input(:text, :name=>false).to_s.should == '<input name="false" type="text"/>'
  end

  specify "should automatically create a label if a :label option is used" do
    @f.input(:text, :label=>'Foo', :value=>'foo').to_s.should == '<label>Foo: <input type="text" value="foo"/></label>'
  end

  specify "should set label attributes with :label_attr option" do
    @f.input(:text, :label=>'Foo', :value=>'foo', :label_attr=>{:class=>'bar'}).to_s.should == '<label class="bar">Foo: <input type="text" value="foo"/></label>'
  end

  specify "should handle implicit labels with checkboxes" do
    @f.input(:checkbox, :label=>'Foo', :value=>'foo', :name=>'a').to_s.should == '<input name="a" type="hidden" value="0"/><label><input name="a" type="checkbox" value="foo"/> Foo</label>'
  end

  specify "should handle implicit labels with :label_position=>:after" do
    @f.input(:text, :label=>'Foo', :value=>'foo', :label_position=>:after).to_s.should == '<label><input type="text" value="foo"/> Foo</label>'
  end

  specify "should handle implicit labels with checkboxes with :label_position=>:before" do
    @f.input(:checkbox, :label=>'Foo', :value=>'foo', :name=>'a', :label_position=>:before).to_s.should == '<input name="a" type="hidden" value="0"/><label>Foo <input name="a" type="checkbox" value="foo"/></label>'
  end

  specify "should automatically note the input has errors if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo').to_s.should == '<input class="error" type="text" value="foo"/><span class="error_message">Bad Stuff!</span>'
  end

  specify "should add an error message after the label" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo', :label=>"Foo").to_s.should == '<label>Foo: <input class="error" type="text" value="foo"/></label><span class="error_message">Bad Stuff!</span>'
  end

  specify "should add to existing :class option if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :class=>'bar', :value=>'foo').to_s.should == '<input class="bar error" type="text" value="foo"/><span class="error_message">Bad Stuff!</span>'
  end

  specify "should respect :error_attr option for setting the attributes for the error message span" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo', :error_attr=>{:class=>'foo'}).to_s.should == '<input class="error" type="text" value="foo"/><span class="foo error_message">Bad Stuff!</span>'
  end

  specify "#open should return an opening tag" do
    @f.open(:action=>'foo', :method=>'post').to_s.should == '<form action="foo" method="post">'
  end

  specify "#close should return a closing tag" do
    @f.close.to_s.should == '</form>'
  end

  specify "#button should return a submit tag" do
    @f.button.to_s.should == '<input type="submit"/>'
  end

  specify "#button should accept an options hash" do
    @f.button(:name=>'foo', :value=>'bar').to_s.should == '<input name="foo" type="submit" value="bar"/>'
  end

  specify "#button should accept a string to use as a value" do
    @f.button('foo').to_s.should == '<input type="submit" value="foo"/>'
  end

  specify "#tag should return a serialized_tag" do
    @f.tag(:textarea).to_s.should == '<textarea></textarea>'
    @f.tag(:textarea, :name=>:foo).to_s.should == '<textarea name="foo"></textarea>'
    @f.tag(:textarea, {:name=>:foo}, :bar).to_s.should == '<textarea name="foo">bar</textarea>'
  end

  specify "#tag should accept children as procs" do
    @f.tag(:div, {:class=>"foo"}, lambda{|t| t.form.tag(:input, :class=>t.attr[:class])}).to_s.should == '<div class="foo"><input class="foo"/></div>'
  end

  specify "#tag should accept children as methods" do
    o = Object.new
    def o.foo(t) t.form.tag(:input, :class=>t.attr[:class]) end
    @f.tag(:div, {:class=>"foo"}, o.method(:foo)).to_s.should == '<div class="foo"><input class="foo"/></div>'
  end

  specify "should have an #inputs method for multiple inputs wrapped in a fieldset" do
    @f.inputs([:textarea, :text]).to_s.should == '<fieldset class="inputs"><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have default #inputs method accept an :attr option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs', :attr=>{:class=>'foo', :bar=>'baz'}).to_s.should == '<fieldset bar="baz" class="foo inputs"><legend>Inputs</legend><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have default #inputs method accept a :legend option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs').to_s.should == '<fieldset class="inputs"><legend>Inputs</legend><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have default #inputs method accept a :legend_attr option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs', :legend_attr=>{:class=>'foo'}).to_s.should == '<fieldset class="inputs"><legend class="foo">Inputs</legend><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have an #inputs method take a block and yield to it" do
    @f.inputs{@f.input(:textarea); @f.input(:text)}.to_s.should == '<fieldset class="inputs"><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have an #inputs method work with both args and block" do
    @f.inputs([:textarea]){@f.input(:text)}.to_s.should == '<fieldset class="inputs"><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have an #inputs method support array arguments and creating inputs with the array as argument list" do
    @f.inputs([[:textarea, {:name=>'foo'}], [:text, {:id=>'bar'}]]).to_s.should == '<fieldset class="inputs"><textarea name="foo"></textarea><input id="bar" type="text"/></fieldset>'
  end

  specify "should have #inputs accept transformer options to modify the options inside the inputs" do
    @f.inputs([:textarea, :text], :wrapper=>:div).to_s.should == '<fieldset class="inputs"><div><textarea></textarea></div><div><input type="text"/></div></fieldset>'
  end

  specify "should have #inputs accept :nested_inputs_wrapper options to modify the :input_wrapper option inside the inputs" do
    @f.inputs(:nested_inputs_wrapper=>:div){@f.inputs([:textarea, :text])}.to_s.should == '<fieldset class="inputs"><div><textarea></textarea><input type="text"/></div></fieldset>'
  end

  specify "should escape tag content" do
    @f.tag(:div, {}, ['<p></p>']).to_s.should == '<div>&lt;p&gt;&lt;/p&gt;</div>'
  end

  specify "should not escape raw tag content using Forme::Raw" do
    @f.tag(:div, {}, ['<p></p>'.extend(Forme::Raw)]).to_s.should == '<div><p></p></div>'
  end

  specify "should not escape raw tag content using Forme.raw" do
    @f.tag(:div, {}, [Forme.raw('<p></p>')]).to_s.should == '<div><p></p></div>'
  end

  specify "should not escape raw tag content using Form#raw" do
    @f.tag(:div, {}, [@f.raw('<p></p>')]).to_s.should == '<div><p></p></div>'
  end

  specify "should escape tag content in attribute values" do
    @f.tag(:div, :foo=>'<p></p>').to_s.should == '<div foo="&lt;p&gt;&lt;/p&gt;"></div>'
  end

  specify "should not escape raw tag content in attribute values" do
    @f.tag(:div, :foo=>'<p></p>'.extend(Forme::Raw)).to_s.should == '<div foo="<p></p>"></div>'
  end

  specify "should format dates, times, and datetimes in ISO format" do
    @f.tag(:div, :foo=>Date.new(2011, 6, 5)).to_s.should == '<div foo="2011-06-05"></div>'
    @f.tag(:div, :foo=>DateTime.new(2011, 6, 5, 4, 3, 2)).to_s.should == '<div foo="2011-06-05T04:03:02.000000"></div>'
    @f.tag(:div, :foo=>Time.utc(2011, 6, 5, 4, 3, 2)).to_s.should =~ /<div foo="2011-06-05T04:03:02.000000"><\/div>/
  end

  specify "should format bigdecimals in standard notation" do
    @f.tag(:div, :foo=>BigDecimal.new('10000.010')).to_s.should == '<div foo="10000.01"></div>'
  end

  specify "inputs should accept a :wrapper option to use a custom wrapper" do
    @f.input(:text, :wrapper=>:li).to_s.should == '<li><input type="text"/></li>'
  end

  specify "inputs should accept a :wrapper_attr option to use custom wrapper attributes" do
    @f.input(:text, :wrapper=>:li, :wrapper_attr=>{:class=>"foo"}).to_s.should == '<li class="foo"><input type="text"/></li>'
  end

  specify "inputs should accept a :help option to use custom helper text" do
    @f.input(:text, :help=>"List type of foo").to_s.should == '<input type="text"/><span class="helper">List type of foo</span>'
  end

  specify "inputs should accept a :helper_attr option for custom helper attributes" do
    @f.input(:text, :help=>"List type of foo", :helper_attr=>{:class=>'foo'}).to_s.should == '<input type="text"/><span class="foo helper">List type of foo</span>'
  end

  specify "inputs should have helper displayed inside wrapper, after error" do
    @f.input(:text, :help=>"List type of foo", :error=>'bad', :wrapper=>:li).to_s.should == '<li><input class="error" type="text"/><span class="error_message">bad</span><span class="helper">List type of foo</span></li>'
  end

  specify "inputs should accept a :formatter option to use a custom formatter" do
    @f.input(:text, :formatter=>:readonly, :value=>'1', :label=>'Foo').to_s.should == '<label>Foo: <span>1</span></label>'
    @f.input(:text, :formatter=>:default, :value=>'1', :label=>'Foo').to_s.should == '<label>Foo: <input type="text" value="1"/></label>'
  end

  specify "inputs should accept a :labeler option to use a custom labeler" do
    @f.input(:textarea, :labeler=>:explicit, :label=>'bar', :id=>:foo).to_s.should == '<label class="label-before" for="foo">bar</label><textarea id="foo"></textarea>'
  end

  specify "inputs handle explicit labels with :label_position=>:after" do
    @f.input(:textarea, :labeler=>:explicit, :label=>'bar', :id=>:foo, :label_position=>:after).to_s.should == '<textarea id="foo"></textarea><label class="label-after" for="foo">bar</label>'
  end

  specify "should handle explicit labels with checkboxes" do
    @f.input(:checkbox, :labeler=>:explicit, :label=>'Foo', :value=>'foo', :name=>'a', :id=>'bar').to_s.should == '<input id="bar_hidden" name="a" type="hidden" value="0"/><input id="bar" name="a" type="checkbox" value="foo"/><label class="label-after" for="bar">Foo</label>'
  end

  specify "should handle explicit labels with checkboxes with :label_position=>:before" do
    @f.input(:checkbox, :labeler=>:explicit, :label=>'Foo', :value=>'foo', :name=>'a', :id=>'bar', :label_position=>:before).to_s.should == '<label class="label-before" for="bar">Foo</label><input id="bar_hidden" name="a" type="hidden" value="0"/><input id="bar" name="a" type="checkbox" value="foo"/>'
  end

  specify "inputs handle implicit labels or checkboxes without hidden fields with :label_position=>:before" do
    @f.input(:checkbox, :label=>'Foo', :value=>'foo', :name=>'a', :id=>'bar', :label_position=>:before, :no_hidden=>true).to_s.should == '<label>Foo <input id="bar" name="a" type="checkbox" value="foo"/></label>'
  end

  specify "inputs should accept a :error_handler option to use a custom error_handler" do
    @f.input(:textarea, :error_handler=>proc{|t, i| [t, "!!! #{i.opts[:error]}"]}, :error=>'bar', :id=>:foo).to_s.should == '<textarea class="error" id="foo"></textarea>!!! bar'
  end

  specify "#inputs should accept a :inputs_wrapper option to use a custom inputs_wrapper" do
    @f.inputs([:textarea], :inputs_wrapper=>:ol).to_s.should == '<ol><textarea></textarea></ol>'
  end

  specify "inputs should accept a :wrapper=>nil option to not use a wrapper" do
    Forme::Form.new(:wrapper=>:li).input(:text, :wrapper=>nil).to_s.should == '<input type="text"/>'
  end

  specify "inputs should accept a :labeler=>nil option to not use a labeler" do
    @f.input(:textarea, :labeler=>nil, :label=>'bar', :id=>:foo).to_s.should == '<textarea id="foo"></textarea>'
  end

  specify "inputs should accept a :error_handler=>nil option to not use an error_handler" do
    @f.input(:textarea, :error_handler=>nil, :error=>'bar', :id=>:foo).to_s.should == '<textarea class="error" id="foo"></textarea>'
  end

  specify "#inputs should accept a :inputs_wrapper=>nil option to not use an inputs_wrapper" do
    @f.form{|f| f.inputs([:textarea], :inputs_wrapper=>nil)}.to_s.should == '<form><textarea></textarea></form>'
  end

  specify "#inputs should treat a single hash argument as an options hash with no default inputs" do
    @f.inputs(:inputs_wrapper=>:ol){@f.input(:textarea)}.to_s.should == '<ol><textarea></textarea></ol>'
  end

  specify "should support setting defaults for inputs at the form level" do
    f = Forme::Form.new(:input_defaults=>{'text'=>{:size=>20}, 'textarea'=>{:cols=>80, :rows=>6}})
    f.input(:text, :name=>"foo").to_s.should == '<input name="foo" size="20" type="text"/>'
    f.input(:textarea, :name=>"foo").to_s.should == '<textarea cols="80" name="foo" rows="6"></textarea>'
  end

  specify "should work with input_defaults with symbol keys using using inputs with symbol keys" do
    f = Forme::Form.new(:input_defaults=>{:text=>{:size=>20}, 'text'=>{:size=>30}})
    f.input(:text, :name=>"foo").to_s.should == '<input name="foo" size="20" type="text"/>'
    f.input('text', :name=>"foo").to_s.should == '<input name="foo" size="30" type="text"/>'
  end

  specify "invalid custom transformers should raise an Error" do
    proc{Forme::Form.new(:wrapper=>Object.new).input(:text).to_s}.should raise_error(Forme::Error)
    proc{@f.input(:textarea, :wrapper=>Object.new).to_s}.should raise_error(Forme::Error)
    proc{@f.input(:textarea, :formatter=>nil).to_s}.should raise_error(Forme::Error)
  end
end

describe "Forme::Form :hidden_tags option " do
  before do
    @f = Forme::Form.new
  end

  specify "should handle hash" do
    Forme.form({}, :hidden_tags=>[{:a=>'b'}]).to_s.should == '<form><input name="a" type="hidden" value="b"/></form>'
  end

  specify "should handle array" do
    Forme.form({}, :hidden_tags=>[["a ", "b"]]).to_s.should == '<form>a b</form>'
  end

  specify "should handle string" do
    Forme.form({}, :hidden_tags=>["a "]).to_s.should == '<form>a </form>'
  end

  specify "should handle proc return hash" do
    Forme.form({}, :hidden_tags=>[lambda{|tag| {:a=>'b'}}]).to_s.should == '<form><input name="a" type="hidden" value="b"/></form>'
  end

  specify "should handle proc return tag" do
    Forme.form({:method=>'post'}, :hidden_tags=>[lambda{|tag| tag.form._tag(tag.attr[:method])}]).to_s.should == '<form method="post"><post></post></form>'
  end

  specify "should raise error for unhandled object" do
    proc{Forme.form({}, :hidden_tags=>[Object.new])}.should raise_error
  end
end

describe "Forme custom" do
  specify "formatters can be specified as a proc" do
    Forme::Form.new(:formatter=>proc{|i| i.form._tag(:textarea, i.opts[:name]=>:name)}).input(:text, :name=>'foo').to_s.should == '<textarea foo="name"></textarea>'
  end

  specify "serializers can be specified as a proc" do
    Forme::Form.new(:serializer=>proc{|t| "#{t.type} = #{t.opts[:name]}"}).input(:textarea, :name=>'foo').to_s.should == 'textarea = foo'
  end

  specify "labelers can be specified as a proc" do
    Forme::Form.new(:labeler=>proc{|t, i| ["#{i.opts[:label]}: ", t]}).input(:textarea, :name=>'foo', :label=>'bar').to_s.should == 'bar: <textarea name="foo"></textarea>'
  end

  specify "error_handlers can be specified as a proc" do
    Forme::Form.new(:error_handler=>proc{|t, i| [t, "!!! #{i.opts[:error]}"]}).input(:textarea, :name=>'foo', :error=>'bar').to_s.should == '<textarea class="error" name="foo"></textarea>!!! bar'
  end

  specify "wrappers can be specified as a proc" do
    Forme::Form.new(:wrapper=>proc{|t, i| t.tag(:div, {:bar=>i.opts[:name]}, t)}).input(:textarea, :name=>'foo').to_s.should == '<div bar="foo"><textarea name="foo"></textarea></div>'
  end

  specify "inputs_wrappers can be specified as a proc" do
    Forme::Form.new(:inputs_wrapper=>proc{|f, opts, &block| f.tag(:div, &block)}).inputs([:textarea]).to_s.should == '<div><textarea></textarea></div>'
  end

  specify "can use nil as value to disable default transformer" do
    Forme::Form.new(:labeler=>nil).input(:textarea, :label=>'foo').to_s.should == '<textarea></textarea>'
  end
end

describe "Forme built-in custom" do
  specify "transformers should raise if the there is no matching transformer" do
    proc{Forme::Form.new(:formatter=>:foo).input(:text).to_s}.should raise_error(Forme::Error)
  end

  specify "formatter: disabled disables all inputs unless :disabled=>false option" do
    Forme::Form.new(:formatter=>:disabled).input(:textarea).to_s.should == '<textarea disabled="disabled"></textarea>'
    Forme::Form.new(:formatter=>:disabled).input(:textarea, :disabled=>false).to_s.should == '<textarea></textarea>'
  end

  specify "formatter: readonly uses spans for most input fields and disables radio/checkbox fields" do
    Forme::Form.new(:formatter=>:readonly).input(:textarea, :label=>"Foo", :value=>"Bar").to_s.should == "<label>Foo: <span>Bar</span></label>"
    Forme::Form.new(:formatter=>:readonly).input(:text, :label=>"Foo", :value=>"Bar").to_s.should == "<label>Foo: <span>Bar</span></label>"
    Forme::Form.new(:formatter=>:readonly).input(:radio, :label=>"Foo", :value=>"Bar").to_s.should == "<label><input disabled=\"disabled\" type=\"radio\" value=\"Bar\"/> Foo</label>"
    Forme::Form.new(:formatter=>:readonly).input(:radio, :label=>"Foo", :value=>"Bar", :checked=>true).to_s.should == "<label><input checked=\"checked\" disabled=\"disabled\" type=\"radio\" value=\"Bar\"/> Foo</label>"
    Forme::Form.new(:formatter=>:readonly).input(:checkbox, :label=>"Foo", :value=>"Bar").to_s.should == "<label><input disabled=\"disabled\" type=\"checkbox\" value=\"Bar\"/> Foo</label>"
    Forme::Form.new(:formatter=>:readonly).input(:checkbox, :label=>"Foo", :value=>"Bar", :checked=>true).to_s.should == "<label><input checked=\"checked\" disabled=\"disabled\" type=\"checkbox\" value=\"Bar\"/> Foo</label>"
    Forme::Form.new(:formatter=>:readonly).input(:select, :label=>"Foo", :options=>[1, 2, 3], :value=>2).to_s.should == "<label>Foo: <span>2</span></label>"
  end

  specify "labeler: explicit uses an explicit label with for attribute" do
    Forme::Form.new(:labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'bar').to_s.should == '<label class="label-before" for="foo">bar</label><textarea id="foo"></textarea>'
  end

  specify "labeler: explicit handles the key option correctly" do
    Forme::Form.new(:labeler=>:explicit, :namespace=>:baz).input(:textarea, :key=>'foo', :label=>'bar').to_s.should == '<label class="label-before" for="baz_foo">bar</label><textarea id="baz_foo" name="baz[foo]"></textarea>'
  end

  specify "labeler: explicit should handle tags with errors" do
    Forme::Form.new(:labeler=>:explicit).input(:text, :error=>'Bad Stuff!', :value=>'f', :id=>'foo', :label=>'bar').to_s.should == '<label class="label-before" for="foo">bar</label><input class="error" id="foo" type="text" value="f"/><span class="error_message">Bad Stuff!</span>'
  end

  specify "wrapper: li wraps tag in an li" do
    Forme::Form.new(:wrapper=>:li).input(:textarea, :id=>'foo').to_s.should == '<li><textarea id="foo"></textarea></li>'
    Forme::Form.new(:wrapper=>:li).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).to_s.should == '<li id="bar"><textarea id="foo"></textarea></li>'
  end

  specify "wrapper: p wraps tag in an p" do
    Forme::Form.new(:wrapper=>:p).input(:textarea, :id=>'foo').to_s.should == '<p><textarea id="foo"></textarea></p>'
    Forme::Form.new(:wrapper=>:p).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).to_s.should == '<p id="bar"><textarea id="foo"></textarea></p>'
  end

  specify "wrapper: div wraps tag in an div" do
    Forme::Form.new(:wrapper=>:div).input(:textarea, :id=>'foo').to_s.should == '<div><textarea id="foo"></textarea></div>'
    Forme::Form.new(:wrapper=>:div).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).to_s.should == '<div id="bar"><textarea id="foo"></textarea></div>'
  end

  specify "wrapper: span wraps tag in an span" do
    Forme::Form.new(:wrapper=>:span).input(:textarea, :id=>'foo').to_s.should == '<span><textarea id="foo"></textarea></span>'
    Forme::Form.new(:wrapper=>:span).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).to_s.should == '<span id="bar"><textarea id="foo"></textarea></span>'
  end

  specify "wrapper: td wraps tag in an td" do
    Forme::Form.new(:wrapper=>:td).input(:textarea, :id=>'foo').to_s.should == '<td><textarea id="foo"></textarea></td>'
    Forme::Form.new(:wrapper=>:td).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).to_s.should == '<td id="bar"><textarea id="foo"></textarea></td>'
  end

  specify "wrapper: trtd wraps tag in an tr/td" do
    Forme::Form.new(:wrapper=>:trtd).input(:textarea, :id=>'foo').to_s.should == '<tr><td><textarea id="foo"></textarea></td><td></td></tr>'
    Forme::Form.new(:wrapper=>:trtd).input(:textarea, :id=>'foo', :wrapper_attr=>{:id=>'bar'}).to_s.should == '<tr id="bar"><td><textarea id="foo"></textarea></td><td></td></tr>'
  end

  specify "wrapper: trtd supports multiple tags in separate tds" do
    Forme::Form.new(:wrapper=>:trtd, :labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'Foo').to_s.should == '<tr><td><label class="label-before" for="foo">Foo</label></td><td><textarea id="foo"></textarea></td></tr>'
  end

  specify "wrapper: trtd should use at most 2 td tags" do
    Forme::Form.new(:wrapper=>:trtd, :labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'Foo', :error=>'Bar').to_s.should == '<tr><td><label class="label-before" for="foo">Foo</label></td><td><textarea class="error" id="foo"></textarea><span class="error_message">Bar</span></td></tr>'
  end

  specify "wrapper: trtd should handle inputs with label after" do
    Forme::Form.new(:wrapper=>:trtd, :labeler=>:explicit).input(:checkbox, :id=>'foo', :name=>'foo', :label=>'Foo').to_s.should == '<tr><td><label class="label-after" for="foo">Foo</label></td><td><input id="foo_hidden" name="foo" type="hidden" value="0"/><input id="foo" name="foo" type="checkbox"/></td></tr>'
  end

  specify "wrapper: tr should use a td wrapper and tr inputs_wrapper" do
    Forme::Form.new(:wrapper=>:tr).inputs([:textarea]).to_s.should == '<tr><td><textarea></textarea></td></tr>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:tr){f.inputs([:textarea])}.to_s.should == '<tr><td><textarea></textarea></td></tr>'
  end

  specify "wrapper: table should use a trtd wrapper and table inputs_wrapper" do
    Forme::Form.new(:wrapper=>:table).inputs([:textarea]).to_s.should == '<table><tr><td><textarea></textarea></td><td></td></tr></table>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:table){f.inputs([:textarea])}.to_s.should == '<table><tr><td><textarea></textarea></td><td></td></tr></table>'
  end

  specify "wrapper: ol should use an li wrapper and ol inputs_wrapper" do
    Forme::Form.new(:wrapper=>:ol).inputs([:textarea]).to_s.should == '<ol><li><textarea></textarea></li></ol>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:ol){f.inputs([:textarea])}.to_s.should == '<ol><li><textarea></textarea></li></ol>'
  end

  specify "wrapper: fieldset_ol should use an li wrapper and fieldset_ol inputs_wrapper" do
    Forme::Form.new(:wrapper=>:fieldset_ol).inputs([:textarea]).to_s.should == '<fieldset class="inputs"><ol><li><textarea></textarea></li></ol></fieldset>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:fieldset_ol){f.inputs([:textarea])}.to_s.should == '<fieldset class="inputs"><ol><li><textarea></textarea></li></ol></fieldset>'
  end

  specify "wrapper should not override inputs_wrapper if both given" do
    Forme::Form.new(:wrapper=>:tr, :inputs_wrapper=>:div).inputs([:textarea]).to_s.should == '<div><td><textarea></textarea></td></div>'
    f = Forme::Form.new
    f.with_opts(:wrapper=>:tr, :inputs_wrapper=>:div){f.inputs([:textarea])}.to_s.should == '<div><td><textarea></textarea></td></div>'
  end

  specify "inputs_wrapper: ol wraps tags in an ol" do
    Forme::Form.new(:inputs_wrapper=>:ol, :wrapper=>:li).inputs([:textarea]).to_s.should == '<ol><li><textarea></textarea></li></ol>'
    Forme::Form.new(:inputs_wrapper=>:ol, :wrapper=>:li).inputs([:textarea], :attr=>{:foo=>1}).to_s.should == '<ol foo="1"><li><textarea></textarea></li></ol>'
  end

  specify "inputs_wrapper: fieldset_ol wraps tags in a fieldset and an ol" do
    Forme::Form.new(:inputs_wrapper=>:fieldset_ol, :wrapper=>:li).inputs([:textarea]).to_s.should == '<fieldset class="inputs"><ol><li><textarea></textarea></li></ol></fieldset>'
    Forme::Form.new(:inputs_wrapper=>:fieldset_ol, :wrapper=>:li).inputs([:textarea], :attr=>{:foo=>1}).to_s.should == '<fieldset class="inputs" foo="1"><ol><li><textarea></textarea></li></ol></fieldset>'
  end

  specify "inputs_wrapper: fieldset_ol supports a :legend option" do
    Forme.form({}, :inputs_wrapper=>:fieldset_ol, :wrapper=>:li, :legend=>'Foo', :inputs=>[:textarea]).to_s.should == '<form><fieldset class="inputs"><legend>Foo</legend><ol><li><textarea></textarea></li></ol></fieldset></form>'
  end

  specify "inputs_wrapper: div wraps tags in a div" do
    Forme::Form.new(:inputs_wrapper=>:div, :wrapper=>:span).inputs([:textarea]).to_s.should == '<div><span><textarea></textarea></span></div>'
    Forme::Form.new(:inputs_wrapper=>:div, :wrapper=>:span).inputs([:textarea], :attr=>{:foo=>1}).to_s.should == '<div foo="1"><span><textarea></textarea></span></div>'
  end

  specify "inputs_wrapper: tr wraps tags in an tr" do
    Forme::Form.new(:inputs_wrapper=>:tr, :wrapper=>:td).inputs([:textarea]).to_s.should == '<tr><td><textarea></textarea></td></tr>'
    Forme::Form.new(:inputs_wrapper=>:tr, :wrapper=>:td).inputs([:textarea], :attr=>{:foo=>1}).to_s.should == '<tr foo="1"><td><textarea></textarea></td></tr>'
  end

  specify "inputs_wrapper: table wraps tags in an table" do
    Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs([:textarea]).to_s.should == '<table><tr><td><textarea></textarea></td><td></td></tr></table>'
    Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs([:textarea], :attr=>{:foo=>1}).to_s.should == '<table foo="1"><tr><td><textarea></textarea></td><td></td></tr></table>'
  end

  specify "inputs_wrapper: table accepts a :legend option" do
   Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs([:textarea], :legend=>'Inputs').to_s.should == '<table><caption>Inputs</caption><tr><td><textarea></textarea></td><td></td></tr></table>'
  end

  specify "inputs_wrapper: table accepts a :legend_attr option" do
    Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs([:textarea], :legend=>'Inputs', :legend_attr=>{:class=>'foo'}).to_s.should == '<table><caption class="foo">Inputs</caption><tr><td><textarea></textarea></td><td></td></tr></table>'
  end

  specify "inputs_wrapper: table accepts a :labels option" do
    Forme::Form.new(:inputs_wrapper=>:table).inputs(:labels=>%w'A B C').to_s.should == '<table><tr><th>A</th><th>B</th><th>C</th></tr></table>'
  end

  specify "inputs_wrapper: table doesn't add empty header row for :labels=>[]" do
    Forme::Form.new(:inputs_wrapper=>:table).inputs(:labels=>[]).to_s.should == '<table></table>'
  end

  specify "serializer: html_usa formats dates and datetimes in American format without timezones" do
    Forme::Form.new(:serializer=>:html_usa).tag(:div, :foo=>Date.new(2011, 6, 5)).to_s.should == '<div foo="06/05/2011"></div>'
    Forme::Form.new(:serializer=>:html_usa).tag(:div, :foo=>DateTime.new(2011, 6, 5, 16, 3, 2)).to_s.should == '<div foo="06/05/2011 04:03:02PM"></div>'
    Forme::Form.new(:serializer=>:html_usa).tag(:div, :foo=>Time.utc(2011, 6, 5, 4, 3, 2)).to_s.should == '<div foo="06/05/2011 04:03:02AM"></div>'
  end

  specify "serializer: html_usa should convert date and datetime inputs into text inputs" do
    Forme::Form.new(:serializer=>:html_usa).input(:date, :value=>Date.new(2011, 6, 5)).to_s.should == '<input type="text" value="06/05/2011"/>'
    Forme::Form.new(:serializer=>:html_usa).input(:datetime, :value=>DateTime.new(2011, 6, 5, 16, 3, 2)).to_s.should == '<input type="text" value="06/05/2011 04:03:02PM"/>'
  end

  specify "serializer: text uses plain text output instead of html" do
    Forme::Form.new(:serializer=>:text).input(:textarea, :label=>"Foo", :value=>"Bar").to_s.should == "Foo: Bar\n\n"
    Forme::Form.new(:serializer=>:text).input(:text, :label=>"Foo", :value=>"Bar").to_s.should == "Foo: Bar\n\n"
    Forme::Form.new(:serializer=>:text).input(:radio, :label=>"Foo", :value=>"Bar").to_s.should == "___ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:radio, :label=>"Foo", :value=>"Bar", :checked=>true).to_s.should == "_X_ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:checkbox, :label=>"Foo", :value=>"Bar").to_s.should == "___ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:checkbox, :label=>"Foo", :value=>"Bar", :checked=>true).to_s.should == "_X_ Foo\n"
    Forme::Form.new(:serializer=>:text).input(:select, :label=>"Foo", :options=>[1, 2, 3], :value=>2).to_s.should == "Foo: \n___ 1\n_X_ 2\n___ 3\n\n"
    Forme::Form.new(:serializer=>:text).input(:password, :label=>"Pass").to_s.should == "Pass: ********\n\n"
    Forme::Form.new(:serializer=>:text).button().to_s.should == ""
    Forme::Form.new(:serializer=>:text).inputs([[:textarea, {:label=>"Foo", :value=>"Bar"}]], :legend=>'Baz').to_s.should == "Baz\n---\nFoo: Bar\n\n"
    Forme::Form.new(:serializer=>:text).tag(:p){|f| f.input(:textarea, :label=>"Foo", :value=>"Bar")}.to_s.should == "Foo: Bar\n\n"
  end
end

describe "Forme registering custom transformers" do
  specify "should have #register_transformer register a transformer object for later use" do
    Forme.register_transformer(:wrapper, :div2, proc{|t, i| i.tag(:div2, {}, [t])})
    Forme::Form.new(:wrapper=>:div2).input(:textarea).to_s.should == '<div2><textarea></textarea></div2>'
  end

  specify "should have #register_transformer register a transformer block for later use" do
    Forme.register_transformer(:wrapper, :div1){|t, i| i.tag(:div1, {}, [t])}
    Forme::Form.new(:wrapper=>:div1).input(:textarea).to_s.should == '<div1><textarea></textarea></div1>'
  end

  specify "should have #register_transformer raise an error if given a block and an object" do
    proc do
      Forme.register_transformer(:wrapper, :div1, proc{|t, i| t}){|t, i| i.tag(:div1, {}, [t])}
    end.should raise_error(Forme::Error)
  end
end

describe "Forme configurations" do
  after do
    Forme.default_config = :default
  end

  specify "config: :formastic uses fieldset_ol inputs_wrapper and li wrapper, and explicit labeler" do
    Forme::Form.new(:config=>:formtastic).inputs([[:textarea, {:id=>:foo, :label=>'Foo'}]]).to_s.should == '<fieldset class="inputs"><ol><li><label class="label-before" for="foo">Foo</label><textarea id="foo"></textarea></li></ol></fieldset>'
  end

  specify "should be able to set a default configuration with Forme.default_config=" do
    Forme.default_config = :formtastic
    Forme::Form.new.inputs([[:textarea, {:id=>:foo, :label=>'Foo'}]]).to_s.should == '<fieldset class="inputs"><ol><li><label class="label-before" for="foo">Foo</label><textarea id="foo"></textarea></li></ol></fieldset>'
  end

  specify "should have #register_config register a configuration for later use" do
    Forme.register_config(:foo, :wrapper=>:li, :labeler=>:explicit)
    Forme::Form.new(:config=>:foo).input(:textarea, :id=>:foo, :label=>'Foo').to_s.should == '<li><label class="label-before" for="foo">Foo</label><textarea id="foo"></textarea></li>'
  end

  specify "should have #register_config support a :base option to base it on an existing config" do
    Forme.register_config(:foo2, :labeler=>:default, :base=>:formtastic)
    Forme::Form.new(:config=>:foo2).inputs([[:textarea, {:id=>:foo, :label=>'Foo'}]]).to_s.should == '<fieldset class="inputs"><ol><li><label>Foo: <textarea id="foo"></textarea></label></li></ol></fieldset>'
  end

end

describe "Forme object forms" do
  specify "should handle a simple case" do
    obj = Class.new{def forme_input(form, field, opts) form._input(:text, :name=>"obj[#{field}]", :id=>"obj_#{field}", :value=>"#{field}_foo") end}.new 
    Forme::Form.new(obj).input(:field).to_s.should ==  '<input id="obj_field" name="obj[field]" type="text" value="field_foo"/>'
  end

  specify "should handle more complex case with multiple different types and opts" do
    obj = Class.new do 
      def self.name() "Foo" end

      attr_reader :x, :y

      def initialize(x, y)
        @x, @y = x, y
      end
      def forme_input(form, field, opts={})
        t = opts[:type]
        t ||= (field == :x ? :textarea : :text)
        s = field.to_s
        form._input(t, {:label=>s.upcase, :name=>"foo[#{s}]", :id=>"foo_#{s}", :value=>send(field)}.merge!(opts))
      end
    end.new('&foo', 3)
    f = Forme::Form.new(obj)
    f.input(:x).to_s.should == '<label>X: <textarea id="foo_x" name="foo[x]">&amp;foo</textarea></label>'
    f.input(:y, :attr=>{:brain=>'no'}).to_s.should == '<label>Y: <input brain="no" id="foo_y" name="foo[y]" type="text" value="3"/></label>'
  end

  specify "should handle case where obj doesn't respond to forme_input" do
    Forme::Form.new([:foo]).input(:first).to_s.should ==  '<input id="first" name="first" type="text" value="foo"/>'
    obj = Class.new{attr_accessor :foo}.new
    obj.foo = 'bar'
    Forme::Form.new(obj).input(:foo).to_s.should ==  '<input id="foo" name="foo" type="text" value="bar"/>'
  end

  specify "should respect opts hash when obj doesn't respond to forme_input" do
    Forme::Form.new([:foo]).input(:first, :name=>'bar').to_s.should ==  '<input id="first" name="bar" type="text" value="foo"/>'
    Forme::Form.new([:foo]).input(:first, :id=>'bar').to_s.should ==  '<input id="bar" name="first" type="text" value="foo"/>'
    Forme::Form.new([:foo]).input(:first, :value=>'bar').to_s.should ==  '<input id="first" name="first" type="text" value="bar"/>'
    Forme::Form.new([:foo]).input(:first, :attr=>{:x=>'bar'}).to_s.should ==  '<input id="first" name="first" type="text" value="foo" x="bar"/>'
  end

  specify "should respect current namespace" do
    Forme::Form.new([:foo], :namespace=>'a').input(:first).to_s.should ==  '<input id="a_first" name="a[first]" type="text" value="foo"/>'
  end

  specify "should get values for hashes using #[]" do
    Forme::Form.new(:obj=>{:bar=>:foo}, :namespace=>'a').input(:bar).to_s.should ==  '<input id="a_bar" name="a[bar]" type="text" value="foo"/>'
  end

  specify "should handle obj passed in via :obj hash key" do
    Forme::Form.new(:obj=>[:foo]).input(:first).to_s.should ==  '<input id="first" name="first" type="text" value="foo"/>'
  end

  specify "should be able to turn off obj handling per input using :obj=>nil option" do
    Forme::Form.new([:foo]).input(:checkbox, :name=>"foo", :hidden_value=>"no", :obj=>nil).to_s.should == '<input name="foo" type="hidden" value="no"/><input name="foo" type="checkbox"/>'
  end
end

describe "Forme.form DSL" do
  specify "should return a form tag" do
    Forme.form.to_s.should ==  '<form></form>'
  end

  specify "should yield a Form object to the block" do
    Forme.form{|f| f.should be_a_kind_of(Forme::Form)}
  end

  specify "should respect an array of classes" do
    Forme.form(:class=>[:foo, :bar]).to_s.should ==  '<form class="foo bar"></form>'
    Forme.form(:class=>[:foo, [:bar, :baz]]).to_s.should ==  '<form class="foo bar baz"></form>'
  end

  specify "should have inputs called instead the block be added to the existing form" do
    Forme.form{|f| f.input(:text)}.to_s.should ==  '<form><input type="text"/></form>'
  end

  specify "should be able to nest inputs inside tags" do
    Forme.form{|f| f.tag(:div){f.input(:text)}}.to_s.should ==  '<form><div><input type="text"/></div></form>'
    Forme.form{|f| f.tag(:div){f.tag(:fieldset){f.input(:text)}}}.to_s.should ==  '<form><div><fieldset><input type="text"/></fieldset></div></form>'
    Forme.form{|f| f.tag(:div){f.tag(:fieldset){f.tag(:span){f.input(:text)}}}}.to_s.should ==  '<form><div><fieldset><span><input type="text"/></span></fieldset></div></form>'
    Forme.form{|f| f.tag(:div){f.input(:text)}; f.input(:radio)}.to_s.should ==  '<form><div><input type="text"/></div><input type="radio"/></form>'
    Forme.form{|f| f.tag(:div){f.tag(:fieldset){f.input(:text);  f.input(:radio)};  f.input(:checkbox)}}.to_s.should ==  '<form><div><fieldset><input type="text"/><input type="radio"/></fieldset><input type="checkbox"/></div></form>'
  end

  specify "should handle an :inputs option to automatically create inputs" do
    Forme.form({}, :inputs=>[:text, :textarea]).to_s.should ==  '<form><fieldset class="inputs"><input type="text"/><textarea></textarea></fieldset></form>'
  end

  specify "should handle a :legend option if inputs is used" do
    Forme.form({}, :inputs=>[:text, :textarea], :legend=>'Foo').to_s.should ==  '<form><fieldset class="inputs"><legend>Foo</legend><input type="text"/><textarea></textarea></fieldset></form>'
  end

  specify "should still work with a block if :inputs is used" do
    Forme.form({}, :inputs=>[:text]){|f| f.input(:textarea)}.to_s.should ==  '<form><fieldset class="inputs"><input type="text"/></fieldset><textarea></textarea></form>'
  end

  specify "should handle an :button option to automatically create a button" do
    Forme.form({}, :button=>'Foo').to_s.should ==  '<form><input type="submit" value="Foo"/></form>'
  end

  specify "should allow :button option value to be a hash" do
    Forme.form({}, :button=>{:value=>'Foo', :name=>'bar'}).to_s.should ==  '<form><input name="bar" type="submit" value="Foo"/></form>'
  end

  specify "should handle an :button option work with a block" do
    Forme.form({}, :button=>'Foo'){|f| f.input(:textarea)}.to_s.should ==  '<form><textarea></textarea><input type="submit" value="Foo"/></form>'
  end

  specify "should have an :button and :inputs option work together" do
    Forme.form({}, :inputs=>[:text, :textarea], :button=>'Foo').to_s.should ==  '<form><fieldset class="inputs"><input type="text"/><textarea></textarea></fieldset><input type="submit" value="Foo"/></form>'
  end

end

