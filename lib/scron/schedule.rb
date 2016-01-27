module Scron
  # Parses a scron configuration line and determines its interval/command
  class Schedule
    attr_reader :interval, :command
    WEEKDAYS = {'Mo' => 1, 'Tu' => 2, 'We' => 3, 'Th' => 4, 'Fr' => 5,
                'Sa' => 6, 'Su' => 7}

    def initialize(line, history)
      interval, command = line.split(/\s+/, 2)
      @interval = interval.split(',').map {|i| parse_days(i)}.min
      @command = command.strip
      @overdue = history[command].nil? || 
                 (App.now - history[command]).to_f > @interval
    end

    def overdue?
      !!@overdue
    end

    private
    # maximum day count requirement for interval to be considered overdue
    # eg "15d" means if command was run "16d" ago it's overdue, if "14d" ago it's not overdue
    def parse_days(interval)
      now = App.now
      if WEEKDAYS[interval] # specific day of week, eg "Mo" or "Tu"
        (now.cwday - WEEKDAYS[interval]) % 7 + 1
      elsif interval =~ /^\d+(st|nd|rd|th)$/ # specific day of month, eg "1st" or "15th"
        day = interval.to_i
        delta = now.day >= day ?
          now.day - day :
          now - last_month(day)
        delta.to_i + 1
      elsif interval =~ /^(\d+)\/(\d+)$/ # specific day of year, eg "4/15" or "7/4"
        year, month, day = App.now.year, $1.to_i, $2.to_i
        year -= 1 if App.now.month < month ||
                     (App.now.month == month && App.now.day < day)
        (App.now - DateTime.new(year, month, day)).to_i + 1
      elsif interval =~ /^\d+d$/ # every number of days, eg "1d" or "14d"
        interval.to_i
      else
        raise ArgumentError.new("Unable to parse: #{interval}")
      end
    end

    def last_month(day)
      last = App.now << 1
      [day, 30, 29, 28].each do |d|
        date = DateTime.new(last.year, last.month, d) rescue nil
        return date if date
      end
    end
  end
end
