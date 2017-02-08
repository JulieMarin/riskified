module Riskified
  BRAND = "Your Brand"
  DEFAULT_REFERRER = "www.brand.com"
  class Client
    SANDBOX_MODE = !Rails.env.production?
    ADAPTER = "Riskified::Adapter::Spree"
  end
end