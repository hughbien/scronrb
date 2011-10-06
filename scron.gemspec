require File.expand_path('scron', File.dirname(__FILE__)) 
 
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
  s.add_development_dependency 'minitest'
 
  s.files        = Dir.glob('*.{rb,md}') + %w(scron)
  s.bindir       = '.'
  s.executables  = ['scron']
  s.require_path = 'lib'
end
