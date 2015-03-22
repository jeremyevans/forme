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

begin
  begin
    raise LoadError if ENV['RSPEC1']
    # RSpec 2+
    require "rspec/core/rake_task"
    spec_class = RSpec::Core::RakeTask
    spec_files_meth = :pattern=
  rescue LoadError
    # RSpec 1
    require "spec/rake/spectask"
    spec_class = Spec::Rake::SpecTask
    spec_files_meth = :spec_files=
  end

  spec = lambda do |name, files, d|
    lib_dir = File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
    ENV['RUBYLIB'] ? (ENV['RUBYLIB'] += ":#{lib_dir}") : (ENV['RUBYLIB'] = lib_dir)
    desc d
    spec_class.new(name) do |t|
      t.send spec_files_meth, files
      t.spec_opts = ENV["#{NAME.upcase}_SPEC_OPTS"].split if ENV["#{NAME.upcase}_SPEC_OPTS"]
    end
  end

  spec_with_cov = lambda do |name, files, d|
    spec.call(name, files, d)
    desc "#{d} with coverage"
    task "#{name}_cov" do
      ENV['COVERAGE'] = '1'
      Rake::Task[name].invoke
    end
  end
  
  task :default => [:spec]
  spec_with_cov.call("spec", Dir["spec/*_spec.rb"], "Run specs")
rescue LoadError
  task :default do
    puts "Must install rspec to run the default task (which runs specs)"
  end
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

