# encoding: utf-8

require 'rubygems'
require 'net/telnet'
require 'net/ssh/telnet'
require 'yaml'

module Net

  module Ops

    #
    class Session

      def initialize(host, options, logger = nil)
        @host = host
        @options = options


      end



      def open(credentials)
        @@logger.debug(@host) { "Opening session as #{credentials[:username]}" }

        @session ||= Session.open_ssh_session(@host, @options, credentials)
        @session ||= Session.open_telnet_session(@host, @options, credentials)

        fail 'No transport available' unless @session

        @session.cmd('') do |c|
          if c.include?('>')
            @@logger.debug(@host) { 'User mode prompt (>) detected' }
            @@logger.debug(@host) { 'Enable' }
            @session.cmd('String' => 'enable', 'Match' => /.+assword.+/)
            @session.cmd(credentials[:password])
          end
        end
      end

      def close
        @@logger.debug(@host) { 'Closing session' }
      end

      # Run a command on a device.
      #
      # @param session [Net::Telnet] the session to the switch.
      # @param command [String] the command to execute.
      # @return [String] the command result.
      def run_command(command)
        @@logger.debug(@host) { "Executing #{command}" }

        output = ''

        t1 = Time.now
        @session.cmd(command) { |c| output += c }
        t2 = Time.now

        exec_time = Utils.time_diff_m(t1, t2)
        @@logger.debug(@host) { "Command took #{exec_time}ms" }

        if exec_time > 700
          @@logger.warn(@host) { "High latency detected (#{exec_time}ms)" }
        end

        output
      end

      def exec_command(command)
        ensure_mode(:privileged)
        self.run_command(command)
      end

      def conf_command(command)
        @@logger.debug(@host) { 'Switching to configure terminal mode' }
        self.run_command('configure terminal')
        self.run_command(command)
      end

      def write!
        self.exec_command('write')
      end

      def get(item)
        ensure_mode(:privileged)
        self.run_command("show #{ item }")
      end

      def set(item, value)
        self.run_command("#{ item } #{ value }")
      end

      def enable(item)
        self.run_command(item)
      end

      def disable(item)
        self.run_command("no #{ item }")
      end

      def ensure_mode(mode)
        case mode

        when :privileged
          self.run_command('end')

        when :configuration
          self.run_command('configure terminal')

        end
      end

      def privileged(&block)
        ensure_mode(:privileged)
        instance_eval(&block)
      end

      def configuration(options = nil, &block)
        ensure_mode(:configuration)
        instance_eval(&block)
        if options == :enforce_save
          write!
        end
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

    end

    #
    class Parser

      def initialize(file)
        @regexs = YAML.load_file(file)
      end

      def parse(command, output)
        results = []

        regex = Regexp.new(explore_tree(command.split(/ /)).fetch('regex').delete(' '))
        puts regex.inspect

        output.each_line do |line|
          results << regex.match(line) if regex.match(line)
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

    #
    class Utils

      def self.time_diff_m(start, finish)
        (finish - start) * 1000.0
      end

    end

  end
end