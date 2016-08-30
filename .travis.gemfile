source 'https://rubygems.org'

gemspec

if RUBY_VERSION < '2.0'
  gem 'rake', '< 10'
  gem 'mime-types', '< 2'
  gem 'json', '< 2'
else
  gem 'rake'
end

platforms :ruby do
  gem 'sqlite3'
end

platforms :jruby do
  gem 'jdbc-sqlite3'
end

if RUBY_VERSION < '1.9'
  gem 'rails', '< 4'
  gem 'i18n', '< 0.7'
  gem 'rack-cache', '< 1.3'
elsif RUBY_VERSION < '2.2'
  gem 'rails', '< 5'
  gem 'rack', '< 2'
else
  gem 'sinatra', '2.0.0.beta2'
end
