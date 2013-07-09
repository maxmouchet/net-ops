# encoding: utf-8

# Quick script for converting hostnames to downcase.

require 'rubygems'
require 'thread/pool'

require './helpers'
require 'logger'
require 'pp'

module QScripts

  module ConvertHostname
    include QScripts::Helpers

    # Array containings hosts to connect to.
    # hosts = ARGV
    hosts = File.read('hosts.txt').lines.map { |line| line = line.strip! }
    # hosts = %w(sa-qcmtlv-11-09)

    options     = { timeout: 10, prompt: /.+(#|>)/ }
    credentials = { username: '', password: '' }

    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    
    def self.work(host, options, credentials, logger)
      logger.info(host) { "Connecting to #{ host }" }

      session = Session.new(host, options)
      
      begin session.open(credentials)
      rescue Exception => e
        logger.error(host) { e.message }
      end
      
      # Avoid truncated outputs
      session.exec_command('terminal length 0')
      
      # Get hostname from show version
      sh_ver_output = session.exec_command('show version')
      match = (/(?<hostname>.+)\s+uptime.+/.match(sh_ver_output))
      
      # Convert hostname if needed
      if match && match['hostname'].downcase!
        logger.info(host) { "Converting #{match['hostname']} => #{match['hostname'].downcase!}" }
        
        #session.conf_command("hostname #{match['hostname'].downcase!}")        
        #session.write!
      elsif match && !match['hostname'].downcase!
        logger.info(host) { 'Nothing to do' }
      else
        logger.error(host) { 'Unable to find hostname' }
      end

      session.close
    end
    
    pool = Thread.pool(4)
    
    hosts.each do |host|
      pool.process { work(host, options, credentials, logger) }
    end
    
    pool.shutdown

  end
end
