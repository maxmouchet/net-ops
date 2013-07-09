# encoding: utf-8

# Quick script for resetting interfaces in err-disabled state on Cisco IOS switches.
# I use it in production but if I were you I won't.
# Use at your own risks.

require './helpers'
require 'logger'

module QScripts

  #
  module ResetErrDisabled
    include QScripts::Helpers

    # Array containings hosts to connect to.
    # hosts = ARGV
    # hosts = File.read('hosts.txt').lines
    hosts = %w(10.0.0.1)

    options     = { timeout: 10, prompt: /.+#/ }
    credentials = { username: '', password: '' }

    @parser = Parser.new('regexs.yml')

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    # @logger.level = Logger::DEBUG

    # Reset the interface.
    #
    # @param session [Net::Telnet] the session to the switch.
    # @param interface [Array] the interface to reset.
    def reset!(session, interface)
      interface_name = interface[1] + interface[2]

      @logger.info("Reseting #{ interface_name } on #{ session.host }")

      session.cmd{'configuraton terminal'}
      session.cmd("interface #{ interface_name }")
      session.cmd('shutdown')
      session.cmd('no shutdown')
      session.cmd{'end'}
    end

    # Return the interfaces of a switch and their status.
    #
    # @param session [Net::Telnet] the session to the switch.
    # @return [Array] the interfaces.
    def get_err_interfaces(session, parser)
      output = session.exec_command('show interfaces status err-disabled')
      parser.parse('interfaces status', output)
    end

    # Save the configuration to startup-config.
    # I don't use copy run start because it asks for confirmation.
    #
    # @param session [Net::Telnet] the session to the switch.
    def write!(session)
      session.cmd{'write'}
    end

    hosts.each do |host|
      @logger.info "Connecting to #{ host }"

      session = Session.new(host, options)
      session.open(credentials)

      fail 'No transport available' if session == nil

      get_err_interfaces(session, @parser).each { |int| reset!(session, int) }

      write!(session)

      session.close
    end

  end
end