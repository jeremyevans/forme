require "rake"
require "rake/clean"

NAME = 'forme'
VERS = lambda do
  require File.expand_path("../lib/forme/version", __FILE__)
  Forme.version
end
CLEAN.include ["#{NAME}-*.gem", "rdoc", "coverage", '**/*.rbc']

# Gem Packaging and Release

desc "Packages #{NAME}"
task :package=>[:clean] do |p|
  sh %{gem build #{NAME}.gemspec}
end

desc "Upload #{NAME} gem to rubygems"
task :release=>[:package] do
  sh %{gem push ./#{NAME}-#{VERS.call}.gem} 
end

### RDoc

RDOC_DEFAULT_OPTS = ["--line-numbers", "--inline-source", '--title', 'Forme']

begin
  gem 'hanna-nouveau'
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
rescue Gem::LoadError
end

rdoc_task_class = begin
  require "rdoc/task"
  RDoc::Task
rescue LoadError
  require "rake/rdoctask"
  Rake::RDocTask
end

RDOC_OPTS = RDOC_DEFAULT_OPTS + ['--main', 'README.rdoc']

rdoc_task_class.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add %w"README.rdoc CHANGELOG MIT-LICENSE lib/**/*.rb"
end

### Specs

desc "Run specs"
task :spec do
  sh "#{FileUtils::RUBY} spec/all.rb"
end
task :default => :spec

desc "Run specs with coverage"
task :spec_cov do
  ENV['COVERAGE'] = '1'
  sh "#{FileUtils::RUBY} spec/all.rb"
end

desc "Run specs with -w, some warnings filtered"
task :spec_w do
  ENV['WARNING'] = '1'
  sh "#{FileUtils::RUBY} -w spec/all.rb"
end

### Other

desc "Print #{NAME} version"
task :version do
  puts VERS.call
end

desc "Check syntax of all .rb files"
task :check_syntax do
  Dir['**/*.rb'].each{|file| print `#{ENV['RUBY'] || :ruby} -c #{file} | fgrep -v "Syntax OK"`}
end

desc "Start an IRB shell using the extension"
task :irb do
  require 'rbconfig'
  ruby = ENV['RUBY'] || File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
  irb = ENV['IRB'] || File.join(RbConfig::CONFIG['bindir'], File.basename(ruby).sub('ruby', 'irb'))
  sh %{#{irb} -I lib -r forme}
end

