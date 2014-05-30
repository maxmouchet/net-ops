module Net; module Ops

  # Manage the connection to a device and the execution of the commands on it.
  # TODO: Transaction (commit, rollback) ?
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
    def initialize(host, dsl, transports, options = { timeout: 10, prompt: /.+(#|>|\])/ }, logger = nil)
      @host    = host.strip
      @options = options
      @transports = []

      setup_logger(logger)
      set_dsl(dsl.to_s.capitalize)

      # Register transports
      transports.each do |transport_symbol|
        canonical_name = 'Net::Ops::Transport::' + transport_symbol.to_s
        begin
          register_transport(canonical_name) if Class === Net::Ops::Transport.const_get(canonical_name)
        rescue
          @logger.error(@host) { "Unknown transport #{ canonical_name }" }
        end
      end

      # Net::Ops::Transport.constants.each do |c|
      #   register_transport(c) if Class === Net::Ops::Transport.const_get(c)
      # end
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
        begin
          @transport ||= transport.new(@host, @options, credentials)
        rescue Exception => e
          @logger.debug(@host) { e }
          next
        end
      end

      fail Net::Ops::TransportUnavailable unless @transport

      @dsl_instance = @dsl.new(@transport, @logger)
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

    def method_missing(m, *args, &block)
      # Search in all dsls
      @dsl_instance.send(m, *args, &block)
      # TODO: Warn method unsupported in DSL if not found
    end

    private

    def set_dsl(klass)
      @logger.debug(@host) { "Using DSL #{ klass }"}
      @dsl = Net::Ops::DSL.const_get(klass)
    end

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
      logger = ColorLogger.new(STDOUT)
      logger.level = Logger::DEBUG
      @logger ||= logger
    end

  end

end; end
