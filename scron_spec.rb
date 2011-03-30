require 'scron'

describe Scron do
  before(:all) do
    Scron.instance_variable_set(:@now, DateTime.new(2010, 4, 15))
  end
  
  it "should set SCHEDULE_FILE" do
    Scron::SCHEDULE_FILE.should == "#{ENV['HOME']}/.scron"
  end

  it "should set HISTORY_FILE" do
    Scron::HISTORY_FILE.should == "#{ENV['HOME']}/.scrondb"
  end

  it "should set LOG_FILE" do
    Scron::LOG_FILE.should == "#{ENV['HOME']}/.scronlog"
  end

  it "should use empty text if no file exists" do
    Scron.send(:read, './non-existent-file').should == ''
    Scron.send(:read, 'README').should_not == ''
  end

  it "should initialize with empty schedules" do
    scron = Scron.new('', '')
    scron.schedules.should == []
  end

  it "should initialize with schedules" do
    scron = Scron.new(
      "30d cmd arg1 arg2\n" +
      "7d /path/to/script.rb\n" +
      "1d /path/to/script2.rb",
      "2100-01-01.01:00 cmd arg1 arg2\n" +
      "2000-01-01.01:00 /path/to/script.rb")
    scron.schedules.size.should == 3
    scron.schedules[0].should_not be_overdue
    scron.schedules[1].should be_overdue
    scron.schedules[2].should be_overdue
  end
end

describe Schedule do
  it "should parse interval from day string" do
    sched = Schedule.new('1d c', History.new(''))
    sched.send(:parse_days, '1d').should == 1
    sched.send(:parse_days, '30d').should == 30
  end

  it "should parse interval from day of week" do
    sched = Schedule.new('1d c', History.new(''))
    sched.send(:parse_days, 'Mo').should == 4
    sched.send(:parse_days, 'Tu').should == 3
    sched.send(:parse_days, 'We').should == 2
    sched.send(:parse_days, 'Th').should == 1
    sched.send(:parse_days, 'Fr').should == 7
    sched.send(:parse_days, 'Sa').should == 6
    sched.send(:parse_days, 'Su').should == 5
  end

  it "should parse interval from day of month" do
    sched = Schedule.new('1d c', History.new(''))
    sched.send(:parse_days, '1st').should == 15
    sched.send(:parse_days, '15th').should == 1
    sched.send(:parse_days, '23rd').should == 24
  end

  it "should parse interval from day of year" do
    sched = Schedule.new('1d c', History.new(''))
    sched.send(:parse_days, '1/1').should == 105
    sched.send(:parse_days, '4/15').should == 1
    sched.send(:parse_days, '12/25').should == 112
  end

  it "should initialize with command and interval" do
    sched = Schedule.new('30d cmd arg1 arg2', History.new(''))
    sched.command.should == 'cmd arg1 arg2'
    sched.interval.should == 30
    sched.should be_overdue
  end

  it "should initialize with overdue history" do
    sched = Schedule.new('30d cmd', History.new('2000-01-01.01:00 cmd'))
    sched.should be_overdue
  end

  it "should initialize with recent history" do
    sched = Schedule.new('30d cmd', History.new('2100-01-01.01:00 cmd'))
    sched.should_not be_overdue
  end
end

describe History do
  it "should initialize from text" do
    history = History.new('2100-01-01.01:00 cmd arg1 arg2')
    history['cmd arg1 arg2'].should == DateTime.new(2100, 1, 1, 1, 0)
  end

  it "should update command" do
    history = History.new('')
    history.touch('cmd')
    history['cmd'].should be_kind_of(DateTime)
  end

  it "should output to string" do
    history = History.new('')
    history.touch('cmd')
    history.to_s.should =~ /^20\d{2}-\d{2}-\d{2}.\d{2}:\d{2} cmd$/
  end
end
