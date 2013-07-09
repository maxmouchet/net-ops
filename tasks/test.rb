require './downcase_hostname_task'

host = 'sa-qcmtlv-11-09'
options     = { timeout: 10, prompt: /.+(#|>)/ }
credentials = { username: '', password: '' }

t = DowncaseHostnameTask.new(host, options, credentials)
t.work