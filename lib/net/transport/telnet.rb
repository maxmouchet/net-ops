require 'net/telnet'

module Net
  module Ops
    module Transport
    
      #
      class Telnet
      
        # Open a Telnet session to the specified host using net/ssh.
        #
        # @param host [String] the destination host.
        # @param options [Hash]
        # @param credentials [Hash] credentials to use to connect.
        def self.open(host, options, credentials)
          session = nil

          session = Net::Telnet.new('Host' => host,
                                    'Timeout' => options[:timeout],
                                    'Prompt'  => options[:prompt])

          session.cmd('String' => credentials[:username],
                      'Match'  => /.+assword.+/)

          session.cmd(credentials[:password])

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
      
    end
  end
end