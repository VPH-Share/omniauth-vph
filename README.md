# Omniauth Vph

Use the VPH-Share ticket strategy as a middleware in your application:

```ruby
use OmniAuth::Strategies::Vphticket,
  host: 'https://portal.vph-share.eu',
  roles_map: {cloudadmin: 'admin', developer: 'developer'}
  ssl_verify: true #or false if self signed cert is used
```

VPH-Share Ticket is required to use this strategy. It can be retrieved after successful log in into Master Interface, located in `host` URL.

VPH-Share security mechanism is role based. `roles_map` allows to map VPH-Share
roles into application specific roles.

`ssl_verify` true/false flag is used to turn on or off ssl validation by Faraday client, while trigering ticket validation request.

The result of invoking this strategy is a object with following elements:

```
login
email
full_name
roles
```

inside `roles` array application specific roles are returned based on `roles_map` hash.

## Installation

Add this line to your application's Gemfile:

    gem 'omniauth-vph'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-vph

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
