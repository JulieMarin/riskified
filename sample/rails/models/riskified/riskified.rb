module Riskified
  @@brand = "Your Brand"
  @@default_referrer = "www.brand.com"
  class Client
    @@sandbox_mode = !Rails.env.production?
    @@adapter = "Riskified::Adapter::Spree"
  end
end