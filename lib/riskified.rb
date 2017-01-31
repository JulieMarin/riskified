require "riskified/version"
require 'dotenv/load'
require "httparty"

module Riskified
  BRAND = "DSTLD"
  class Client
    include HTTParty
    format :json

    base_uri

    API_URL = "http://test.com"
    ADAPTER = Adapter::Spree

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
      HTTParty.post(
        "#{API_URL}/api/create",
        query: order.to_json,
        headers: headers
      )
    end

    def submit(order)
      HTTParty.post(
        "#{API_URL}/api/submit",
        query: order.to_json,
        headers: headers
      )
    end

    def update(order)
      HTTParty.post(
        "#{API_URL}/api/create",
        query: order.to_json,
        headers: headers
      )
    end

end
