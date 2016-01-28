require File.expand_path("../lib/forme/version", __FILE__)
spec = Gem::Specification.new do |s|
  s.name = 'forme'
  s.version = Forme.version.dup
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "MIT-LICENSE"]
  s.rdoc_options += ["--quiet", "--line-numbers", "--inline-source", '--title', 'Forme: HTML forms library', '--main', 'README.rdoc']
  s.summary = "HTML forms library"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.homepage = "http://github.com/jeremyevans/forme"
  s.files = %w(MIT-LICENSE CHANGELOG README.rdoc Rakefile) + Dir["{spec,lib}/**/*.rb"]
  s.license = 'MIT'
  s.description = <<END
Forme is a forms library with the following goals:

1) Have no external dependencies
2) Have a simple API
3) Support forms both with and without related objects
4) Allow compiling down to different types of output
END

  s.add_development_dependency "minitest", '>=5.7.0'
  s.add_development_dependency "sequel", '>= 4'
  s.add_development_dependency "roda"
  s.add_development_dependency "rack_csrf"
  s.add_development_dependency "erubis"
  s.add_development_dependency "tilt"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "rails"
end
