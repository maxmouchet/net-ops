require 'net/ssh/telnet'

module Net; module Ops; module Transport

  #
  class SSHAdapter < Net::SSH::Telnet

    def initialize(host, options, credentials)
      super('Host'     => host,
            'Username' => credentials[:username],
            'Password' => credentials[:password],
            'Timeout'  => options[:timeout],
            'Prompt'   => options[:prompt])
    end

  end

end; end; end