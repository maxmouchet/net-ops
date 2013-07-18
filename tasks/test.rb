require './downcase_hostname_task'

hosts = %w()

options     = { timeout: 30, prompt: /.+(#|>)/ }
credentials = { username: '', password: '' }

pool = Thread.pool(10)

hosts.each do |host|
  pool.process do
    t = DowncaseHostnameTask.new(host, options, credentials)
    t.work
  end
end

pool.shutdown
