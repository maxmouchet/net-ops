module Net; module Ops

  #
  class Task
    include Net::Ops

    def initialize(id)
      @id = id

      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
    end

    def log(severity, message)
      @logger.add(severity, message, @id)
    end

    def info(message)
      log(Logger::INFO, message)
    end

    def warn(message)
      log(Logger::WARN, message)
    end

    def error(message)
      log(Logger::ERROR, message)
    end

  end

end; end