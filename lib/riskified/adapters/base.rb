module Riskified
  module Adapter
    class Base
      def initialize(order)
        @order = order
        adapt
      end

      def to_json
        adapt.as_json
      end
    end
  end
end