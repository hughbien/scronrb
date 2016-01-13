require_relative '../lib/scron'
require 'minitest/autorun'

class ScronTest < Minitest::Test
  def setup
    Scron::App.instance_variable_set(:@now, DateTime.new(2010, 3, 15))
  end
end
