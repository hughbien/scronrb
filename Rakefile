require File.expand_path('scron', File.dirname(__FILE__))

task :default => :test

task :test do
  ruby '*_test.rb' # see .watchr for continuous testing
end

task :build do
  `gem build scron.gemspec`
end

task :push => :build do
  `gem push scron-#{Scron::VERSION}.gem`
end
