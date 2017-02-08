require "riskified/version"
require "dotenv"
require "httparty"
require "openssl"

Dotenv.load

require "riskified/adapter"
require "riskified/adapters/base"

module Riskified
  BRAND = ""
  DEFAULT_REFERRER = ""

  class Client
    include HTTParty
    format :json

    SANDBOX_MODE = true
    ADAPTER = "Riskified::Adapter::Spree"

    API_URL = SANDBOX_MODE == true ? "https://sandbox.riskified.com" : "https://wh.riskified.com"

    def adapter
      ADAPTER.constantize
    end

    def headers(body)
      {
        "Content-Type" => "application/json",
        "ACCEPT" => "application/vnd.riskified.com; version=2",
        "X-RISKIFIED-SHOP-DOMAIN" => ENV["RISKIFIED_SHOP_DOMAIN"],
        "X-RISKIFIED-HMAC-SHA256" => calc_hmac(body)
      }
    end

    def initialize
      self.class.class_eval do
        base_uri API_URL
      end
      self
    end

    def adapt_order(order)
      adapter.new(order).as_json
    end

    def adapt_checkout(order)
      adapter.new(order).as_checkout(resp).as_json
    end

    def create(order)
      data = {order: adapt_order(order)}.to_json
      self.class.post(
        "/api/create",
        body: data,
        headers: headers(data)
      )
    end

    def submit(order)
      data = {order: adapt_order(order)}.to_json
      self.class.post(
        "/api/submit",
        body: data,
        headers: headers(data)
      )
    end

    def update(order)
      data = {order: adapt_order(order)}.to_json
      self.class.post(
        "/api/create",
        body: data,
        headers: headers(data)
      )
    end

    # optional
    def checkout_denied(order, resp)
      data = {checkout: adapt_checkout(order)}.to_json
      self.class.post(
        "/api/checkout_denied",
        body: data,
        headers: headers(data)
      )
    end

    def calc_hmac(body)
      hmac = OpenSSL::HMAC.hexdigest('SHA256', ENV["RISKIFIED_AUTH_TOKEN"], body)
    end
  end
end