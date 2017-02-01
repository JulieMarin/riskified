require "riskified/version"
require "dotenv/load"
require "httparty"
require "spree_core"

autoload :Adapter, "riskified/adapter"
autoload :BaseAdapter, "riskified/adapters/base"
autoload :SpreeAdapter, "riskified/adapters/spree"

module Riskified
  BRAND = "DSTLD"
  DEFAULT_REFERRER = "www.dstld.com"

  class Client
    include HTTParty
    format :json

    API_URL = "http://riskified.com"

    base_uri API_URL
    adapter = Riskified::Adapter::Spree

    def headers
      {
        "ACCEPT" => "application/vnd.riskified.com; version=2",
        "X-RISKIFIED-SHOP-DOMAIN" => ENV["X_RISKIFIED_SHOP_DOMAIN"],
        "X-RISKIFIED-HMAC-SHA256" => ENV["X_RISKIFIED_HMAC_SHA256"]
      }
    end

    def initialize(response=nil)
      self
    end

    def create(order)
      post(
        "/api/create",
        query: adapter.new(order).to_json,
        headers: headers
      )
    end

    def submit(order)
      post(
        "/api/submit",
        query: adapter.new(order).to_json,
        headers: headers
      )
    end

    def update(order)
      post(
        "/api/create",
        query: adapter.new(order).to_json,
        headers: headers
      )
    end
  end
end