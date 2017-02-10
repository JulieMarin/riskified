module Riskified
  module Tools
    module HistoricalData
      class << self
        attr_accessor :client

        def send_orders
          @orders = Spree::Order.where(created_at: "01/01/2016".to_datetime...DateTime.now).where("state != 'cart' AND state != 'resumed'")
          @client ||= Riskified::Client.new
          @client.historical(@orders)
        end
      end
    end
  end
end