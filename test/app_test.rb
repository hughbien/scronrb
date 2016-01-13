require_relative 'test_helper'

class AppTest < ScronTest
  def test_files
    assert_equal("#{ENV['HOME']}/.scron", Scron::App::SCHEDULE_FILE)
    assert_equal("#{ENV['HOME']}/.scrondb", Scron::App::HISTORY_FILE)
    assert_equal("#{ENV['HOME']}/.scronlog", Scron::App::LOG_FILE)
  end

  def test_editor
    assert_includes([ENV['EDITOR'] || 'vi'], Scron::App::EDITOR)
  end

  def test_empty
    assert_equal('', Scron::App.send(:read, './non-existent-file'))
    refute_equal('', Scron::App.send(:read, 'README.md'))
  end

  def test_no_schedules
    scron = Scron::App.new('', '')
    assert_equal([], scron.schedules)
  end

  def test_initialize_schedules
    scron = Scron::App.new(
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
