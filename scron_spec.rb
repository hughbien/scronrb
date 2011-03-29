require 'scron'

describe Scron do
  it "should set SCHEDULE_FILE" do
    Scron::SCHEDULE_FILE.should == "#{ENV['HOME']}/.scron"
  end

  it "should use empty text if no file exists" do
    Scron.new('', '').send(:read, './non-existent-file').should == ''
    Scron.new('', '').send(:read, 'README').should_not == ''
  end

  it "should initialize with empty schedules" do
    scron = Scron.new('', '')
    scron.schedules.should == []
  end

  it "should initialize with schedules" do
    scron = Scron.new(
      "30d cmd arg1 arg2\n" +
      "7d /path/to/script.rb\n" +
      "24h /path/to/script2.rb",
      "2100-01-01.01:00 cmd arg1 arg2\n" +
      "2000-01-01.01:00 /path/to/script.rb")
    scron.schedules.size.should == 3
    scron.schedules[0].should_not be_overdue
    scron.schedules[1].should be_overdue
    scron.schedules[2].should be_overdue
  end
end

describe Schedule do
  it "should parse hour intervals from time string" do
    history = History.new('')
    Schedule.new('1 c', history).send(:parse_hours, '1').should == 1
    Schedule.new('1 c', history).send(:parse_hours, '24h').should == 24
    Schedule.new('1 c', history).send(:parse_hours, '1d').should == 24
    Schedule.new('1 c', history).send(:parse_hours, '30d').should == 720
  end

  it "should initialize with command and interval" do
    sched = Schedule.new('30d cmd arg1 arg2', History.new(''))
    sched.command.should == 'cmd arg1 arg2'
    sched.interval.should == 720
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
