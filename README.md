# Omniauth::Launchpad
Build status: [![Build Status](https://travis-ci.org/joaopapereira/omniauth-launchpad.png?branch=master)](https://travis-ci.org/joaopapereira/omniauth-launchpad)

This gem allows the user to login with the launchpad account

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-launchpad'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-launchpad

## Usage

Add the middleware to a Rails app in config/initializers/omniauth.rb:
```
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :launchpad, CONSUMER_KEY
end
```

## Contributing

1. Fork it ( https://github.com/joaopapereira/omniauth-launchpad/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
