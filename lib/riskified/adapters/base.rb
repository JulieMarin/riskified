module Riskified
  module Adapter
    class Base
      attr_accessor :adapted_order
      
      def initialize(order)
        @order = order
        @adapted_order ||= adapt
        @adapted_order.as_json
      end

      def as_json
        @adapted_order.as_json
      end
    end
  end
end