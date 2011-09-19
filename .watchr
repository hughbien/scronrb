#!/usr/bin/env ruby

watch('.*\.rb') { system('rspec *_spec.rb') }
