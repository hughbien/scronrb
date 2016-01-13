require_relative 'lib/scron/version'

task :default => :test

task :test do
  if file = ENV['TEST']
    File.exists?(file) ? require_relative(file) : puts("#{file} doesn't exist")
  else
    Dir.glob('./test/*_test.rb').each { |f| require(f) }
  end
end

task :build do
  `gem build scron.gemspec`
end

task :clean do
  rm Dir.glob('*.gem')
end

task :push => :build do
  `gem push scron-#{Scron::VERSION}.gem`
end
