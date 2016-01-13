require_relative 'lib/scron/version'

Gem::Specification.new do |s|
  s.name        = 'scron'
  s.version     = Scron::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Hugh Bien']
  s.email       = ['hugh@hughbien.com']
  s.homepage    = 'https://github.com/hughbien/scron'
  s.summary     = "Scheduler for laptops/machines which aren't on 24/7"
  s.description = 'Run commands at scheduled intervals.  If an interval is ' +
                  'missed, the command will be run as soon as possible.'
 
  s.required_rubygems_version = '>= 1.3.6'
 
  s.files        = Dir.glob('*.md') + Dir.glob('bin/*') + Dir.glob('lib/*')
  s.bindir       = 'bin'
  s.executables  = ['scron']
end
