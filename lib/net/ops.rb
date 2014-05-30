require 'yaml'
require 'logger'
require 'thread/pool'
require 'term/ansicolor'

require 'net/ops/version'

require 'net/ops/dsl'
require 'net/ops/task'
require 'net/ops/parser'
require 'net/ops/session'
require 'net/ops/color_logger'

require 'net/ops/transport'

module Net

  # Ruby framework for interacting with network devices.
  module Ops

    class TransportUnavailable < Exception; end
    class IOSInvalidInput      < Exception; end

    class Color
      extend Term::ANSIColor
    end

  end

end
