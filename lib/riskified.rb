require "riskified/version"
require "dotenv/load"
require "httparty"

module Riskified
  BRAND = "DSTLD"
  DEFAULT_REFERRER = "www.dstld.com"

  class Client
    include HTTParty
    format :json

    API_URL = "http://riskified.com"

    base_uri API_URL
    adapter = Adapter::Spree

    def headers
      {
        "ACCEPT" => "application/vnd.riskified.com; version=2",
        "X-RISKIFIED-SHOP-DOMAIN" => ENV["X-RISKIFIED-SHOP-DOMAIN"]
        "X-RISKIFIED-HMAC-SHA256" => ENV["X-RISKIFIED-HMAC-SHA256"]
      }
    end

    def initialize(response)
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
