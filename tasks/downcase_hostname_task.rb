require './task'
require '../helpers'

class DowncaseHostnameTask < Task
  include QScripts::Helpers

  def initialize(host, options, credentials)
    @host        = host
    @options     = options
    @credentials = credentials

    @session = Session.new(host, options)

    super(host)
  end

  def work
    info "Connecting to #{ @host }"

    begin @session.open(@credentials)
    rescue Exception => e
      error e.message
    end

    @session.privileged { set 'terminal length', 0 }

    match = /(?<hostname>.+)\s+uptime.+/.match(@session.get('version'))

    # Convert hostname if needed
    if match && match['hostname'].downcase!
      info "Converting #{ match['hostname'] } => #{ match['hostname'].downcase! }"
      @session.configuration(:enforce_save) { set 'hostname', match['hostname'].downcase! }

    elsif match && !match['hostname'].downcase! then info 'Nothing to do'
    else error 'Unable to find hostname'; end

    @session.close
  end

end