Gem::Specification.new do |s|
  s.name        = 'net-ops'
  s.version     = '0.0.4.pre'
  s.date        = '2013-07-16'
  s.summary     = 'Net::Ops'
  s.description = 'Framework to automate daily operations on network devices.'
  s.authors     = ['Maxime Mouchet']
  s.email       = ['max@maxmouchet.com']
  s.files       = ['lib/net/ops.rb']
  s.add_runtime_dependency 'thread', '~> 0.1'
  s.add_runtime_dependency 'net-ssh-telnet', '~> 0.0.2'
  s.license     = 'MIT'
  s.homepage    = 'http://github.com/maxmouchet/qscripts'
end
