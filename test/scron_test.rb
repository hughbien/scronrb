require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'scron'))
gem 'minitest'
require 'minitest/autorun'

class ScronTest < Minitest::Test
  def setup
    Scron.instance_variable_set(:@now, DateTime.new(2010, 3, 15))
  end
end

class AppTest < ScronTest
  def test_files
    assert_equal("#{ENV['HOME']}/.scron", Scron::SCHEDULE_FILE)
    assert_equal("#{ENV['HOME']}/.scrondb", Scron::HISTORY_FILE)
    assert_equal("#{ENV['HOME']}/.scronlog", Scron::LOG_FILE)
  end

  def test_editor
    assert_includes([ENV['EDITOR'] || 'vi'], Scron::EDITOR)
  end

  def test_empty
    assert_equal('', Scron.send(:read, './non-existent-file'))
    refute_equal('', Scron.send(:read, 'README.md'))
  end

  def test_no_schedules
    scron = Scron.new('', '')
    assert_equal([], scron.schedules)
  end

  def test_initialize_schedules
    scron = Scron.new(
      "30d cmd arg1 arg2\n" +
      "7d /path/to/script.rb\n" +
      "1d /path/to/script2.rb",
      "2100-01-01.01:00 cmd arg1 arg2\n" +
      "2000-01-01.01:00 /path/to/script.rb")
    assert_equal(3, scron.schedules.size)
    refute(scron.schedules[0].overdue?)
    assert(scron.schedules[1].overdue?)
    assert(scron.schedules[2].overdue?)
  end
end

class ScheduleTest < ScronTest
  def test_parse_day_interval
    sched = Schedule.new('1d c', History.new(''))
    assert_equal(1, sched.send(:parse_days, '1d'))
    assert_equal(30, sched.send(:parse_days, '30d'))
  end

  def test_parse_day_of_week
    sched = Schedule.new('1d c', History.new(''))
    assert_equal(1, sched.send(:parse_days, 'Mo'))
    assert_equal(7, sched.send(:parse_days, 'Tu'))
    assert_equal(6, sched.send(:parse_days, 'We'))
    assert_equal(5, sched.send(:parse_days, 'Th'))
    assert_equal(4, sched.send(:parse_days, 'Fr'))
    assert_equal(3, sched.send(:parse_days, 'Sa'))
    assert_equal(2, sched.send(:parse_days, 'Su'))
  end

  def test_parse_day_of_month
    sched = Schedule.new('1d c', History.new(''))
    assert_equal(15, sched.send(:parse_days, '1st'))
    assert_equal(1, sched.send(:parse_days, '15th'))
    assert_equal(21, sched.send(:parse_days, '23rd'))
    assert_equal(16, sched.send(:parse_days, '31st'))
  end

  def test_parse_day_of_year
    sched = Schedule.new('1d c', History.new(''))
    assert_equal(74, sched.send(:parse_days, '1/1'))
    assert_equal(1, sched.send(:parse_days, '3/15'))
    assert_equal(81, sched.send(:parse_days, '12/25'))
  end

  def test_initialize_command
    sched = Schedule.new('30d cmd arg1 arg2', History.new(''))
    assert_equal('cmd arg1 arg2', sched.command)
    assert_equal(30, sched.interval)
    assert(sched.overdue?)
  end

  def test_bad_date
    sched = Schedule.new('1d c', History.new(''))
    assert_raises(ArgumentError) { sched.send(:parse_days, '2/31') }
    assert_raises(ArgumentError) { sched.send(:parse_days, '1') }
  end

  def test_multiple_intervals
    assert_equal(1, Schedule.new('1d,2d,3d cmd', History.new('')).interval)
    assert_equal(2, Schedule.new('Fr,Sa,Su cmd', History.new('')).interval)
    assert_equal(15, Schedule.new('1st,23rd cmd', History.new('')).interval)
  end

  def test_overdue_history
    sched = Schedule.new('30d cmd', History.new('2000-01-01.01:00 cmd'))
    assert(sched.overdue?)
  end

  def test_recent_history
    sched = Schedule.new('30d cmd', History.new('2100-01-01.01:00 cmd'))
    refute(sched.overdue?)
  end
end

class HistoryTest < ScronTest
  def test_initialize
    history = History.new('2100-01-01.01:00 cmd arg1 arg2')
    assert_equal(DateTime.new(2100, 1, 1, 1, 0), history['cmd arg1 arg2'])
  end

  def test_update_command
    history = History.new('')
    history.touch('cmd')
    assert_kind_of(DateTime, history['cmd'])
  end

  def test_output
    history = History.new('')
    history.touch('cmd')
    assert_match(/^20\d{2}-\d{2}-\d{2}.\d{2}:\d{2} cmd$/, history.to_s)
  end
end
