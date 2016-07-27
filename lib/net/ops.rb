require 'yaml'
require 'logger'
require 'thread/pool'

require 'net/ops/version'

require 'net/ops/task'
require 'net/ops/parser'
require 'net/ops/session'

require 'net/ops/transport/ssh'
require 'net/ops/transport/telnet'
require 'net/ops/transport/serial'

module Net

  # Ruby framework for interacting with network devices.
  module Ops

    class TransportUnavailable < Exception; end
    class IOSInvalidInput      < Exception; end

  end

end
