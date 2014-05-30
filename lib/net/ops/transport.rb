module Net; module Ops

  # A Transport is a class providing methods to send commands to a device.
  # The following methods should be implemented:
  #
  #     def initialize(host, options, credentials)
  #       # Open the connection
  #     end
  #
  #     def close
  #       # Close the connection
  #     end
  #
  #     def cmd(options)
  #       # TODO: Write doc
  #     end
  #
  #     def login
  #       # TODO: Write doc
  #     end
  #
  #     def puts
  #       # TODO: Write doc
  #     end
  module Transport; end

end; end
