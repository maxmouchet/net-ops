module Net; module Ops

  #
  class Parser

    def initialize(file)
      @regexs = YAML.load_file(file)
    end

    def parse(command, output)
      results = []
      path    = explore_tree(command.split(/ /))

      if path.has_key?('regex')
        regex = Regexp.new(path.fetch('regex').delete(' '))

        output.each_line do |line|
          results << regex.match(line) if regex.match(line)
        end

      else results = output
      end

      results
    end

    private

    def explore_tree(path)
      level = @regexs['cisco']

      path.each { |p| level[p] ? level = level[p] : break }

      level
    end

  end

end; end