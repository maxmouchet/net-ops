module Net; module Ops; module Transport

  class Text

    def initialize(host, options, credentials)
      @file = File.open('debug.txt', 'w')
      @file.puts host.inspect
      @file.puts options.inspect
      @file.puts credentials.inspect
    end

    def close
      @file.puts 'Closing connection'
    end

    def cmd(options)
      @file.puts 'cmd: ' + options.inspect
    end

    def login(options, password = nil)
      @file.puts 'login: ' + options.inspect
    end

    def puts(string)
      @file.puts 'puts: ' + string
    end

  end

end; end; end
