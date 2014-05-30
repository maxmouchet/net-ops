module Net; module Ops

  # Provides colored logging to the terminal.
  class ColorLogger < Logger

    def initialize(logdev)
      super(logdev)

      original_formatter = Logger::Formatter.new
      self.formatter = proc do |severity, datetime, progname, msg|
        severity = case severity
        when 'DEBUG'
          Color.blue + severity + Color.clear
        when 'INFO'
          Color.green + severity + Color.clear
        when 'WARN'
          Color.yellow + severity + Color.clear
        when 'ERROR'
          Color.red + severity + Color.clear
        end
        original_formatter.call(severity, datetime, progname, msg)
      end
    end

  end

end; end
