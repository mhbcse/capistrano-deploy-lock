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

Deploy with custom lock:

    $ cap production deploy:with_lock

Manually Lock (without deploy):
  
    $ cap production deploy:lock

Manually Unlock (if necessary):

    $ cap production deploy:unlock


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
