#!/usr/bin/env ruby

watch('.*\.rb') { system('rspec -c *_spec.rb') }
