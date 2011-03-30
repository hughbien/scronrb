#!/usr/bin/env ruby
require 'date'

class Scron
  SCHEDULE_FILE = "#{ENV['HOME']}/.scron"
  HISTORY_FILE = "#{ENV['HOME']}/.scrondb"
  LOG_FILE = "#{ENV['HOME']}/.scronlog"
  attr_reader :history, :schedules
  
  def initialize(text, history_text)
    @history = History.new(history_text)
    @schedules = text.split("\n").
      reject {|l| l =~ /^\s+$/}.
      map {|l| Schedule.new(l, @history)}
  end

  def self.help
    puts "Usage: #{File.basename(__FILE__)}"
  end

  def self.run(argv)
    return help if argv.size != 0

    scron = Scron.new(read(SCHEDULE_FILE), read(HISTORY_FILE))
    overdue = scron.schedules.select {|s| s.overdue?}
    return if overdue.size == 0

    logger = []
    overdue.each do |schedule|
      output = `#{schedule.command}`
      logger << "=> #{now.strftime(History::FORMAT)} #{schedule.command} (#{$?.to_i})"
      logger << output unless output == ''
      scron.history.touch(schedule.command) if $?.to_i == 0
    end
    File.open(HISTORY_FILE, "w") {|f| f.puts scron.history.to_s}
    File.open(LOG_FILE, "a") {|f| f.puts logger.map {|l| l.strip}.join("\n")}
  end

  def self.now
    @now ||= DateTime.now
  end

  private
  def self.read(filename)
    File.exist?(filename) ? File.read(filename) : ''
  end
end

class Schedule
  attr_reader :interval, :command
  WEEKDAYS = {'Mo' => 1, 'Tu' => 2, 'We' => 3, 'Th' => 4, 'Fr' => 5,
              'Sa' => 6, 'Su' => 7}

  def initialize(line, history)
    interval, command = line.split(/\s+/, 2)
    @interval = parse_days(interval)
    @command = command.strip
    @overdue = history[command].nil? || 
               (Scron.now - history[command]).to_f > @interval
  end

  def overdue?
    !!@overdue
  end

  private
  def parse_days(interval)
    now = Scron.now
    if WEEKDAYS[interval]
      (now.cwday - WEEKDAYS[interval]) % 7 + 1
    elsif interval =~ /^\d+(st|nd|rd|th)$/
      day, last_month = interval.to_i, now << 1
      delta = now.day >= day ?
        now.day - day :
        now - DateTime.new(last_month.year, last_month.month, day)
      delta.to_i + 1
    elsif interval =~ /^(\d+)\/(\d+)$/
      year, month, day = Scron.now.year, $1.to_i, $2.to_i
      year -= 1 if Scron.now.month < month ||
                   (Scron.now.month == month && Scron.now.day < day)
      (Scron.now - DateTime.new(year, month, day)).to_i + 1
    else
      interval.to_i
    end
  end
end

class History
  FORMAT = '%Y-%m-%d.%H:%M'

  def initialize(text)
    @history = {}
    text.split("\n").reject {|l| l =~ /^\s+$/}.each do |line|
      timestamp, command = line.split(/\s+/, 2)
      @history[command.strip] = DateTime.parse(timestamp, FORMAT)
    end
  end

  def [](command)
    @history[command]
  end

  def touch(command)
    @history[command] = Scron.now
  end

  def to_s
    lines = []
    @history.each do |command, timestamp|
      lines << "#{timestamp.strftime(FORMAT)} #{command}"
    end
    lines.join("\n")
  end
end

Scron.run(ARGV) if $0 == __FILE__
