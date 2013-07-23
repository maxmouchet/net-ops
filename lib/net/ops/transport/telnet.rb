require 'net/telnet'

module Net; module Ops; module Transport

  #
  class Telnet

    # Open a Telnet session to the specified host using net/ssh.
    #
    # @param host [String] the destination host.
    # @param options [Hash]
    # @param credentials [Hash] credentials to use to connect.
    def self.open(host, options, credentials)
      session = nil

      session = Net::Telsnet.new('Host' => host,
                                'Timeout' => options[:timeout],
                                'Prompt'  => options[:prompt])

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

      return session

    rescue Errno::ECONNREFUSED => e
      session = nil

    rescue Net::OpenTimeout => e
      session = nil

    rescue Exception => e
      session = nil

    return session
    end

  end

end; end; end