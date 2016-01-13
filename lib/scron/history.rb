module Scron
  # Parses/updates the history of last run commands
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
      @history[command] = App.now
    end

    def to_s
      lines = []
      @history.each do |command, timestamp|
        lines << "#{timestamp.strftime(FORMAT)} #{command}"
      end
      lines.join("\n")
    end
  end
end
