module FormeErbSpecs
  extend Minitest::Spec::DSL

  before do
    o = Object.new
    def o.puts(*) end
    @rack = {'rack.input'=>'', 'REQUEST_METHOD'=>'GET', 'rack.errors'=>o, 'SCRIPT_NAME'=>''}
  end

  it "#form should add start and end tags and yield Forme::Form instance" do
    sin_get('/').must_equal '<form action="/baz"> <p>FBB</p> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> <input type="submit" value="Save"/> </form>'
  end

  it "#form should have inputs work with a block" do
    sin_get('/inputs_block').must_equal '<form action="/baz"><fieldset class="inputs"><legend>FBB</legend> <input id="last" name="last" type="text" value="bar"/> </fieldset></form>'
  end

  it "#form should have inputs with fieldset_ol wrapper work with block" do
    sin_get('/inputs_block_wrapper').must_equal '<form action="/baz"><fieldset class="inputs"><legend>FBB</legend><ol> <input id="last" name="last" type="text" value="bar"/> </ol></fieldset></form>'
  end

  it "#form should add start and end tags and yield Forme::Form instance" do
    sin_get('/nest').must_equal '<form action="/baz"> <p>FBB</p> <div> <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> </div> </form>'
  end

  it "#form should correctly handle situation where multiple templates are used with same form object" do
    sin_get('/nest_sep').sub(/ 4\z/, '4').must_equal '0 <form action="/baz"> 1 <p>FBB</p> 2 n1 <div> n2 <input id="first" name="first" type="text" value="foo"/> <input id="last" name="last" type="text" value="bar"/> n3 </div> n4 <fieldset class="inputs"><legend>Foo</legend><input id="first" name="first" type="text" value="foo"/><input id="last" name="last" type="text" value="bar"/></fieldset> n5 3 </form>4'
  end

  it "#form should correctly handle situation Sequel integration with subforms where multiple templates are used with same form object" do
    sin_get('/nest_seq_simple').sub(/ 4\z/, '4').sub(%r{<input name="_csrf" type="hidden" value="([^"]+)"/>}, '<input name="_csrf" type="hidden" value="csrf"/>').must_equal '0 <form action="/baz" class="forme album" method="post"><input name="_csrf" type="hidden" value="csrf"/> 1 n1 <input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Artist</legend> n2 <label>Name2: <input id="album_artist_attributes_name2" name="album[artist_attributes][name2]" type="text" value="A2"/></label> n3 </fieldset> n4 3 </form>4'

    sin_get('/nest_seq').sub(/ 4\z/, '4').sub(%r{<input name="_csrf" type="hidden" value="([^"]+)"/>}, '<input name="_csrf" type="hidden" value="csrf"/>').must_equal '0 <form action="/baz" class="forme album" method="post"><input name="_csrf" type="hidden" value="csrf"/> 1 <input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Foo</legend><label>Name: <input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="A"/></label></fieldset> 2 n1 <input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Artist</legend> n2 <label>Name2: <input id="album_artist_attributes_name2" name="album[artist_attributes][name2]" type="text" value="A2"/></label> n3 </fieldset> n4 <input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="2"/><fieldset class="inputs"><legend>Bar</legend><label>Name3: <input id="album_artist_attributes_name3" name="album[artist_attributes][name3]" type="text" value="A3"/></label></fieldset> n5 3 </form>4'
  end

  it "#form should correctly handle subform with :grid option with block" do
    sin_get('/grid-block').sub(/ 4\z/, '4').sub(%r{<input name="_csrf" type="hidden" value="([^"]+)"/>}, '<input name="_csrf" type="hidden" value="csrf"/>').must_equal '0 <form action="/baz" class="forme album" method="post"><input name="_csrf" type="hidden" value="csrf"/> 1 <input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="2"/><table><caption>Foo</caption><thead><tr><th>Name</th></tr></thead><tbody><tr><td class="string"><input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="A"/></td> 2 </tr></tbody></table> 3 <input type="submit" value="Sub"/></form>4'
  end

  it "#form should correctly handle subform with :grid option without block" do
    sin_get('/grid-noblock').sub(/ 3\z/, '3').sub(%r{<input name="_csrf" type="hidden" value="([^"]+)"/>}, '<input name="_csrf" type="hidden" value="csrf"/>').must_equal '0 <form action="/baz" class="forme album" method="post"><input name="_csrf" type="hidden" value="csrf"/> 1 <input id="album_artist_attributes_id" name="album[artist_attributes][id]" type="hidden" value="2"/><table><caption>Foo</caption><thead><tr><th>Name</th></tr></thead><tbody><tr><td class="string"><input id="album_artist_attributes_name" maxlength="255" name="album[artist_attributes][name]" type="text" value="A"/></td></tr></tbody></table> 2 <input type="submit" value="Sub"/></form>3'
  end

  it "#form should correctly handle subform with :grid option without block" do
    sin_get('/grid-noblock-multiple').sub(/ 3\z/, '3').sub(%r{<input name="_csrf" type="hidden" value="([^"]+)"/>}, '<input name="_csrf" type="hidden" value="csrf"/>').must_equal '0 <form action="/baz" class="forme artist" method="post"><input name="_csrf" type="hidden" value="csrf"/> 1 <input id="artist_albums_attributes_0_id" name="artist[albums_attributes][0][id]" type="hidden" value="1"/><table><caption>Foo</caption><thead><tr><th>Name</th><th>Copies</th></tr></thead><tbody><tr><td class="string"><input id="artist_albums_attributes_0_name" maxlength="255" name="artist[albums_attributes][0][name]" type="text" value="N"/></td><td class="integer"><input id="artist_albums_attributes_0_copies_sold" name="artist[albums_attributes][0][copies_sold]" type="number" value="2"/></td></tr></tbody></table> 2 <input type="submit" value="Sub"/></form>3'
  end

  it "#form should accept two hashes instead of requiring obj as first argument" do
    sin_get('/hash').must_equal '<form action="/baz"> <input id="first" name="first" type="text" value="foo"/> </form>'
  end

  it "#form should deal with emitted code" do
    sin_get('/legend').must_equal '<form action="/baz"> <p>FBB</p> <fieldset class="inputs"><legend>Foo</legend><input id="first" name="first" type="text" value="foo"/><input id="last" name="last" type="text" value="bar"/></fieldset> <p>FBB2</p> </form>'
  end

  it "#form should work with :inputs, :button, and :legend options" do
    sin_get('/combined').must_equal '<form action="/baz"><fieldset class="inputs"><legend>123</legend><input id="first" name="first" type="text" value="foo"/></fieldset> <p>FBB</p> <input id="last" name="last" type="text" value="bar"/> <input type="submit" value="xyz"/></form>'
  end

  it "#form should work without a block" do
    sin_get('/noblock').must_equal '<form action="/baz"><fieldset class="inputs"><legend>123</legend><input id="first" name="first" type="text" value="foo"/></fieldset><input type="submit" value="xyz"/></form>'
  end

  it "#form should work without a block and still have hidden tags emitted" do
    sin_get('/noblock_post').sub(%r{<input name=\"_csrf\" type=\"hidden\" value=\"([^\"]+)\"/>}, "<input name=\"_csrf\" type=\"hidden\" value=\"csrf\"/>").must_equal '<form method="post"><input name="_csrf" type="hidden" value="csrf"/><input type="submit" value="xyz"/></form>'
  end

  it "#form with an empty form should work" do
    sin_get('/noblock_empty').must_equal '<form action="/baz"></form>'
  end
end
