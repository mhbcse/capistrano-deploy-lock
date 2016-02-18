# Capistrano Deploy Lock 1.0.1

Deploy lock feature for Capistrano 3.4.x

Lock deploy when deployment is running or custom lock to prevent further deployment for Capistrano 3.

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-deploy-lock', '~> 1.0'
    gem 'capistrano'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install capistrano-deploy-lock

## Usage

Require in `Capfile` to use the default task:

```ruby
require 'capistrano/deploy-lock'
```

Deploy with default configuration:

Just run normal capistrano command, deploy lock will work automatically. 
    
    $ cap production deploy
    
You will get the following tasks

```ruby
cap production deploy:with_lock         # Deploy with custom lock
cap production deploy:lock              # Lock manually (without deploy)
cap production deploy:unlock            # Unlock manually
cap production deploy:unlock:force      # Unlock forcefully
```
    
Configurable options (copy into deploy.rb), shown here with examples:

```ruby
# Deploy Lock File
# default value: File.join(shared_path, "deploy-lock.yml")
set :deploy_lock_file, -> { File.join(shared_path, "deploy-lock.yml") }

# Deploy Lock Roles
# default value: :app
set :deploy_lock_roles, -> { :app }

# Deploy lock expiry (in second)
# Default 15 minutes
set :default_lock_expiry, (15 * 60)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Credits

cap-deploy-lock is maintained by [Maruf Hasan Bulbul](http://www.mhbweb.com).

## License

© 2016 Maruf Hasan Bulbul. It is free software and may be redistributed.
