# encoding: utf-8

require 'rubygems'
require 'net/telnet'
require 'net/ssh/telnet'
require 'yaml'

module QScripts

  #
  module Helpers

    #
    class Session

      def initialize(host, options)
        @host = host
        @options = options
      end

      def open(credentials)
        session ||= Session.open_ssh_session(@host, @options, credentials)
        session ||= Session.open_telnet_session(@host, @options, credentials)
      end

      # Execute a command on a device.
      #
      # @param session [Net::Telnet] the session to the switch.
      # @param command [String] the command to execute.
      # @return [String] the command result.
      def exec_command(command)
        output = ''
        session.cmd(command) { |c| output += c }
        output
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
        @logger.error e.class
        session = nil

      rescue Net::SSH::AuthenticationFailed => e
        @logger.error e.class
        session = nil

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

        session.cmd(credentials[:username])
        session.cmd(credentials[:password])

      rescue Errno::ECONNREFUSED => e
        @logger.error e.class
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

  end
end