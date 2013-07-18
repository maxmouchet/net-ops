# Sample script that show basic usage of Net::Ops.
# For more information refer to the documentation.
# To generate it run `yardoc lib/net/ops/session.rb`.

# Add lib/ to the PATH.
$:.unshift File.join(File.dirname(__FILE__), *%w[lib])

require 'rubygems'
require 'net/ops'
require 'yaml'

# Load credentials from credentials.yml.
#
# File format is :
# username: myusername
# password: mypassword
credentials = YAML.load_file('credentials.yml')

# Define the timeout and the prompt (optional).
# Net::Ops::Session.new default to
# { timeout: 10, prompt: /.+(#|>)/ }
options = { timeout: 10, prompt: /.+(#|>)/ }

# Create a logger (optional).
# Net::Ops::Session.setup_logger default to
# logger = Logger.new(STDOUT)
# logger.level = Logger::DEBUG
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

# Create a session to sa-qcmtlv-11-09 (1).
# This is the exhaustive form with all optionals params.
session = Net::Ops::Session.new('sa-qcmtlv-11-09', options, logger)

# OR

# Create a session to sa-qcmtlv-11-09 (2).
# This is the short form without the optional params.
# See the documentation/code for default values.
session = Net::Ops::Session.new('sa-qcmtlv-11-09')

# Open the session using the specified credentials.
# This form provides the full hash in case
# key names are not :username and :password.
# Or if you want to specify credentials directly.
session.open({ username: credentials.fetch('username'),
               password: credentials.fetch('password') })

# Set terminal length to 0 otherwise too long outputs will cause
# Net::Telnet to timeout while waiting for the prompt.
session.privileged { set 'terminal length', 0 }

# Here we pass a block to be executed in the privileged mode.
session.privileged do

  # Let's get interfaces status.
  sw_interfaces = get 'interfaces status'
  
  # Show disabled interfaces
  @nc_interfaces = sw_interfaces.select { |int| int['status'] == 'disabled' }
  puts @nc_interfaces
  
end

# Do some stuff in configuration mode.
session.configuration do

  # Add description to Gi1/0/2.
  # Note the singular/plural in interface(s).
  # interface accept only String as an argument.
  # interfaces accept Array, Regexp, and String.
  interface('Gi1/0/2') do
    set 'description', 'I am Gi1/0/2'
  end
  
  # Disable bpduguard on all Gig interfaces.
  interfaces(/Gi1\/0/) do
    disable 'spanning-tree bpduguard'
  end
  
end

# Copy to startup-config
session.write!

# Do something else in configuration mode
# but automatically write this time.
session.configuration(:enforce_save) do
  disable 'ip http secure-server'
end

# Close the session.
# Optionnal since Ruby garbage collector should do that for us.
session.close