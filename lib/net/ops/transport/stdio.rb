module Net; module Ops; module Transport

  # Use terminal I/O. Useful for debugging.
  class StdIO

    def initialize(host, options, credentials)
      $stdout.puts host.inspect
      $stdout.puts options.inspect
      $stdout.puts credentials.inspect
    end

    def close
      $stdout.puts 'Closing connection'
    end

    def cmd(options)
      $stdout.puts 'cmd: ' + options.inspect
      unless options.strip.empty?
        $stdout.print '=> '
        $stdin.gets
      end
    end

    def login(options, password = nil)
      $stdout.puts 'login: ' + options.inspect
    end

    def puts(string)
      $stdout.puts 'puts: ' + string
    end

  end

end; end; end
