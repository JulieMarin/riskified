module Riskified
  module Tools
    require 'yaml'
    CHARGEBACKS = YAML.load_file("app/models/riskified/tools/chargebacks.yml")

    class DecisionDetailRetriever
      attr_accessor :external_status
      attr_accessor :decided_at
      attr_accessor :reason

      def initialize(order)
        @order = order
        @chargebacks = {}
        get_external_status
        if ["chargeback_fraud", "chargeback_not_fraud"].include?(@external_status)
          get_decided_at
          get_reason
        end
        self
      end

      def get_external_status
        # ["address", "returned", "complete", "canceled", "payment", "confirm", "awaiting_return", "delivery"] 
        @external_status = case @order.state
          when "complete"
            chargeback.try(:[], "external_status") || "approved"
          when "canceled"
            "canceled"
          when "address", "payment", "delivery", "confirm"
            "checkout"
          else # "returned", "awaiting_return"
            "approved"
          end
      end

      def get_decided_at
        return nil unless @chargebacks[@order.number]
        DateTime.strptime(@chargebacks[@order.number]["chargeback_date"], "%m/%d/%y")
      end

      def get_reason
        return nil unless @chargebacks[@order.number]
        @chargebacks[@order.number]["chargeback_reason"]
      end

      

      def chargeback
        if Riskified::Tools::CHARGEBACKS.map {|o| o["order_number"]}.include?(@order.number)
          @chargebacks[@order.number] = Riskified::Tools::CHARGEBACKS.find {|o| o["order_number"] == @order.number}
        else
          nil
        end
      end
    end
  end
end

