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
      attr_accessor :refund_serializer
    end

    include HTTParty

    format :json

    API_URL = @sandbox_mode == true ? "https://sandbox.riskified.com" : "https://wh.riskified.com"

    def adapter
      self.class.adapter
    end

    def refund_serializer
      self.class.refund_serializer
    end

    def initialize
      self.class.class_eval do
        base_uri API_URL
      end
      self
    end

    def headers(body)
      {
        "Content-Type" => "application/json",
        "ACCEPT" => "application/vnd.riskified.com; version=2",
        "X-RISKIFIED-SHOP-DOMAIN" => ENV["RISKIFIED_SHOP_DOMAIN"],
        "X-RISKIFIED-HMAC-SHA256" => calc_hmac(body)
      }
    end

    def post(path, data)
      self.class.post(
        path,
        body: data,
        headers: headers(data)
      )
    end

    def adapt_order(order)
      adapter.new(order).as_json
    end

    def adapt_order_with_decision_details(order)
      adapter.new(order).with_decision_details.as_json
    end

    def adapt_checkout(order, resp)
      adapter.new(order).as_checkout(resp).as_json
    end

    def create(order)
      data = {order: adapt_order(order)}.to_json
      post("/api/create", data)
    end

    def submit(order)
      data = {order: adapt_order(order)}.to_json
      post("/api/submit", data)
    end

    def update(order)
      data = {order: adapt_order(order)}.to_json
      post("/api/create", data)
    end

    def historical(orders)
      data = {
        orders: orders.map {|o|
          adapt_order_with_decision_details(o)
        }
      }.as_json
      post("/api/historical", data.to_json)
    end

    # optional
    def checkout_denied(order, resp)
      data = {checkout: adapt_checkout(order, resp)}.to_json
      post("/api/checkout_denied", data)
    end

    def cancel(order)
      post("/api/cancel", adapter.new(order).cancellation_data.to_json)
    end

    def refund(r)
      post("/api/refund", refund_serializer.new(r).to_json)
    end

    def calc_hmac(body)
      hmac = OpenSSL::HMAC.hexdigest('SHA256', ENV["RISKIFIED_AUTH_TOKEN"], body)
    end
  end
end