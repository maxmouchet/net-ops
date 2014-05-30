module Net; module Ops

  # A DSL is a stateless class containing methods for interacting
  # with specific devices and operating systems.
  # The DSL has access to the transport and the logger of the session.
  # The methods shouldn't rely on a state kept by the instance of the DSL
  # because it may be destroyed and instanciated several times during one session.
  module DSL; end

end; end
