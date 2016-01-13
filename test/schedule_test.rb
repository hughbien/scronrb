require_relative 'test_helper'

class ScheduleTest < ScronTest
  def test_parse_day_interval
    sched = Scron::Schedule.new('1d c', Scron::History.new(''))
    assert_equal(1, sched.send(:parse_days, '1d'))
    assert_equal(30, sched.send(:parse_days, '30d'))
  end

  def test_parse_day_of_week
    sched = Scron::Schedule.new('1d c', Scron::History.new(''))
    assert_equal(1, sched.send(:parse_days, 'Mo'))
    assert_equal(7, sched.send(:parse_days, 'Tu'))
    assert_equal(6, sched.send(:parse_days, 'We'))
    assert_equal(5, sched.send(:parse_days, 'Th'))
    assert_equal(4, sched.send(:parse_days, 'Fr'))
    assert_equal(3, sched.send(:parse_days, 'Sa'))
    assert_equal(2, sched.send(:parse_days, 'Su'))
  end

  def test_parse_day_of_month
    sched = Scron::Schedule.new('1d c', Scron::History.new(''))
    assert_equal(15, sched.send(:parse_days, '1st'))
    assert_equal(1, sched.send(:parse_days, '15th'))
    assert_equal(21, sched.send(:parse_days, '23rd'))
    assert_equal(16, sched.send(:parse_days, '31st'))
  end

  def test_parse_day_of_year
    sched = Scron::Schedule.new('1d c', Scron::History.new(''))
    assert_equal(74, sched.send(:parse_days, '1/1'))
    assert_equal(1, sched.send(:parse_days, '3/15'))
    assert_equal(81, sched.send(:parse_days, '12/25'))
  end

  def test_initialize_command
    sched = Scron::Schedule.new('30d cmd arg1 arg2', Scron::History.new(''))
    assert_equal('cmd arg1 arg2', sched.command)
    assert_equal(30, sched.interval)
    assert(sched.overdue?)
  end

  def test_bad_date
    sched = Scron::Schedule.new('1d c', Scron::History.new(''))
    assert_raises(ArgumentError) { sched.send(:parse_days, '2/31') }
    assert_raises(ArgumentError) { sched.send(:parse_days, '1') }
  end

  def test_multiple_intervals
    assert_equal(1, Scron::Schedule.new('1d,2d,3d cmd', Scron::History.new('')).interval)
    assert_equal(2, Scron::Schedule.new('Fr,Sa,Su cmd', Scron::History.new('')).interval)
    assert_equal(15, Scron::Schedule.new('1st,23rd cmd', Scron::History.new('')).interval)
  end

  def test_overdue_history
    sched = Scron::Schedule.new('30d cmd', Scron::History.new('2000-01-01.01:00 cmd'))
    assert(sched.overdue?)
  end

  def test_recent_history
    sched = Scron::Schedule.new('30d cmd', Scron::History.new('2100-01-01.01:00 cmd'))
    refute(sched.overdue?)
  end
end
