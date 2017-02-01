require "riskified/version"
require "dotenv"
require "httparty"
require "spree_core"
require "openssl"

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

    API_URL = "https://sandbox.riskified.com"

    base_uri API_URL

    def adapter
      Riskified::Adapter::Spree
    end

    def headers(body)
      {
        "Content-Type" => "application/json",
        "ACCEPT" => "application/vnd.riskified.com; version=2",
        "X-RISKIFIED-SHOP-DOMAIN" => ENV["RISKIFIED_SHOP_DOMAIN"],
        "X-RISKIFIED-HMAC-SHA256" => calc_hmac(body)
      }
    end

    def initialize(sandbox=true)
      if sandbox == false
        self.class.class_eval do
          base_uri "https://production.riskified.com"
        end
      end
      self
    end

    def create(order)
      data = {order: adapter.new(order)}.to_json
      self.class.post(
        "/api/create",
        body: data,
        headers: headers(data)
      )
    end

    def submit(order)
      data = {order: adapter.new(order)}.to_json
      self.class.post(
        "/api/submit",
        body: data,
        headers: headers(data)
      )
    end

    def update(order)
      data = {order: adapter.new(order)}.to_json
      self.class.post(
        "/api/create",
        body: data,
        headers: headers(data)
      )
    end

    # optional
    def checkout_denied(order, resp)
      data = {checkout: adapter.new(order).as_checkout(resp)}.to_json
      self.class.post(
        "/api/checkout_denied",
        body: data,
        headers: headers(data)
      )
    end

    private

    def calc_hmac(body)
      digest = OpenSSL::Digest.new('sha256')
      hmac = OpenSSL::HMAC.hexdigest(digest, ENV["RISKIFIED_AUTH_TOKEN"], body.to_json)
    end
  end
end