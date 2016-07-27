require 'net/ops'

@port = '/dev/ttyUSB0'
@options     = { speed: 9600 }
@credentials = {}

@session = Net::Ops::Session.new(@port, @options)

begin @session.open(@credentials)
rescue Exception => e
  error e.message
end

@session.run("term len 0")
puts @session.get("int status | i Gi")
puts @session.latency

@session.close
