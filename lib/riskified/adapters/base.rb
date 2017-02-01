module Riskified
  module Adapter
    class Base
      def initialize(order)
        @order = order
        @adapted_order ||= adapt
      end

      def to_json
        @adapted_order.as_json
      end
    end
  end
end