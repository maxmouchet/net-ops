require 'net/ssh/telnet'

module Net
  module Ops
    module Transport
    
      #
      class SSH
        
        # Open an SSH session to the specified host using net/ssh/telnet.
        #
        # @param host [String] the destination host.
        # @param options [Hash]
        # @param credentials [Hash] credentials to use to connect.
        def self.open(host, options, credentials)
          session = nil

          ssh = Net::SSH.start(host, credentials[:username], :password => credentials[:password])
          session = Net::SSH::Telnet.new('Session' => ssh,
                                         'Timeout' => options[:timeout],
                                         'Prompt'  => options[:prompt])

        rescue Errno::ECONNREFUSED => e
          session = nil

        rescue Net::SSH::AuthenticationFailed => e
          session = nil

        rescue Exception => e
          session = nil

        return session
        end
        
      end
    
    end
  end
end