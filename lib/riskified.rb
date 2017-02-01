require "riskified/version"
require "dotenv"
require "httparty"
require "spree_core"

Dotenv.load

require "riskified/adapter"
require "riskified/adapters/base"
require "riskified/adapters/spree"

module Riskified
  BRAND = "DSTLD"
  DEFAULT_REFERRER = "www.dstld.com"

  class Client
    include HTTParty
    format :json

    API_URL = "http://riskified.com"

    base_uri API_URL

    def adapter
      Riskified::Adapter::Spree
    end

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
        query: {order: adapter.new(order).as_json},
        headers: headers
      )
    end

    def submit(order)
      post(
        "/api/submit",
        query: {order: adapter.new(order).as_json},
        headers: headers
      )
    end

    def update(order)
      post(
        "/api/create",
        query: {order: adapter.new(order).as_json},
        headers: headers
      )
    end

    # optional
    def checkout_denied(order, resp)
      post(
        "/api/checkout_denied",
        query: {checkout: adapter.new(order).as_checkout(resp).as_json},
        headers: headers
      )
    end
  end
end