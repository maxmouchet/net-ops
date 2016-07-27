require 'rubyserial'

module Net; module Ops; module Transport

  #
  class Serial

    def initialize(port, options, credentials)
      @serialport = ::Serial.new(port, options[:speed], 8)
    end

    def close
      puts 'TODO close()'
    end

    def cmd(command)
      @serialport.write("#{command}\n")

      output = ''
      while !output.match(/^Switch.+/) do
        output += @serialport.read(255)
      end

      # OPTIMIZE
      output = output.split("\r\n").drop(1).reverse.drop(1).reverse.join("\n")

      yield(output) if block_given?
    end

  end

end; end; end
