require_relative 'lib/forme/version'
spec = Gem::Specification.new do |s|
  s.name = 'forme'
  s.version = Forme.version.dup
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "MIT-LICENSE"]
  s.rdoc_options += ["--quiet", "--line-numbers", "--inline-source", '--title', 'Forme: HTML forms library', '--main', 'README.rdoc']
  s.summary = "HTML forms library"
  s.author = "Jeremy Evans"
  s.email = "code@jeremyevans.net"
  s.homepage = "http://github.com/jeremyevans/forme"
  s.files = %w(MIT-LICENSE CHANGELOG README.rdoc) + Dir["lib/**/*.rb"]
  s.license = 'MIT'
  s.metadata = {
    'bug_tracker_uri'   => 'https://github.com/jeremyevans/forme/issues',
    'changelog_uri'     => 'http://forme.jeremyevans.net/files/CHANGELOG.html',
    'documentation_uri' => 'http://forme.jeremyevans.net',
    'mailing_list_uri'  => 'https://github.com/jeremyevans/forme/discussions',
    'source_code_uri'   => 'https://github.com/jeremyevans/forme',
  }
  s.description = <<END
Forme is a forms library with the following goals:

1) Have no external dependencies
2) Have a simple API
3) Support forms both with and without related objects
4) Allow compiling down to different types of output
5) Integrate easily into web frameworks
END

  s.required_ruby_version = ">= 1.9.2"
  s.add_dependency "bigdecimal"
  s.add_development_dependency "minitest", '>= 5.7.0'
  s.add_development_dependency "minitest-global_expectations"
  s.add_development_dependency "sequel", '>= 4'
  s.add_development_dependency "roda"
  s.add_development_dependency "rack_csrf"
  s.add_development_dependency "erubi"
  s.add_development_dependency "tilt"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "rails"
  s.add_development_dependency "i18n"
end
