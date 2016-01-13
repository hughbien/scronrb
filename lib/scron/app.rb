module Scron
  class App
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
      scron = App.new(read(SCHEDULE_FILE), read(HISTORY_FILE))
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
end
