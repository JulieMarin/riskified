require_relative "../../app/models/riskified/adapters/spree.rb"

Riskified.brand = "Your Brand"
Riskified.default_referrer = "www.brand.com"
Riskified::Client.sandbox_mode = !Rails.env.production?
Riskified::Client.adapter = Riskified::Adapter::Spree