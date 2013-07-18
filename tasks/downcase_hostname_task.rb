# Task for converting hostname to lowercase.
# Handle devices with SSH by regenerating crypto key.

require '../lib/net/ops'

class DowncaseHostnameTask < Net::Ops::Task

  def initialize(host, options, credentials)
    @host        = host
    @options     = options
    @credentials = credentials

    @session = Session.new(host, options)

    super(host)
  end

  # This is where all the logic is.
  def work
  
    # First we need to open the session.
    # I create a helper because we will have to
    # (dis)connect several times during this task.
    connect

    # Set terminal length to 0 otherwise too long outputs will cause
    # Net::Telnet to timeout while waiting for the prompt.
    @session.privileged { set 'terminal length', 0 }

    # Check ip http secure-server
    https = /^ip http secure-server/.match(@session.get('run | i ip http'))
    
    # Get hostname from show version.
    match = /(?<hostname>.+)\s+uptime.+/.match(@session.get('version'))

    # Check if we found the hostname
    # and convert it if needed.
    # `match['hostname'].downcase!` return nil
    # if the hostname is already in lowercase.
    if !https && match && match['hostname'].downcase!
    
      # If we are connected using SSH we enable Telnet
      # in case bad crypto key prevent us from logging.
      enable_telnet if ssh?
      
      # Convert the hostname
      info "Converting #{ match['hostname'] } => #{ match['hostname'].downcase }"
      @session.configuration(:enforce_save) { set 'hostname', match['hostname'].downcase }
      
      # If SSH is enabled regenerate crypto key
      # and verify SSH is still working.
      if ssh?

        # Delete the existing crypto key
        # then regenerate it.
        regenerate_crypto
        
        # Close the session and reopen it
        # to see if we are still able to
        # connect via SSH.
        info 'Verifying SSH is still working'
        reconnect
        
        # If SSH is still working we can disable Telnet.
        if ssh?
          info 'Hooray SSH is still working !'
          disable_telnet
        else warn 'SSH is not working :('
        end
        
      end

    elsif match && !match['hostname'].downcase! then info 'Nothing to do'
    else error 'Unable to find hostname'; end
    
    @session.close
  end
  
  # Below are the helpers methods.
  # I wrote them to be DRY and reduce code.

  # Open the session and show the transport used.
  def connect
    info "Connecting to #{ @host }"

    begin @session.open(@credentials)
    rescue Exception => e
      error e.message
    end
    
    info "Transport is #{ @session.transport.class }"
  end
  
  # Alias for session.close
  def disconnect
    @session.close
  end
  
  # Disconnect, then reconnect.
  def reconnect
    disconnect; connect
  end
  
  # True if the transport it SSH.
  def ssh?
    @session.transport.class.to_s.include?('SSH')
  end
  
  # Enable Telnet and SSH on all VTY lines.
  def enable_telnet
    info 'Enabling Telnet'
    
    @session.configuration(:enforce_save) do
      lines('vty 0 4')  { set 'transport input', 'ssh telnet' }
      # lines('vty 5 15') { set 'transport input', 'ssh telnet' }
    end
  end
  
  # Set SSH only on all VTY lines.
  def disable_telnet
    info 'Disabling Telnet'
    
    @session.configuration(:enforce_save) do
      lines('vty 0 4')  { set 'transport input', 'ssh' }
      # lines('vty 5 15') { set 'transport input', 'ssh' }
    end
  end
  
  # Delete the crypto key then regenerate it.
  def regenerate_crypto
    info 'Regenerate crypto key'
    
    @session.configuration(:enforce_save) do
      zeroize 'crypto key'
      begin
        generate 'crypto key', 'rsa general-keys modulus 2048'
      rescue Exception => e
        generate 'crypto key', 'rsa modulus 2048'
      end
      set 'ip ssh version', 2
    end
  end

end