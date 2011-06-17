require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')
require 'date'

describe "Forme plain forms" do
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
  end

  specify "should create select tag" do
    @f.input(:select).to_s.should == '<select></select>'
  end

  specify "should create date tag" do
    @f.input(:date).to_s.should == '<input type="date"/>'
  end

  specify "should not error for input type :input" do
    @f.input(:input).to_s.should == '<input type="input"/>'
  end

  specify "should use multiple select boxes for dates if the :as=>:select option is given" do
    pr = Proc.new{|a, v| a.map{|o| "<option #{'selected="selected" ' if o == v}value=\"#{o}\">#{o}</option>"}.join}
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5)).to_s.should == %{<select id="bar_year" name="foo[year]">#{pr[1900..2050, 2011]}</select><select id="bar_month" name="foo[month]">#{pr[1..12, 6]}</select><select id="bar_day" name="foo[day]">#{pr[1..31, 5]}</select>}
  end

  specify "should have explicit labeler and trtd wrapper work with multiple select boxes for dates" do
    pr = Proc.new{|a, v| a.map{|o| "<option #{'selected="selected" ' if o == v}value=\"#{o}\">#{o}</option>"}.join}
    @f.input(:date, :name=>"foo", :id=>"bar", :as=>:select, :value=>Date.new(2011, 6, 5), :wrapper=>:trtd, :labeler=>:explicit, :label=>'Baz').to_s.should == %{<tr><td><label for="bar_year">Baz</label></td><td><select id="bar_year" name="foo[year]">#{pr[1900..2050, 2011]}</select><select id="bar_month" name="foo[month]">#{pr[1..12, 6]}</select><select id="bar_day" name="foo[day]">#{pr[1..31, 5]}</select></td></tr>}
  end

  specify "should create select tag with options" do
    @f.input(:select, :options=>[1, 2, 3], :selected=>2).to_s.should == '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
    @f.input(:select, :options=>[1, 2, 3], :value=>2).to_s.should == '<select><option>1</option><option selected="selected">2</option><option>3</option></select>'
  end

  specify "should create select tag with options and values" do
    @f.input(:select, :options=>[[:a, 1], [:b, 2], [:c, 3]], :selected=>2).to_s.should == '<select><option value="1">a</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
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

  specify "should use :add_blank option value as prompt if it is a String" do
    @f.input(:select, :options=>[[:b, 2], [:c, 3]], :add_blank=>"Prompt Here", :value=>2).to_s.should == '<select><option value="">Prompt Here</option><option selected="selected" value="2">b</option><option value="3">c</option></select>'
  end

  specify "radio and checkbox inputs should handle :checked option" do
    @f.input(:radio, :checked=>true).to_s.should == '<input checked="checked" type="radio"/>'
    @f.input(:radio, :checked=>false).to_s.should == '<input type="radio"/>'
    @f.input(:checkbox, :checked=>true).to_s.should == '<input checked="checked" type="checkbox"/>'
    @f.input(:checkbox, :checked=>false).to_s.should == '<input type="checkbox"/>'
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

  specify "should automatically note the input has errors if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :value=>'foo').to_s.should == '<input class="error" type="text" value="foo"/><span class="error_message">Bad Stuff!</span>'
  end

  specify "should add to existing :class option if :error option is used" do
    @f.input(:text, :error=>'Bad Stuff!', :class=>'bar', :value=>'foo').to_s.should == '<input class="bar error" type="text" value="foo"/><span class="error_message">Bad Stuff!</span>'
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

  specify "should have an #inputs method for multiple inputs wrapped in a fieldset" do
    @f.inputs([:textarea, :text]).to_s.should == '<fieldset><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have default #inputs method accept a :legend option" do
    @f.inputs([:textarea, :text], :legend=>'Inputs').to_s.should == '<fieldset><legend>Inputs</legend><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have an #inputs method take a block and yield to it" do
    @f.inputs{@f.input(:textarea); @f.input(:text)}.to_s.should == '<fieldset><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have an #inputs method work with both args and block" do
    @f.inputs([:textarea]){@f.input(:text)}.to_s.should == '<fieldset><textarea></textarea><input type="text"/></fieldset>'
  end

  specify "should have an #inputs method support array arguments and creating inputs with the array as argument list" do
    @f.inputs([[:textarea, {:name=>'foo'}], [:text, {:id=>'bar'}]]).to_s.should == '<fieldset><textarea name="foo"></textarea><input id="bar" type="text"/></fieldset>'
  end

  specify "should escape tag content" do
    @f.tag(:div, {}, ['<p></p>']).to_s.should == '<div>&lt;p&gt;&lt;/p&gt;</div>'
  end

  specify "should not escape raw tag content" do
    @f.tag(:div, {}, ['<p></p>'.extend(Forme::Raw)]).to_s.should == '<div><p></p></div>'
  end

  specify "should escape tag content in attribute values" do
    @f.tag(:div, :foo=>'<p></p>').to_s.should == '<div foo="&lt;p&gt;&lt;/p&gt;"></div>'
  end

  specify "should not escape raw tag content in attribute values" do
    @f.tag(:div, :foo=>'<p></p>'.extend(Forme::Raw)).to_s.should == '<div foo="<p></p>"></div>'
  end

  specify "should format dates, times, and datetimes in ISO format" do
    @f.tag(:div, :foo=>Date.new(2011, 6, 5)).to_s.should == '<div foo="2011-06-05"></div>'
    @f.tag(:div, :foo=>DateTime.new(2011, 6, 5, 4, 3, 2)).to_s.should == '<div foo="2011-06-05 04:03:02+00:00"></div>'
    @f.tag(:div, :foo=>Time.utc(2011, 6, 5, 4, 3, 2)).to_s.should =~ /<div foo="2011-06-05 04:03:02(GMT|UTC)"><\/div>/
  end

  specify "inputs should accept a :wrapper option to use a custom wrapper" do
    @f.input(:text, :wrapper=>:li).to_s.should == '<li><input type="text"/></li>'
  end

  specify "inputs should accept a :formatter option to use a custom formatter" do
    @f.input(:text, :formatter=>:readonly, :value=>'1', :label=>'Foo').to_s.should == '<label>Foo: <span>1</span></label>'
    @f.input(:text, :formatter=>:default, :value=>'1', :label=>'Foo').to_s.should == '<label>Foo: <input type="text" value="1"/></label>'
  end

  specify "inputs should accept a :labeler option to use a custom labeler" do
    @f.input(:textarea, :labeler=>:explicit, :label=>'bar', :id=>:foo).to_s.should == '<label for="foo">bar</label><textarea id="foo"></textarea>'
  end

  specify "inputs should accept a :error_handler option to use a custom error_handler" do
    @f.input(:textarea, :error_handler=>proc{|t, i| [t, "!!! #{i.opts[:error]}"]}, :error=>'bar', :id=>:foo).to_s.should == '<textarea id="foo"></textarea>!!! bar'
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
    @f.input(:textarea, :error_handler=>nil, :error=>'bar', :id=>:foo).to_s.should == '<textarea id="foo"></textarea>'
  end

  specify "#inputs should accept a :inputs_wrapper=>nil option to not use an inputs_wrapper" do
    @f.form{|f| f.inputs([:textarea], :inputs_wrapper=>nil)}.to_s.should == '<form><textarea></textarea></form>'
  end

  specify "invalid custom transformers should raise an Error" do
    proc{Forme::Form.new(:wrapper=>Object.new)}.should raise_error(Forme::Error)
    proc{@f.input(:textarea, :wrapper=>Object.new).to_s}.should raise_error(Forme::Error)
  end
end

describe "Forme custom" do
  specify "formatters can be specified as a proc" do
    Forme::Form.new(:formatter=>proc{|i| i.form._tag(:textarea, i.opts.map{|k,v| [v.upcase, k.to_s.downcase]})}).input(:text, :NAME=>'foo').to_s.should == '<textarea FOO="name"></textarea>'
  end

  specify "serializers can be specified as a proc" do
    Forme::Form.new(:serializer=>proc{|t| "#{t.type} = #{t.opts.inspect}"}).input(:textarea, :NAME=>'foo').to_s.should == 'textarea = {:NAME=>"foo"}'
  end

  specify "labelers can be specified as a proc" do
    Forme::Form.new(:labeler=>proc{|t, i| ["#{i.opts[:label]}: ", t]}).input(:textarea, :NAME=>'foo', :label=>'bar').to_s.should == 'bar: <textarea NAME="foo"></textarea>'
  end

  specify "error_handlers can be specified as a proc" do
    Forme::Form.new(:error_handler=>proc{|t, i| [t, "!!! #{i.opts[:error]}"]}).input(:textarea, :NAME=>'foo', :error=>'bar').to_s.should == '<textarea NAME="foo"></textarea>!!! bar'
  end

  specify "wrappers can be specified as a proc" do
    Forme::Form.new(:wrapper=>proc{|t, i| t.tag(:div, {:bar=>i.opts[:NAME]}, t)}).input(:textarea, :NAME=>'foo').to_s.should == '<div bar="foo"><textarea NAME="foo"></textarea></div>'
  end

  specify "inputs_wrappers can be specified as a proc" do
    Forme::Form.new(:inputs_wrapper=>proc{|f, opts, &block| f.tag(:div, &block)}).inputs([:textarea]).to_s.should == '<div><textarea></textarea></div>'
  end
end

describe "Forme built-in custom" do
  specify "transformers should raise if the there is no matching transformer" do
    proc{Forme::Form.new(:formatter=>:foo)}.should raise_error(Forme::Error)
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
    Forme::Form.new(:labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'bar').to_s.should == '<label for="foo">bar</label><textarea id="foo"></textarea>'
  end

  specify "labeler: explicit should handle tags with errors" do
    Forme::Form.new(:labeler=>:explicit).input(:text, :error=>'Bad Stuff!', :value=>'f', :id=>'foo', :label=>'bar').to_s.should == '<label for="foo">bar</label><input class="error" id="foo" type="text" value="f"/><span class="error_message">Bad Stuff!</span>'
  end

  specify "wrapper: li wraps tag in an li" do
    Forme::Form.new(:wrapper=>:li).input(:textarea, :id=>'foo').to_s.should == '<li><textarea id="foo"></textarea></li>'
  end

  specify "wrapper: p wraps tag in an p" do
    Forme::Form.new(:wrapper=>:p).input(:textarea, :id=>'foo').to_s.should == '<p><textarea id="foo"></textarea></p>'
  end

  specify "wrapper: div wraps tag in an div" do
    Forme::Form.new(:wrapper=>:div).input(:textarea, :id=>'foo').to_s.should == '<div><textarea id="foo"></textarea></div>'
  end

  specify "wrapper: span wraps tag in an span" do
    Forme::Form.new(:wrapper=>:span).input(:textarea, :id=>'foo').to_s.should == '<span><textarea id="foo"></textarea></span>'
  end

  specify "wrapper: trtd wraps tag in an tr/td" do
    Forme::Form.new(:wrapper=>:trtd).input(:textarea, :id=>'foo').to_s.should == '<tr><td><textarea id="foo"></textarea></td></tr>'
  end

  specify "wrapper: trtd supports multiple tags in separate tds" do
    Forme::Form.new(:wrapper=>:trtd, :labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'Foo').to_s.should == '<tr><td><label for="foo">Foo</label></td><td><textarea id="foo"></textarea></td></tr>'
  end

  specify "wrapper: trtd should use at most 2 td tags" do
    Forme::Form.new(:wrapper=>:trtd, :labeler=>:explicit).input(:textarea, :id=>'foo', :label=>'Foo', :error=>'Bar').to_s.should == '<tr><td><label for="foo">Foo</label></td><td><textarea class="error" id="foo"></textarea><span class="error_message">Bar</span></td></tr>'
  end

  specify "inputs_wrapper: ol wraps tags in an ol" do
    Forme::Form.new(:inputs_wrapper=>:ol, :wrapper=>:li).inputs([:textarea]).to_s.should == '<ol><li><textarea></textarea></li></ol>'
  end

  specify "inputs_wrapper: fieldset_ol wraps tags in a fieldset and an ol" do
    Forme::Form.new(:inputs_wrapper=>:fieldset_ol, :wrapper=>:li).inputs([:textarea]).to_s.should == '<fieldset><ol><li><textarea></textarea></li></ol></fieldset>'
  end

  specify "inputs_wrapper: fieldset_ol supports a :legend option" do
    Forme.form({}, :inputs_wrapper=>:fieldset_ol, :wrapper=>:li, :legend=>'Foo', :inputs=>[:textarea]).to_s.should == '<form><fieldset><legend>Foo</legend><ol><li><textarea></textarea></li></ol></fieldset></form>'
  end

  specify "inputs_wrapper: div wraps tags in a div" do
    Forme::Form.new(:inputs_wrapper=>:div, :wrapper=>:span).inputs([:textarea]).to_s.should == '<div><span><textarea></textarea></span></div>'
  end

  specify "inputs_wrapper: table wraps tags in an table" do
    Forme::Form.new(:inputs_wrapper=>:table, :wrapper=>:trtd).inputs([:textarea]).to_s.should == '<table><tr><td><textarea></textarea></td></tr></table>'
  end

  specify "serializer: html_usa formats dates and datetimes in American format without timezones" do
    Forme::Form.new(:serializer=>:html_usa).tag(:div, :foo=>Date.new(2011, 6, 5)).to_s.should == '<div foo="06/05/2011"></div>'
    Forme::Form.new(:serializer=>:html_usa).tag(:div, :foo=>DateTime.new(2011, 6, 5, 16, 3, 2)).to_s.should == '<div foo="06/05/2011 04:03:02PM"></div>'
    Forme::Form.new(:serializer=>:html_usa).tag(:div, :foo=>Time.utc(2011, 6, 5, 4, 3, 2)).to_s.should == '<div foo="06/05/2011 04:03:02AM"></div>'
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
    Forme.register_transformer(:wrapper, :div, proc{|t, i| t.tag(:div, {}, [t])})
    Forme::Form.new(:wrapper=>:div).input(:textarea).to_s.should == '<div><textarea></textarea></div>'
  end

  specify "should have #register_transformer register a transformer block for later use" do
    Forme.register_transformer(:wrapper, :div1){|t, i| t.tag(:div1, {}, [t])}
    Forme::Form.new(:wrapper=>:div1).input(:textarea).to_s.should == '<div1><textarea></textarea></div1>'
  end

  specify "should have #register_transformer raise an error if given a block and an object" do
    proc do
      Forme.register_transformer(:wrapper, :div1, proc{|t, i| t}){|t| t.tag(:div1, {}, [t])}
    end.should raise_error(Forme::Error)
  end
end

describe "Forme configurations" do
  after do
    Forme.default_config = :default
  end

  specify "config: :formastic uses fieldset_ol inputs_wrapper and li wrapper, and explicit labeler" do
    Forme::Form.new(:config=>:formtastic).inputs([[:textarea, {:id=>:foo, :label=>'Foo'}]]).to_s.should == '<fieldset><ol><li><label for="foo">Foo</label><textarea id="foo"></textarea></li></ol></fieldset>'
  end

  specify "should be able to set a default configuration with Forme.default_config=" do
    Forme.default_config = :formtastic
    Forme::Form.new.inputs([[:textarea, {:id=>:foo, :label=>'Foo'}]]).to_s.should == '<fieldset><ol><li><label for="foo">Foo</label><textarea id="foo"></textarea></li></ol></fieldset>'
  end

  specify "should have #register_config register a configuration for later use" do
    Forme.register_config(:foo, :wrapper=>:li, :labeler=>:explicit)
    Forme::Form.new(:config=>:foo).input(:textarea, :id=>:foo, :label=>'Foo').to_s.should == '<li><label for="foo">Foo</label><textarea id="foo"></textarea></li>'
  end

  specify "should have #register_config support a :base option to base it on an existing config" do
    Forme.register_config(:foo2, :labeler=>:default, :base=>:formtastic)
    Forme::Form.new(:config=>:foo2).inputs([[:textarea, {:id=>:foo, :label=>'Foo'}]]).to_s.should == '<fieldset><ol><li><label>Foo: <textarea id="foo"></textarea></label></li></ol></fieldset>'
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
    f.input(:y, :brain=>'no').to_s.should == '<label>Y: <input brain="no" id="foo_y" name="foo[y]" type="text" value="3"/></label>'
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
    Forme::Form.new([:foo]).input(:first, :x=>'bar').to_s.should ==  '<input id="first" name="first" type="text" value="foo" x="bar"/>'
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
    Forme.form({}, :inputs=>[:text, :textarea]).to_s.should ==  '<form><fieldset><input type="text"/><textarea></textarea></fieldset></form>'
  end

  specify "should handle a :legend option if inputs is used" do
    Forme.form({}, :inputs=>[:text, :textarea], :legend=>'Foo').to_s.should ==  '<form><fieldset><legend>Foo</legend><input type="text"/><textarea></textarea></fieldset></form>'
  end

  specify "should still work with a block if :inputs is used" do
    Forme.form({}, :inputs=>[:text]){|f| f.input(:textarea)}.to_s.should ==  '<form><fieldset><input type="text"/></fieldset><textarea></textarea></form>'
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
    Forme.form({}, :inputs=>[:text, :textarea], :button=>'Foo').to_s.should ==  '<form><fieldset><input type="text"/><textarea></textarea></fieldset><input type="submit" value="Foo"/></form>'
  end

end

