require 'yaml'
require 'ap'

regexs = YAML.load_file('regexs.yml')
ap regexs

sample = File.read('sample.txt')

r = Regexp.new regexs['cisco']['interfaces']['status']['_regex']

sample.each_line do |line|
  ap r.match(line)
end