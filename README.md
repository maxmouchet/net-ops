# Net::Ops

## Ruby framework for interacting with network devices

Computers are made to simplify our lives, not make them more complicated. They don't mind doing 1000x the same thing but too often people do repetitive tasks at hand because they don't know how to write scripts.  
I developed this little Ruby module to simplify daily operations on network devices like switches, routers, and access-points.

### Prerequisites

I made it to be as simple as possible but, if you want to understand how it works or extend it, you will need some Ruby knowledge.  
[The Little Book of Ruby](http://www.sapphiresteel.com/The-Little-Book-Of-Ruby) is a good introduction altough convention are not always clear.  
[Design Patterns](http://www.amazon.fr/Design-Patterns-Elements-Reusable-Object-Oriented/dp/0201633612) and [Design Patterns in Ruby](http://www.pearsonhighered.com/educator/product/Design-Patterns-in-Ruby/9780321490452.page)
are must read.  
[Stack Overflow](http://stackoverflow.com/) is a good place in case of problem.

### Compatibility

Tested with Cisco IOS and IOS XE devices. Should work partially with NX-OS.  
Not compatible with IOS XR and non-Cisco devices but it would be possible to add an abstraction layer in ops.rb to support other brands.

I implemented only two [transports](#transports), Telnet and SSH. If you want to use another protocol (a serial link for example) you will have to implement it.


## Installation

First, you need a Ruby interpreter. [MRI](http://en.wikipedia.org/wiki/Ruby_MRI), the reference implementation, is a good choice. You can download it on [ruby-lang.org](http://www.ruby-lang.org/en/downloads/).  
Note that MRI is already included in Mac OS X and most of the Linux distributions.  
On Ubuntu you can install it with `apt-get install ruby1.9.3`.   
There is other Ruby implementation like [JRuby](http://jruby.org/) or [MagLev](http://maglev.github.io/) but I have not tested my code with them.  

Then you should intall net-ops. You can get the latest version from RubyGems:
```bash
gem install 'net-ops'
```

Or build it from the source:
```bash
gem build net-ops.gemspec
gem install ./net-ops-x.y.z.gem
```

## Getting started

You need to require net/ops in all your scripts and [tasks](#tasks) (we will talk about this later):

```ruby
require 'net/ops'
```

### Storing credentials

Writing directly your username and password directly in the script is a bad idea.  
If you want to keep things simple you can store them in a [YAML](http://en.wikipedia.org/wiki/YAML) file with the following structure:
```yml
# credentials.yml
username: ledog
password: r5Xqx8
```
Then, to use them in your script:

```ruby
credentials = YAML.load_file('credentials.yml')

credentials.fetch('username') #=> 'ledog'
credentials.fetch('password') #=> 'r5Xqx8'
```

### Connecting to a device

Connecting to a device is a two-step process: create a session, and open it.  
Nothing is sent on the transport until you open the session.

#### Create the session

To create a Session you just need to specify the hostname (or the IP address):

```ruby
@session = Net::Ops::Session.new('router1.local')
```

##### Options

You can also customize the timeout (`Integer`) and the prompt (`Regexp`) if you want:

```ruby
host    = 'router1.local'
options = { timeout: 10, prompt: /.+(#|>)/ }

@session = Net::Ops::Session.new(host, options)
```

##### Logging

By default `Session` logs everything from `Level::DEBUG` to `STDOUT`. You can specify a custom logger to the constructor.  
For example to log everything from `Level::WARN` to a file:
```ruby
logger = Logger.new('logfile.log')
logger.level = Logger::WARN

@session = Net::Ops::Session.new(host, options, logger)
```

#### Open the session

Given you loaded your credentials from a YAML file you can open the session like this:

```ruby
@session.open({ username: credentials.fetch('username'),
               password: credentials.fetch('password') })
```

Note that this doesn't handle `Net::Ops::TransportUnavailable` which is raised when no transport can be used to open the session.
To show the error and prevent your script from stopping:

```ruby
begin @session.open({ username: '', password: '' })
rescue Net::Ops::TransportUnavailable => e
  puts "There is an error: #{e.message}"
end
```

#### Close the session

It is generally not needed to close the session since the Ruby garbage collector will do it automatically.  
However if you need to, you can call `close`:
```ruby
@session.close
```

### Sending commands

Once the session is opened you can send commands to the device. Net::Ops offer three abstraction levels that are described below.

#### Raw commands

The basic way to send a command and get the output is the `run(command)` method.  
It send command (`String`) followed by a carriage return to the device, wait for the prompt, and return what happened between.  
For example, to get `show int status` output:

```ruby
puts @session.run('show int status')
```

`run(command)` is pretty low-level but sometimes you will want to play directly with the transport.  
For example when the command ask for confirmation and doesn't return the prompt (like `reload`). In this case you can do something like this:
```ruby
transport = @session.transport
transport.cmd('String' => 'reload', 'Match' => /.+confirm.+/)
transport.cmd('yes')
```

To get the output with `transport.cmd` you need to pass a block:

```ruby
transport = @session.transport
transport.cmd('show version') { |c| puts c }
```


#### Basic commands

To make your script easier to read, Net::Ops provides methods which are basically alias to Cisco commands.  
These are `get(item)`, `set(item, value)`, `enable(item)`, and `disable(item)`:
```ruby
@session.get 'interfaces status'
# send 'show interfaces status'

@session.set 'terminal length', 0
# send 'terminal length 0'

@session.enable 'ip http secure-server'
# send 'ip http secure-server'

@session.disable 'spanning-tree bpduguard'
# send 'no spanning-tree bpduguard'
```

These methods allow you to write script that are easily readable but you can do much more by combining them with the [DSL](http://en.wikipedia.org/wiki/Domain-specific_language) that Net::Ops provides.

#### Domain-specific language

Currently the DSL is made of five methods:
* `privileged(&block)`
* `configuration(options = nil, &block)`
* `interface(interface, &block)`
* `interfaces(interfaces, &block)`
* `lines(lines, &block)`

They allow you to run commands in the specified context. Note that don't have to prefix methods with `@session` since the block is evalued inside the session.

Here's an example of how to use it:
```ruby
# Here we pass a block to be executed in the privileged mode.
@session.privileged do

  # Let's get interfaces status.
  sw_interfaces = get 'interfaces status'
  
  # Show disabled interfaces
  nc_interfaces = sw_interfaces.select { |int| int['status'] == 'disabled' }
  puts nc_interfaces
  
end

# Do some stuff in configuration mode.
@session.configuration do
  
  # Add description to Gi1/0/2.
  # Note the singular/plural in interface(s).
  # interface accept only String as an argument.
  # interfaces accept Array, Regexp, and String.
  interface('Gi1/0/2') do
    set 'description', 'I am Gi1/0/2'
  end
  
  # Disable bpduguard on all Gig interfaces.
  interfaces(/Gi1\/0/) do
    disable 'spanning-tree bpduguard'
  end
  
end

# Copy to startup-config
@session.write!

# Do something else in configuration mode
# but automatically write this time.
@session.configuration(:enforce_save) do
  disable 'ip http secure-server'
end
```

#### Other commands

* `write!`
* `zeroize(item)`
* `generate(item, options)`

Example :

```ruby
# Delete the crypto key
@session.zeroize 'crypto key'

# Regenerate it
@session.generate 'crypto key', 'rsa general-keys modulus 2048'

# Save running-config
@session.write!
```

## Tasks
Net::Ops allow to define tasks that perform a specific action and run it on several devices in parallel while handling errors and providing easy logging.  

### Definition
To define a task you should create a new class that inherit from `Task` and define `initialize` and `work` methods:

```ruby
# my_task.rb
class MyTask < Net::Ops::Task

  def initialize(id)
    # Setup your stuff.
    super(id)
  end

  def work
    # Place your logic here.
  end
  
end
```

`id` is an identifier that should be unique for each instance of your task. You can use whatever you want, for example the hostname of the device you are currently working on.  

### Execution
To run a task you can basically instance it and call work:

```ruby
t = MyTask.new('task1')
t.work
```

However you may want to run several tasks in parallel to speed up things. You can do that thanks to [thread/pool](https://github.com/meh/ruby-thread):

```ruby
hosts = %w( host1 host2 host3 )
max_conn = 2

pool = Thread.pool(max_conn)

hosts.each do |hosts|
  pool.process { MyTask.new(host).work }
end

pool.shutdown
```

## Transports

### Built-in

### Custom
```ruby
class MyCustomTransport

  def self.open(host, options, credentials)
    session = # Do what you need to get a session to the host.
    return session
  end
  
end
```

## Documentation
You can get the documentation via gem with `gem server`.
Or generate it manually with `rake doc`.

## Todo - Ideas