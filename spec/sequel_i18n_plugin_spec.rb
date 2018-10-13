require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

begin
  require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_i18n_helper.rb')
rescue LoadError
  warn "unable to load i18n, skipping i18n Sequel plugin spec"
else
describe "Forme Sequel::Model forms" do
  before do
    @ab = Invoice[1]
    @b = Forme::Form.new(@ab)
  end

  it "should not change the usual label input if translation is not present" do
    @b.input(:name).to_s.must_equal '<label>Name: <input id="invoice_name" maxlength="255" name="invoice[name]" type="text" value="b"/></label>'
  end

  it "should use the translation for the label if present" do
    @b.input(:summary).to_s.must_equal '<label>Brief Description: <input id="invoice_summary" maxlength="255" name="invoice[summary]" type="text" value="a brief summary"/></label>'
  end

  it "should not change the usual legend for the subform if the translation is not present" do
    Forme.form(Firm[1]){|f| f.subform(:invoices){ f.input(:name) }}.to_s.must_equal '<form class="forme firm" method="post"><input id="firm_invoices_attributes_0_id" name="firm[invoices_attributes][0][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Invoice #1</legend><label>Name: <input id="firm_invoices_attributes_0_name" maxlength="255" name="firm[invoices_attributes][0][name]" type="text" value="b"/></label></fieldset></form>'
  end

  it "should use the translation for the legend on the subform if present" do
    Forme.form(Firm[1]){|f| f.subform(:clients){ f.input(:name) }}.to_s.must_equal '<form class="forme firm" method="post"><input id="firm_clients_attributes_0_id" name="firm[clients_attributes][0][id]" type="hidden" value="1"/><fieldset class="inputs"><legend>Clientes</legend><label>Name: <input id="firm_clients_attributes_0_name" maxlength="255" name="firm[clients_attributes][0][name]" type="text" value="a great client"/></label></fieldset></form>'
  end
end
end
