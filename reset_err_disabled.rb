# encoding: utf-8

# Quick script for resetting interfaces in err-disabled state on Cisco IOS switches.
# I use it in production but if I were you I won't.
# Use at your own risks.

require 'rubygems'
require 'net/telnet'
require 'net/ssh/telnet'
require 'logger'

# [Regex] for parsing `show interface statuts` output.
INT_STATUS_REGEX = /^(Fa|Gi)(\d+\/\d+(\/\d+)?)\s+(.+)?\s(connected|notconnect|disabled|err-disabled)\s+(\w+|\d+)\s+(auto|a-full)\s+(auto|a-1000)\s(.+)/

# [Array] containings hosts to connect to.
hosts = %w(10.0.0.1)

options     = { timeout: 10, prompt: /.+#/ }
credentials = { username: '', password: '' }

@logger = Logger.new(STDOUT)
@logger.level = Logger::DEBUG

# Return `true` if the interface need to be reseted.
def need_reset?(int)
  int[5] == 'err-disabled'
end

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
def get_interfaces(session)
  output = exec_command(session, 'show interface status')
  parse_interfaces(output)
end

# Convert `show interface status` output to an array of interfaces.
#
# @return [Array] the interfaces.
def parse_interfaces(output)
  output.lines.select { |l| INT_STATUS_REGEX.match(l) != nil }.map! { |l| l = INT_STATUS_REGEX.match(l) }
end

# Execute a command on a device.
#
# @param session [Net::Telnet] the session to the switch.
# @param command [String] the command to execute.
# @return [String] the command result.
def exec_command(session, command)
  output = ''
  session.cmd(command) { |c| output += c }
  output
end

# Save the configuration to startup-config.
#
# @param session [Net::Telnet] the session to the switch.
def write!(session)
  session.cmd{'copy run start'}
end

def open_ssh_session(host, options, credentials)
  session = nil

  ssh = Net::SSH.start(host, credentials[:username], :password => credentials[:password])
  session = Net::SSH::Telnet.new('Session' => ssh,
                                 'Timeout' => options[:timeout],
                                 'Prompt'  => options[:prompt])

rescue Errno::ECONNREFUSED => e
  @logger.error e.class

rescue Net::SSH::AuthenticationFailed => e
  @logger.error e.class

return session
end

def open_telnet_session(host, options, credentials)
  session = nil

  session = Net::Telnet.new('Host' => host,
                            'Timeout' => options[:timeout],
                            'Prompt'  => options[:prompt])

  session.cmd(credentials[:username])
  session.cmd(credentials[:password])

rescue Errno::ECONNREFUSED => e
  @logger.error e.class

return session
end

hosts.each do |host|
  @logger.info "Connecting to #{ host }"

  session ||= open_ssh_session(host, options, credentials)
  session ||= open_telnet_session(host, options, credentials)

  fail 'No transport available' if session == nil

  get_interfaces(session).each { |int| reset!(int) if need_reset?(int) }

  write!(session)

  session.close
end