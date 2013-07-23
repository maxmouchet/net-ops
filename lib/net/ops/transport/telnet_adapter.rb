require 'net/telnet'

module Net; module Ops; module Transport

  #
  class TelnetAdapter < Net::Telnet

    def initialize(host, options, credentials)
      super('Host' => host,
            'Timeout' => options[:timeout],
            'Prompt'  => options[:prompt])

      login
    end

    private

    def login
      output = ''
      session.cmd('String' => '', 'Match'  => /.+/) { |c| output += c }

      if /[Uu]sername:/.match(output) then
        session.cmd('String' => credentials[:username],
                  'Match'  => /.+/)
        session.cmd(credentials[:password])
      end

      if /[Pp]assword:/.match(output) then
        session.cmd(credentials[:password])
      end
    end

  end

end; end; end