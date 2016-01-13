require_relative 'test_helper'

class HistoryTest < ScronTest
  def test_initialize
    history = Scron::History.new('2100-01-01.01:00 cmd arg1 arg2')
    assert_equal(DateTime.new(2100, 1, 1, 1, 0), history['cmd arg1 arg2'])
  end

  def test_update_command
    history = Scron::History.new('')
    history.touch('cmd')
    assert_kind_of(DateTime, history['cmd'])
  end

  def test_output
    history = Scron::History.new('')
    history.touch('cmd')
    assert_match(/^20\d{2}-\d{2}-\d{2}.\d{2}:\d{2} cmd$/, history.to_s)
  end
end
