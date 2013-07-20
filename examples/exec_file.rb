require 'rubygems'
require '../lib/net/ops'
require 'yaml'

credentials = YAML.load_file('credentials.yml')
commands = File.open('commands.txt')
hosts    = File.open('hosts.txt')

hosts.each_line do |host|

  session = Net::Ops::Session.new(host)
  session.open({ username: credentials.fetch('username'),
                password: credentials.fetch('password') })

  session.privileged { set 'terminal length', 0 }

  commands.each_line do |command|
    puts @session.run(command)
  end

end