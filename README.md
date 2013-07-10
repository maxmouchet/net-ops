# Net::Ops

## Overview

## Install

```bash
gem install net-ops
```

## Usage

```ruby
require 'net/ops'
```

### Opening a session

```ruby
host    = 'router1.local'
options = { timeout: 10, prompt: /.+(#|>)/ }

@session = Net::Ops::Session.new(host, options)
```

```ruby
begin @session.open({ username: '', password: '' })
rescue Net::Ops::TransportUnavailable => e
  error e.message
end
```

### Executing commands

```ruby
@session.configuration(:enforce_save) do
  set 'hostname', 'r1.local'
end

@session.get 'version'
```
