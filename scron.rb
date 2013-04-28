require 'date'

class Scron
  VERSION = '1.0.3'
  SCHEDULE_FILE = "#{ENV['HOME']}/.scron"
  HISTORY_FILE = "#{ENV['HOME']}/.scrondb"
  LOG_FILE = "#{ENV['HOME']}/.scronlog"
  EDITOR = ENV['EDITOR'] || 'vi'
  attr_reader :history, :schedules
  
  def initialize(text, history_text)
    @history = History.new(history_text)
    @schedules = text.split("\n").
      reject {|l| l =~ /^\s+$/}.
      map {|l| Schedule.new(l, @history)}
  end

  def self.run
    scron = Scron.new(read(SCHEDULE_FILE), read(HISTORY_FILE))
    overdue = scron.schedules.select {|s| s.overdue?}
    nowstr = now.strftime(History::FORMAT)

    logger = File.open(LOG_FILE, "a")
    logger.puts("=> #{nowstr} running")
    return if overdue.size == 0

    overdue.each do |schedule|
      logger.puts("=> #{nowstr} #{schedule.command} (start)")
      output = safe_cmd(schedule.command)
      logger.puts("=> #{nowstr} #{schedule.command} (exit=#{$?.to_i})")
      logger.puts(output) unless output == ''
      if $?.to_i == 0
        scron.history.touch(schedule.command) 
        File.open(HISTORY_FILE, "w") {|f| f.puts scron.history.to_s}
      end
    end
  ensure
    logger.close
  end

  def self.now
    @now ||= begin
      now = DateTime.now
      now += now.offset
      now = now.new_offset('+00:00')
    end
  end

  def self.edit
    `#{EDITOR} #{SCHEDULE_FILE} < \`tty\` > \`tty\``
  end

  private
  def self.safe_cmd(command)
    `#{command}`
  rescue StandardError => error
    error.to_s
  end

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
    @interval = interval.split(',').map {|i| parse_days(i)}.min
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
      day = interval.to_i
      delta = now.day >= day ?
        now.day - day :
        now - last_month(day)
      delta.to_i + 1
    elsif interval =~ /^(\d+)\/(\d+)$/
      year, month, day = Scron.now.year, $1.to_i, $2.to_i
      year -= 1 if Scron.now.month < month ||
                   (Scron.now.month == month && Scron.now.day < day)
      (Scron.now - DateTime.new(year, month, day)).to_i + 1
    elsif interval =~ /^\d+d$/
      interval.to_i
    else
      raise ArgumentError.new("Unable to parse: #{interval}")
    end
  end

  def last_month(day)
    last = Scron.now << 1
    [day, 30, 29, 28].each do |d|
      date = DateTime.new(last.year, last.month, d) rescue nil
      return date if date
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
