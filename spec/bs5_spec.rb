require_relative 'spec_helper'
require_relative '../lib/forme/bs5'

describe "Forme Bootstrap5 (BS5) forms" do
  before do
    @f = Forme::Form.new(config: :bs5)
  end

  it "should generate email and password fields" do
    @f.input(:email).must_equal '<div><input class="form-control" type="email"/></div>'
    @f.input(:email, label: "Email address").must_equal '<div><label class="form-label label-before">Email address</label><input class="form-control" type="email"/></div>'
    @f.input(:password).must_equal '<div><input class="form-control" type="password"/></div>'
    @f.input(:password, label: "Password").must_equal '<div><label class="form-label label-before">Password</label><input class="form-control" type="password"/></div>'
  end

  it "should generate submit buttons" do
    @f.button("Click me").must_equal '<input class="btn btn-primary" type="submit" value="Click me"/>'
    @f.button(value: "Click me", class: "btn-warning").must_equal '<input class="btn btn-warning" type="submit" value="Click me"/>'
    @f.button(value: "Click me", class: "btn-outline-success").must_equal '<input class="btn btn-outline-success" type="submit" value="Click me"/>'
  end

  it "should generate hidden fields" do
    @f.input(:hidden, value: "foobar").must_equal '<input type="hidden" value="foobar"/>'
  end

  it "should generate checkboxes" do
    @f.input(:checkbox).must_equal '<div class="form-check"><input class="form-check-input" type="checkbox"/></div>'
    @f.input(:checkbox, label: "Check me out").must_equal '<div class="form-check"><input class="form-check-input" type="checkbox"/><label class="form-check-label label-after">Check me out</label></div>'
  end

  it "should generate radio buttons" do
    @f.input(:radio).must_equal '<div class="form-check"><input class="form-check-input" type="radio"/></div>'
    @f.input(:radio, label: "Default radio").must_equal '<div class="form-check"><input class="form-check-input" type="radio"/><label class="form-check-label label-after">Default radio</label></div>'
  end

  it "should generate textarea fields" do
    @f.input(:textarea).must_equal '<div><textarea class="form-control"></textarea></div>'
  end

  it "should generate select fields" do
    @f.input(:select, options: { 'Foo' => 'foo', 'Bar' => 'bar' }, selected: 'bar').must_equal '<div><select class="form-select"><option value="foo">Foo</option><option selected="selected" value="bar">Bar</option></select></div>'
  end

  it "should generate range fields" do
    @f.input(:range).must_equal '<div><input class="form-range" type="range"/></div>'
  end

  it "should generate color fields" do
    @f.input(:color).must_equal '<div><input class="form-control form-control-color" type="color"/></div>'
  end

  it "should link labels to input fields" do
    @f.input(:text, label: "Some field", id: "some_field").must_equal '<div><label class="form-label label-before" for="some_field">Some field</label><input class="form-control" id="some_field" type="text"/></div>'
  end

  it "should generate form text" do
    @f.input(:text, help: "This is some hint").must_equal '<div><input class="form-control" type="text"/><div class="form-text">This is some hint</div></div>'
    @f.input(:text, help: "This is some hint", helper_attr: { id: "field_help" }).must_equal '<div><input aria-describedby="field_help" class="form-control" type="text"/><div class="form-text" id="field_help">This is some hint</div></div>'
    @f.input(:text, label: "Some label", help: "This is some hint").must_equal '<div><label class="form-label label-before">Some label</label><input class="form-control" type="text"/><div class="form-text">This is some hint</div></div>'
    @f.input(:text, label: "Some label", help: "This is some hint", helper_attr: { id: "field_help" }).must_equal '<div><label class="form-label label-before">Some label</label><input aria-describedby="field_help" class="form-control" type="text"/><div class="form-text" id="field_help">This is some hint</div></div>'
  end

  it "should generate error feedback" do
    @f.input(:text, error: "This is wrong").must_equal '<div><input aria-invalid="true" class="form-control is-invalid" type="text"/><div class="invalid-feedback">This is wrong</div></div>'
    @f.input(:text, error: "This is wrong", error_id: "field_feedback").must_equal '<div><input aria-describedby="field_feedback" aria-invalid="true" class="form-control is-invalid" type="text"/><div class="invalid-feedback" id="field_feedback">This is wrong</div></div>'
    @f.input(:text, error: "This is wrong", label: "Some label").must_equal '<div><label class="form-label label-before">Some label</label><input aria-invalid="true" class="form-control is-invalid" type="text"/><div class="invalid-feedback">This is wrong</div></div>'
    @f.input(:text, error: "This is wrong", error_id: "field_feedback", label: "Some label").must_equal '<div><label class="form-label label-before">Some label</label><input aria-describedby="field_feedback" aria-invalid="true" class="form-control is-invalid" type="text"/><div class="invalid-feedback" id="field_feedback">This is wrong</div></div>'
    @f.input(:text, error: "This is wrong", class: "foo").must_equal '<div><input aria-invalid="true" class="form-control foo is-invalid" type="text"/><div class="invalid-feedback">This is wrong</div></div>'
  end

  it "should consider form's :errors hash based on the :key option" do
    @f.opts[:errors] = { "foo" => "must be present" }
    @f.input(:text, key: "foo").must_equal '<div><input aria-describedby="foo_error_message" aria-invalid="true" class="form-control is-invalid" id="foo" name="foo" type="text"/><div class="invalid-feedback" id="foo_error_message">must be present</div></div>'
  end

  it "should support error tooltips" do
    @f.input(:text, error: "This is wrong", error_attr: { class: "invalid-tooltip" }).must_equal '<div><input aria-invalid="true" class="form-control is-invalid" type="text"/><div class="invalid-tooltip">This is wrong</div></div>'
  end

  it "supports control sizing, select sizing, switches, and inline radios" do
    @f.input(:text, class: "form-control-lg").must_equal '<div><input class="form-control form-control-lg" type="text"/></div>'
    @f.input(:select, class: "form-select-lg").must_equal '<div><select class="form-select form-select-lg"></select></div>'
    @f.input(:checkbox, wrapper_attr: { class: "form-switch" }, attr: { role: "switch" }).must_equal '<div class="form-check form-switch"><input class="form-check-input" role="switch" type="checkbox"/></div>'
    @f.input(:radio, wrapper_attr: { class: "form-check-inline" }).must_equal '<div class="form-check form-check-inline"><input class="form-check-input" type="radio"/></div>'
  end

  it "should support floating labels" do
    @f.input(:text, label: "Some label", id: "some_field", wrapper_attr: { class: "form-floating" }).must_equal '<div class="form-floating"><input class="form-control" id="some_field" type="text"/><label class="label-after" for="some_field">Some label</label></div>'
  end

  it "should support plaintext fields" do
    @f.input(:email, class: "form-control-plaintext").must_equal '<div><input class="form-control-plaintext" type="email"/></div>'
  end

  it "should support readonly formatter" do
    @f.input(:email, formatter: :bs5_readonly).must_equal '<div><input class="form-control" readonly="readonly" type="email"/></div>'
    @f.input(:checkbox, formatter: :bs5_readonly).must_equal '<div class="form-check"><input class="form-check-input" disabled="disabled" type="checkbox"/></div>'
    @f.input(:radio, formatter: :bs5_readonly).must_equal '<div class="form-check"><input class="form-check-input" disabled="disabled" type="radio"/></div>'
    @f.input(:select, formatter: :bs5_readonly).must_equal '<div><select class="form-select" disabled="disabled"></select></div>'
    @f.input(:textarea, formatter: :bs5_readonly).must_equal '<div><textarea class="form-control" readonly="readonly"></textarea></div>'
  end

  it "should support custom inputs wrapper" do
    @f.inputs([:textarea], inputs_wrapper: :ol).must_equal '<ol><div><textarea class="form-control"></textarea></div></ol>'
    @f.inputs([:textarea], inputs_wrapper: :bs5_table, wrapper: :trtd).must_equal '<table class="table table-bordered"><tr><td><textarea class="form-control"></textarea></td><td></td></tr></table>'
    @f.inputs([:textarea], inputs_wrapper: :bs5_table, wrapper: :trtd, legend: 'Foo', labels: ['bar']).must_equal '<table class="table table-bordered"><caption>Foo</caption><tr><th>bar</th></tr><tr><td><textarea class="form-control"></textarea></td><td></td></tr></table>'
    @f.inputs([:textarea], inputs_wrapper: :bs5_table, wrapper: :trtd, attr: {class: 'foo'}).must_equal '<table class="foo"><tr><td><textarea class="form-control"></textarea></td><td></td></tr></table>'
  end

  it "should default input type to text" do
    @f.tag(:input).must_equal '<input class="form-control" type="text"/>'
  end
end
