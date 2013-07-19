require './downcase_hostname_task'

hosts = %w( 192.168.0.104 )

credentials = YAML.load_file('credentials.yml')


options     = { timeout: 30, prompt: /.+(#|>)/ }
credentials = { username: credentials.fetch('username'),
                password: credentials.fetch('username') }

pool = Thread.pool(10)

hosts.each do |host|
  # pool.process do
    t = DowncaseHostnameTask.new(host, options, credentials)
    t.work
  # end
end

pool.shutdown