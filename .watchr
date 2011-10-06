#!/usr/bin/env ruby

watch('.*\.rb') { system('ruby *_test.rb') }
