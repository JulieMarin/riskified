# Riskified

Use Riskified with Ruby. Sample shows use with Rails and Spree.

TODO: test

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'riskified'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install riskified

## Usage
send spree order to riskified
```ruby
require 'riskified' # or add to gemfile
client = Riskified::Client.new
o = Spree::Order.where.not(completed_at: nil).last
resp = client.create(o)
# => {"order"=>{"status"=>"submitted", "id"=>"123", "description"=>"Under review by Riskified"}}
```
    
serialize spree order to Riskified API format
```ruby
o = Spree::Order.where.not(completed_at: nil).last
a = Riskified::Adapter::Spree.new(o)
a.to_json
```

## Use with Rails
```ruby
Look at the sample/rails folder

# Riskified gem settings in spree app
# /models/riskified/riskified.rb
module Riskified
  BRAND = "DSTLD"
  DEFAULT_REFERRER = "www.dstld.com"
  SANDBOX_MODE = !Rails.env.production?
end
```

## Required env variables
    RISKIFIED_SHOP_DOMAIN = www.brand.com
    RISKIFIED_AUTH_TOKEN = sha256 auth hash from riskified


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/riskified.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

