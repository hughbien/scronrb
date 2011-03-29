#!/usr/bin/env ruby
require 'date'
require 'open3'

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

  def self.run!
    scron = Scron.new(read(SCHEDULE_FILE), read(HISTORY_FILE))
    overdue = scron.schedules.select {|s| s.overdue?}
    return unless overdue.size > 0

    logger = []
    overdue.each do |schedule|
      stdin, stdout, stderr = Open3.popen3(schedule.command)
      stdout, stderr = stdout.gets, stderr.gets
      logger << "=> #{DateTime.now.strftime(History::FORMAT)} #{schedule.command}"
      logger << stdout if stdout
      logger << stderr if stderr
      scron.history.touch(schedule.command) unless stderr
    end
    File.open(HISTORY_FILE, "w") {|f| f.puts scron.history.to_s}
    File.open(LOG_FILE, "a") {|f| f.puts logger.map {|l| l.strip}.join("\n")}
  end

  private
  def self.read(filename)
    File.exist?(filename) ? File.read(filename) : ''
  end
end

class Schedule
  attr_reader :interval, :command

  def initialize(line, history)
    interval, command = line.split(/\s+/, 2)
    @interval = parse_hours(interval)
    @command = command.strip
    @overdue = history[command].nil? || 
               (DateTime.now - history[command]).to_f * 24 > @interval
  end

  def overdue?
    !!@overdue
  end

  private
  def parse_hours(interval)
    multiplier = interval =~ /d$/ ? 24 : 1;
    interval.to_i * multiplier
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
    @history[command] = DateTime.now
  end

  def to_s
    lines = []
    @history.each do |command, timestamp|
      lines << "#{timestamp.strftime(FORMAT)} #{command}"
    end
    lines.join("\n")
  end
end

Scron.run! if $0 == __FILE__
