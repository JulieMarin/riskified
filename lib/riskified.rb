require "riskified/version"
require "dotenv"
require "httparty"
require "openssl"

Dotenv.load

require "riskified/adapter"
require "riskified/adapters/base"

module Riskified
  class << self
    attr_accessor :brand
    attr_accessor :default_referrer
  end

  class Client
    class << self
      attr_accessor :sandbox_mode
      attr_accessor :adapter
    end

    include HTTParty
    
    format :json

    API_URL = @sandbox_mode == true ? "https://sandbox.riskified.com" : "https://wh.riskified.com"

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