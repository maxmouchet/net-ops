require 'yaml'
require 'logger'
require 'thread/pool'

#Dir['../lib/net/transport/*.rb'].each { |file| require file }
require 'net/transport/ssh'
require 'net/transport/telnet'

module Net
  module Ops

    # Provides a DSL for interacting with Cisco switches and routers.
    class Session

      attr_reader :transport
      attr_reader :transports

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
      def initialize(host, options = { timeout: 10, prompt: /.+(#|>|\])/ }, logger = nil)
        @host    = host
        @options = options
        @transports = []

        setup_logger(logger)

        Net::Ops::Transport.constants.each do |c|
          register_transport(c) if Class === Net::Ops::Transport.const_get(c)
        end
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

        @transports.each do |transport|
          @transport ||= transport.open(@host, @options, credentials)
        end

        fail Net::Ops::TransportUnavailable unless @transport
      end

      # Close the session to the device.
      #
      # @return [void]
      def close
        @logger.debug(@host) { 'Closing session' }
        @transport.close
        @transport = nil
      end

      # Measure the latency.
      #
      # @return [Integer] the time to run and retrieve the output of a command in milliseconds.
      def latency
        t1 = Time.now
        @transport.cmd('')
        t2 = Time.now

        (t2 - t1) * 1000.0
      end

      # Send the specified command to the device and wait for the output.
      #
      # @param  [String] command the command to run.
      # @return [String] the output of the command.
      def run(command)
        @logger.debug("#{ @host } (#{ get_mode })") { "Executing #{ command }" }

        output = ''
        @transport.cmd(command) { |c| output += c }

        # @logger.debug("#{ @host } (#{ get_mode })") { output }
        # @logger.warn(@host) { 'Net::Ops::IOSInvalidInput'; puts output } if /nvalid input detected/.match(output)
        fail Net::Ops::IOSInvalidInput if /nvalid input detected/.match(output)

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

      def zeroize(item)
        @logger.debug(@host) { "Executing #{ item } zeroize" }

        @transport.cmd('String' => "#{ item } zeroize", 'Match' => /.+/)
        @transport.cmd('yes')
      end

      def generate(item, options)
        run("#{ item } generate #{ options }")
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

      def interface(interface, &block)
        ensure_mode(:configuration)

        run("interface #{ interface }")
        instance_eval(&block)
      end

      def interfaces(interfaces = /.+/, &block)
        ints = privileged do
          get('interfaces status').select do |int|
            interfaces.match("#{ int['short_type'] }#{ int['port_number'] }")
          end
        end

        ints.each do |int|
          interface("#{ int['short_type'] }#{ int['port_number'] }") do
            instance_eval(&block)
          end
        end
      end

      def lines(lines, &block)
        ensure_mode(:configuration)

        run("line #{ lines }")
        instance_eval(&block)
      end

      private

      def register_transport(klass)
        @logger.debug(@host) { "Registering transport #{ klass }" }
        @transports << Net::Ops::Transport.const_get(klass)
      end

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
        prompt = ''
        @transport.cmd('') { |c| prompt += c }
        match = /(?<hostname>[^\(-\)]+)(\((?<text>[\w\-]+)\))?(?<char>#|>)/.match(prompt)

        mode  = nil

        if match && match['char']

          mode = case match['char']
                 when '>' then :user
                 when '#' then :privileged
                 end

        end

        if match && match['text']
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
          enable_privileged(@credentials[:password]) if user?

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
        @transport.cmd('String' => 'enable', 'Match' => /.+assword.+/)
        @transport.cmd(password)
      end

    end

    class Parser

      def initialize(file)
        @regexs = YAML.load_file(file)
      end

      def parse(command, output)
        results = []
        path    = explore_tree(command.split(/ /))

        if path.has_key?('regex')
          regex = Regexp.new(path.fetch('regex').delete(' '))

          output.each_line do |line|
            results << regex.match(line) if regex.match(line)
          end

        else results = output
        end

        results
      end

      private

      def explore_tree(path)
        level = @regexs['cisco']

        path.each { |p| level[p] ? level = level[p] : break }

        level
      end

    end

    class Task
      include Net::Ops

      def initialize(id)
        @id = id

        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end

      def log(severity, message)
        @logger.add(severity, message, @id)
      end

      def info(message)
        log(Logger::INFO, message)
      end

      def warn(message)
        log(Logger::WARN, message)
      end

      def error(message)
        log(Logger::ERROR, message)
      end

    end

    #
    class TransportUnavailable < Exception; end
    class IOSInvalidInput < Exception; end

  end
end