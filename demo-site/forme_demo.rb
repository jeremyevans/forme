#!/usr/bin/env/ruby
require 'rubygems'
require 'erb'
require 'sinatra/base'
require 'models'
require 'forme/sinatra'

class FormeDemo < Sinatra::Base
  disable :run
  disable :session

  helpers Forme::Sinatra::ERB
  helpers do
    def h(s)
      Rack::Utils.escape_html(s.to_s)
    end

    def form_opts
      @form_opts ||= @form_opts_str ? eval(@form_opts_str) : {}
    end

    def demo(t, opts={})
      @templ = t
      erb(t, opts)
    end
  end

  get '/' do
    @page_title = 'Forme Demo Site'
    erb :index
  end

  get '/album/basic/default' do
    @page_title = 'Album Basic - Default'
    @css = "form label { display: block; }"
    demo :album_basic
  end

  get '/album/basic/explicit' do
    @page_title = 'Album Basic - Explicit Labels'
    @form_opts_str = '{:labeler=>:explicit, :wrapper=>proc{|tag| tag.tag(:div, {}, tag)}}'
    @css = <<-END
label, input, select { display: block; float: left }
label { min-width: 120px; }
form div { padding: 5px; clear: both; }
END
    demo :album_basic
  end

  get '/album/basic/table' do
    @page_title = 'Album Basic - Table'
    @form_opts_str = '{:labeler=>:explicit, :wrapper=>:trtd, :inputs_wrapper=>:table}'
    demo :album_basic
  end

  get '/album/basic/list' do
    @page_title = 'Album Basic - List'
    @form_opts_str = '{:wrapper=>:li, :inputs_wrapper=>:ol}'
    @css = "ol {list-style-type: none;}"
    demo :album_basic
  end

  get '/album/basic/alt_assoc' do
    @page_title = 'Album Basic - Association Radios/Checkboxes'
    @form_opts_str = "{:wrapper=>:li, :inputs_wrapper=>:ol, :many=>{:type=>:checkbox}, :one=>{:type=>:radio}}"
    @css = "ol {list-style-type: none;}"
    demo :album_basic
  end

  get '/album/basic/readonly' do
    @page_title = 'Album Basic - Read Only'
    @form_opts_str = "{:wrapper=>:li, :inputs_wrapper=>:ol, :formatter=>:readonly}"
    @css = "ol {list-style-type: none;}"
    demo :album_basic
  end

  get '/album/basic/text' do
    @page_title = 'Album Basic - Plain Text'
    @form_opts_str = "{:serializer=>:text}"
    content_type 'text/plain'
    demo :album_basic, :layout=>false
  end

  get '/album/nested' do
    @page_title = 'Single Level Nesting'
    @css = "form label { display: block; }"
    demo :album_nested
  end

  get '/artist/nested' do
    @page_title = 'Multiple Level Nesting'
    @css = "form label { display: block; }"
    demo :artist_nested
  end

  post '/album' do
    Album[1].update(params[:album])
    redirect back
  end

  post '/artist' do
    Artist[1].update(params[:artist])
    redirect back
  end

end

class FileServer
  def initialize(app, root)
    @app = app
    @rfile = Rack::File.new(root)
  end
  def call(env)
    res = @rfile.call(env)
    res[0] == 200 ? res : @app.call(env)
  end
end

