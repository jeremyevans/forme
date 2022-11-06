require_relative 'spec_helper'
require_relative 'sequel_helper'
require_relative '../lib/forme/bs5'

describe "Forme Sequel::Model BS5 forms" do
  before do
    @ab = Album[1]
    @b = Forme::Form.new(@ab, config: :bs5)
    @ac = Album[2]
    @c = Forme::Form.new(@ac, config: :bs5)
  end

  it "should use a checkbox for dual-valued boolean fields" do
    @b.input(:platinum).must_equal '<div class="form-check boolean"><input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><input class="form-check-input" id="album_platinum" name="album[platinum]" type="checkbox" value="t"/><label class="form-check-label label-after" for="album_platinum">Platinum</label></div>'
    @c.input(:platinum).must_equal '<div class="form-check boolean"><input id="album_platinum_hidden" name="album[platinum]" type="hidden" value="f"/><input checked="checked" class="form-check-input" id="album_platinum" name="album[platinum]" type="checkbox" value="t"/><label class="form-check-label label-after" for="album_platinum">Platinum</label></div>'
  end

  it "should use radio buttons for boolean fields if :as=>:radio is used" do
    @b.input(:platinum, :as=>:radio).must_equal '<div class="boolean"><span class="label">Platinum</span><div class="form-check"><input class="form-check-input" id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/><label class="form-check-label option label-after" for="album_platinum_yes">Yes</label></div><div class="form-check"><input checked="checked" class="form-check-input" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/><label class="form-check-label option label-after" for="album_platinum_no">No</label></div></div>'
    @c.input(:platinum, :as=>:radio).must_equal '<div class="boolean"><span class="label">Platinum</span><div class="form-check"><input checked="checked" class="form-check-input" id="album_platinum_yes" name="album[platinum]" type="radio" value="t"/><label class="form-check-label option label-after" for="album_platinum_yes">Yes</label></div><div class="form-check"><input class="form-check-input" id="album_platinum_no" name="album[platinum]" type="radio" value="f"/><label class="form-check-label option label-after" for="album_platinum_no">No</label></div></div>'
  end
end
