module Riskified
  module Adapter
    Order = Struct.new(
      :id,
      :checkout_id, #optional
      :name,
      :email,
      :created_at, # DateTime
      :closed_at, #optional DateTime
      :currency,
      :updated_at,
      :gateway,
      :browser_ip,
      :total_price,
      :total_discounts,
      :cancel_reason, #optional
      :cart_token, #optional
      :note,
      :referring_site,
      :line_items, # [LineItem]
      :passengers, #optional
      :discount_codes, # [DiscountCode]
      :shipping_lines, # [ShippingLine]
      :payment_details, # PaymentDetails
      :customer, # Customer
      :billing_address, # Address
      :shipping_address, # Address
      :vendor_id, #optional
      :vendor_name, #optional
      :source, #optional
      :order_type, #optional
      :submission_reason, #optional
      :decision, #optional DecisionDetails
      :client_details, #optional [ClientDetails]
      :charge_free_payment_details #optional
      )
    LineItem = Struct.new(
      :price,
      :quantity,
      :title,
      :product_id,
      :sku, #optional
      :category,
      :sub_category, #optional
      :brand,
      :product_type
      )
    DiscountCode = Struct.new(
      :amount,
      :code
      )
    ShippingLine = Struct.new(
      :price,
      :title,
      :code #optional
      )
    PaymentDetails = Struct.new(
      :credit_card_bin,
      :avs_result_code,
      :cvv_result_code,
      :credit_card_number,
      :credit_card_company,
      :authorization_id, #optional
      :authorization_error #optional
      )
    Customer = Struct.new(
      :email,
      :first_name,
      :last_name,
      :id,
      :created_at,
      :first_purchase_at, #optional
      :orders_count,
      :verified_email,
      :social #optional [Social]
      )
    Social = Struct.new(
      :network,
      :public_username,
      :account_url
      )
    Address = Struct.new(
      :first_name,
      :last_name,
      :address1,
      :address2, #optional
      :company, #optional
      :country,
      :country_code, #optional
      :phone,
      :city,
      :province, #optional
      :province_code, #optional
      :zip #optional
      )
    ClientDetails = Struct.new(
      :accept_language, #optional
      :user_agent #optional
      )

    class Base
      def initialize(order)
        @order = order
        adapt
      end

      def to_json
        adapt.to_hash.to_json
      end
    end


    class Spree < Base
      

      def determine_product_type(product)
        if product.name.downcase.include?("gift card")
          "digital"
        else
          "physical"
        end
      end

      def adapt_line_items
        @order.line_items.map { |li|
          LineItem.new(
            price: li.price.to_f
            quantity: li.quantity
            title: li.name,
            product_id: li.product.id
            sku: li.sku
            category: #li.variant.product.taxons ?
            sub_category: nil, #optional
            brand: Riskified::BRAND
            product_type: determine_product_type(li.product)
            )
        }
      end

      def adapt_discount_codes
        @order.adjustments
          .where(source_type: ['Spree::PromotionAction'])
          .eligible
          .map {|a| a.source.promotion }
          .map {|p|
            DiscountCode.new(
              amount: a.amount.to_f.abs,
              code: p.code
            )
          }
      end

      def adapt_shipping_lines
        @order.shipments.map {|s|
          shipping_rate = s.shipping_rates.select {|sr| sr.shipping_method_id == s.shipping_method.id}.first

          ShippingLine.new(
            price: shipping_rate.cost.to_f
            title: s.shipping_method.name
          )
        }
      end

      def adapt_payment_details
        p = @order.payments.where(state: "completed").first
        credit_card = if p.source.is_a?(Spree::CreditCard)
          p.source
        end
        PaymentDetails.new(
          credit_card_bin: nil, #todo
          avs_result_code: p.avs_response,
          cvv_result_code: p.cvv_response_code,
          credit_card_number: "xxxx-xxxx-xxxx-#{credit_card.last_digits}",
          credit_card_company: credit_card.cc_type
          )
      end

      def adapt_customer
        user = @order.user
        first_purchase = user.orders.where.not(completed_at: nil)
          .order("created_at ASC")
          .first
        first_purchase_at = first_purchase.completed_at.to_datetime if first_purchase.present?
        Customer.new(
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          id: user.id,
          created_at: user.created_at.to_datetime,
          first_purchase_at: first_purchase_at, #optional
          orders_count: user.orders.where(state: "completed").count,
          verified_email: user.confirmed_at.present?,
          social: #todo [Social]
          )
      end

      def adapt_address(address)
        Address.new(
          first_name: address.firstname,
          last_name: address.lastname,
          address1: address.address1,
          address2: address.address2,
          company: address.company,
          country: address.country.name,
          country_code: address.country.iso,
          phone: address.phone,
          city: address.city,
          province: address.state.name,
          province_code: address.state.abbr,
          zip: address.zipcode
          )
      end

      def adapt
        @adapted_order ||= Order.new(
          id: @order.id,
          name: @order.name,
          email: @order.email,
          created_at: @order.created_at.to_datetime,
          currency: @order.currency,
          updated_at: @order.updated_at.to_datetime,
          gateway: @order.payment_method.name,
          browser_ip: nil, #?
          total_price: @order.total.to_f,
          total_discounts: @order.promo_total.to_f,
          note: @order.number,
          referring_site: nil, #?
          line_items: adapt_line_items,
          discount_codes: adapt_discount_codes,
          shipping_lines: adapt_shipping_lines,
          payment_details: adapt_payment_details,
          customer: adapt_customer,
          billing_address: adapt_address(@order.billing_address),
          shipping_address: adapt_address(@order.shipping_address)
          )
      end
    end
  end
end