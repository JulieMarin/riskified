module Riskified::Adapter
  class Spree < Base
    PAYPAL_SOURCE = "Spree::PaypalExpressCheckout"

    def determine_product_type(product)
      if product.name.downcase.include?("gift card")
        "digital"
      else
        "physical"
      end
    end

    def line_item_category(line_item, depth_order = "ASC")
      if depth_order == "DESC"
        return nil unless line_item.product.taxons.length > 3
      end
      line_item.product.taxons.order("depth #{depth_order}")
        .limit(2).reduce('') {|x, i|
          x + ' ' + i.name
        }.strip
    end

    def adapt_line_items
      @order.line_items.map { |li|
        Riskified::Adapter::LineItem.new(
          price: li.price.to_f,
          quantity: li.quantity,
          title: li.name,
          product_id: li.product.id,
          sku: li.sku,
          category: line_item_category(li), 
          sub_category: line_item_category(li, "DESC"),
          brand: Riskified::BRAND,
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
          Riskified::Adapter::DiscountCode.new(
            amount: a.amount.to_f.abs,
            code: p.code
          )
        }
    end

    def adapt_shipping_lines
      @order.shipments.map {|s|
        shipping_rate = s.shipping_rates.select {|sr| sr.shipping_method_id == s.shipping_method.id}.first

        Riskified::Adapter::ShippingLine.new(
          price: shipping_rate.cost.to_f,
          title: s.shipping_method.name
        )
      }
    end

    def cc_number(credit_card)
      if credit_card.cc_type == "american_express"
        "xxxx-xxxxxxx-#{credit_card.last_digits}"
      else
        "xxxx-xxxx-xxxx-#{credit_card.last_digits}"
      end
    end

    def first_completed_payment
      @order.payments.where(state: "completed").first
    end

    def adapt_payment_details
      p = first_completed_payment
      if p.source.is_a?("Spree::CreditCard".constantize)
        credit_card = p.source
        Riskified::Adapter::CreditCardPaymentDetails.new(
          credit_card_bin: credit_card.bin,
          avs_result_code: p.avs_response,
          cvv_result_code: p.cvv_response_code,
          credit_card_number: cc_number(credit_card),
          credit_card_company: credit_card.cc_type
          )
      elsif p.source.is_a?(Riskified::Adapter::Spree::PAYPAL_SOURCE.constantize)
        paypal = p.source
        Riskified::Adapter::PaypalPaymentDetails.new(
          payer_email: paypal.payer_email,
          payer_status: paypal.payer_status,
          payer_address_status: paypal.payer_address_status,
          protection_eligibility: paypal.protection_eligibility
          )
      end
    end

    def first_purchase_at(user)
      first_purchase = user.orders.where.not(completed_at: nil)
        .order("created_at ASC")
        .first
      first_purchase.completed_at.to_datetime if first_purchase.present?
    end

    def adapt_customer
      user = @order.user
      
      Riskified::Adapter::Customer.new(
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        id: user.id,
        created_at: user.created_at.to_datetime,
        first_purchase_at: first_purchase_at(user), #optional
        orders_count: user.orders.where(state: "completed").count,
        verified_email: user.confirmed_at.present?
        )
    end

    def adapt_address(address)
      return nil if address.nil?
      Riskified::Adapter::Address.new(
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

    def referring_site
      Riskified::DEFAULT_REFERRER
    end

    def gateway
      if first_completed_payment
        first_completed_payment.payment_method.name
      else
        nil
      end
    end

    def adapt
      @adapted_order ||= Riskified::Adapter::Order.new(
        id: @order.id,
        name: @order.name,
        email: @order.email,
        created_at: @order.created_at.to_datetime,
        currency: @order.currency,
        updated_at: @order.updated_at.to_datetime,
        gateway: gateway,
        browser_ip: @order.last_ip_address,
        total_price: @order.total.to_f,
        total_discounts: @order.promo_total.to_f,
        note: @order.number,
        referring_site: referring_site, #?
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