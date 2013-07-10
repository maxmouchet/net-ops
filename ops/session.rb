require 'yaml'
require 'net/telnet'
require 'net/ssh/telnet'

require './transport_unavailable'

module Net

  module Ops

    # Provides a DSL for interacting with Cisco switches and routers.
    class Session

      # Initialize a new session.
      #
      # @param [String] host the target host.
      #
      # @param [Hash<Symbol, String>] options an Hash containing the transport options.
      # @option options [String] :timeout The timeout before raising an exception while waiting for output.
      # @option options [String, Regexp] :prompt A String or a Regexp that match the prompt of the device.
      #
      # @param [Logger] logger the logger to use.
      #
      # @return [Session] the new session.
      def initialize(host, options, logger = nil)
        @host    = host
        @options = options
        setup_logger(logger)
      end

      # Open the session to the device.
      #
      # @param [Hash<Symbol, String>] credentials an Hash containing the credentials used to login.
      # @option credentials [String] :username The username.
      # @option credentials [String] :password The password.
      #
      # @return [void]
      # @raise  [Net::Ops::TransportUnavailable] if the session cannot be opened.
      def open(credentials)
        @credentials = credentials

        @logger.debug(@host) { "Opening session as #{ credentials[:username] }" }

        @session ||= Session.open_ssh_session    @host, @options, credentials
        @session ||= Session.open_telnet_session @host, @options, credentials

        fail Net::Ops::TransportUnavailable unless @session
      end

      # Close the session to the device.
      #
      # @return [void]
      def close
        @logger.debug(@host) { 'Closing session' }
        @session.close
      end

      # Measure the latency.
      #
      # @return [Integer] the time to run and retrieve the output of a command in milliseconds.
      def latency
        t1 = Time.now
        @session.cmd('')
        t2 = Time.now

        Utils.time_diff_m(t1, t2)
      end

      # Send the specified command to the device and wait for the output.
      #
      # @param  [String] command the command to run.
      # @return [String] the output of the command.
      def run(command)
        @logger.debug(@host) { "Executing #{ command }" }

        output = ''
        @session.cmd(command) { |c| output += c }

        output
      end

      # Get the specified item on the device.
      # Equivalent to the Cisco show command.
      #
      # @param item [String] the item to get.
      # @return [String] the item.
      def get(item)
        run("show #{ item }")
      end

      # Set the value for the specified item on the device.
      #
      # @param item  [String] the item to configure.
      # @param value [String] the value to assign to the item.
      # @return [String] the eventual output of the command.
      def set(item, value)
        run("#{ item } #{ value }")
      end

      # Enable the specified item on the device.
      #
      # @param item [String] the item to enable.
      # @return [String] the eventual output of the command.
      def enable(item)
        run(item)
      end

      # Disable the specified item on the device.
      # Equivalent to the Cisco no command.
      #
      # @param item [String] the item to enable.
      # @return [String] the eventual output of the command.
      def disable(item)
        run("no #{ item }")
      end

      # Run the specified command in the privileged mode on the device.
      #
      # @param  [String] command the command to run.
      # @return [String] the output of the command.
      def exec(command)
        ensure_mode(:privileged)
        run(command)
      end

      # Run the specified command in the configuration mode on the device.
      #
      # @param  [String] command the command to run.
      # @return [String] the output of the command.
      def config(command)
        ensure_mode(:configuration)
        run(command)
      end

      # Save the configuration of the device.
      # Equivalent to the Cisco copy running-config startup-config command.
      # @return [void]
      def write!
        ensure_mode(:privileged)
        exec('write memory')
      end

      # Run the specified block in the privileged mode on the device.
      #
      # @param  [Block] block the block to run.
      # @return [void]
      def privileged(&block)
        ensure_mode(:privileged)
        instance_eval(&block)
      end

      # Run the specified block in the configuration mode on the device.
      #
      # @param  [Block] block the block to run.
      # @return [void]
      def configuration(options = nil, &block)
        ensure_mode(:configuration)
        instance_eval(&block)

        write! if options == :enforce_save
      end

      # Open an SSH session to the specified host using net/ssh/telnet.
      #
      # @param host [String] the destination host.
      # @param options [Hash]
      # @param credentials [Hash] credentials to use to connect.
      def self.open_ssh_session(host, options, credentials)
        session = nil

        ssh = Net::SSH.start(host, credentials[:username], :password => credentials[:password])
        session = Net::SSH::Telnet.new('Session' => ssh,
                                       'Timeout' => options[:timeout],
                                       'Prompt'  => options[:prompt])

      rescue Errno::ECONNREFUSED => e
        @@logger.error(host) { e.class }
        session = nil

      rescue Net::SSH::AuthenticationFailed => e
        @@logger.error(host) { e.class }
        session = nil

      rescue Exception => e
        @@logger.error(host) { e.class }

      return session
      end

      # Open a Telnet session to the specified host using net/ssh.
      #
      # @param host [String] the destination host.
      # @param options [Hash]
      # @param credentials [Hash] credentials to use to connect.
      def self.open_telnet_session(host, options, credentials)
        session = nil

        session = Net::Telnet.new('Host' => host,
                                  'Timeout' => options[:timeout],
                                  'Prompt'  => options[:prompt])

        session.cmd('String' => credentials[:username],
                    'Match'  => /.+assword.+/)

        session.cmd(credentials[:password])

        return session

      rescue Errno::ECONNREFUSED => e
        @@logger.error(host) { e.class }
        session = nil

      rescue Net::OpenTimeout => e
        @@logger.error(host) { e.class }
        session = nil

      rescue Exception => e
        @@logger.error(host) { e.class }
        session = nil

      return session
      end

      private

      # Create a default logger if none is specified.
      #
      # @param  [Logger] logger the logger to use.
      # @return [void]
      def setup_logger(logger = nil)
        # If a logger is specified we replace the existing.
        @logger = logger

        # Otherwise we create a new one.
        logger = Logger.new(STDOUT)
        logger.level = Logger::DEBUG
        @logger ||= logger
      end

      # Get the current command mode.
      #
      # @return [Symbol] the current command mode.
      def get_mode
        match = @session.cmd('') { |c| /.+(?<text>\([\w-]+\))?(?<char>#|>)/.match(c) }
        mode  = nil

        if match && match['char']

          mode = case match['char']
                 when '>' then :user
                 when '#' then :privileged
                 end

        elsif match && match['text']
          mode = match['text'].to_sym

        end

        mode
      end

      # Ensure the CLI is currently in the specified command mode.
      #
      # @param  [Symbol] mode the target command mode.
      # @return [void]
      def ensure_mode(mode)
        case mode

        when :user
          run('end') if configuration?

        when :privileged
          run('end') if configuration?
          enable_privileged(@credentials['password']) if user?

        when :configuration
          run('configure terminal') unless configuration?

        end
      end

      # Check if the CLI is in user mode.
      #
      # @return [Boolean]
      def user?
        get_mode == :user
      end

      # Check if the CLI is in privileged mode.
      #
      # @return [Boolean]
      def privileged?
        get_mode == :privileged
      end

      # Check if the CLI is in configuration mode.
      #
      # @return [Boolean]
      def configuration?
        get_mode.to_s.include?('config')
      end

      # Go from user mode to privileged mode.
      #
      # @param  [String] the enable password.
      # @return [void]
      def enable_privileged(password)
        @session.cmd('String' => 'enable', 'Match' => /.+assword.+/)
        @session.cmd(password)
      end

    end

  end
end