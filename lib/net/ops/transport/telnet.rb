require 'net/telnet'

module Net; module Ops; module Transport

  #
  class Telnet < Net::Telnet

    def initialize(host, options, credentials)
      super('Host'    => host,
            'Timeout' => options[:timeout],
            'Prompt'  => options[:prompt])

      login(credentials)
    end

    private

    def login(credentials)
      output = ''
      self.cmd('String' => '', 'Match'  => /.+/) { |c| output += c }

      if /[Uu]sername:/.match(output) then
        self.cmd('String' => credentials[:username],
                  'Match'  => /.+/)
        self.cmd(credentials[:password])
      end

      if /[Pp]assword:/.match(output) then
        self.cmd(credentials[:password])
      end
    end

  end

end; end; end