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

    def requires_shipping(product)
      determine_product_type(product) == "physical"
    end

    def line_item_category(line_item, depth_order = "ASC")
      if depth_order == "DESC"
        return nil unless line_item.product.taxons.length > 3
      end
      line_item.product.taxons.order("depth #{depth_order}")
        .limit(2).reduce('') {|x, i|
          x + ' ' + i.name
        }.strip.split(' ').uniq.join(' ')
    end

    def adapt_line_items
      @order.line_items.map { |li|
        attrs = {
          price: li.price.to_f,
          quantity: li.quantity,
          title: li.name,
          product_id: li.product.id,
          sku: li.sku,
          category: line_item_category(li), 
          sub_category: line_item_category(li, "DESC"),
          brand: Riskified::BRAND,
          product_type: determine_product_type(li.product),
          requires_shipping: requires_shipping(li.product)
        }
        if determine_product_type(li.product) == "digital" && li.gift_card.present?
          gc = li.gift_card
          Riskified::Adapter::LineItemDigitalGoods.new(attrs.merge({
            sender_name: gc.from_name,
            photo_uploaded: false,
            photo_url: nil,
            message: gc.message,
            recipient: Riskified::Adapter::Recipient.new(email: gc.to_email)
            }))
        else
          Riskified::Adapter::LineItem.new(attrs)
        end
      }
    end

    def adapt_discount_codes
      @order.adjustments
        .eligible
        .map {|a| 
          promo = if a.source_type == "Spree::StoreCredit" && a.gift_card_id
            OpenStruct.new(code: "GiftCard".constantize.find(a.gift_card_id).code)
          elsif a.source_type == "Spree::PromotionAction"
            a.source.promotion
          end
          {
          adj: a,
          promo: promo
        } }
        .map {|h|
          Riskified::Adapter::DiscountCode.new(
            amount: h[:adj].amount.to_f.abs,
            code: h[:promo].code
          )
        }
    end

    def adapt_shipping_lines
      @order.shipments.map {|s|
        shipping_rate = s.shipping_rates.select {|sr| sr.shipping_method_id == s.shipping_method.id}.first

        Riskified::Adapter::ShippingLine.new(
          price: shipping_rate.cost.to_f,
          title: s.shipping_method.name,
          code:  s.shipping_method.admin_name
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

    def current_payment
      @order.payments.order("created_at DESC").first
    end

    def adapt_payment_details
      p = first_completed_payment
      return nil unless p
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

    def authorization_error_code(resp)
      begin
        resp.message.split(" ").last.gsub('(','').gsub(')','')
      rescue NoMethodError
        nil
      end
    end

    def adapt_payment_details_for_checkout(resp)
      p = current_payment
      if p.source.is_a?("Spree::CreditCard".constantize)
        credit_card = p.source
        Riskified::Adapter::CreditCardPaymentDetails.new(
          credit_card_bin: credit_card.bin,
          avs_result_code: p.avs_response,
          cvv_result_code: p.cvv_response_code,
          credit_card_number: cc_number(credit_card),
          credit_card_company: credit_card.cc_type,
          authorization_error: Riskified::Adapter::AuthorizationError.new(
            created_at: DateTime.now, #todo
            error_code: authorization_error_code(resp)
            )
          )
      end
    end

    def first_purchase_at(user)
      first_purchase = user.orders.where.not(completed_at: nil)
        .order("created_at ASC")
        .first
      first_purchase.completed_at.to_datetime if first_purchase.present?
    end

    def adapt_customer_social(user)
      if user.services.any?
        user.services.map {|s| 
          public_username = s.provider == "google" ? s.info.email : s.info.name
          if s.provider == "facebook"
            account_url = if s.info.link.present?
              s.info.link
            else
              "https://www.facebook.com/app_scoped_user_id/#{s.uid}"
            end
            Riskified::Adapter::Social.new(
              network: s.provider,
              public_username: public_username,
              account_url: account_url,
              email: s.info.email,
              id: s.uid
            )
          else
            Riskified::Adapter::Social.new(
              network: s.provider,
              public_username: public_username,
              email: s.info.email,
              id: s.uid
            )
          end
        }
      end
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
        verified_email: user.confirmed_at.present?,
        social: adapt_customer_social(user)
        )
    end

    def adapt_address(address, type = :shipping, order = nil)
      return nil if address.nil?
      if type == :billing
        Riskified::Adapter::BillingAddress.new(
          first_name: address.firstname,
          last_name: address.lastname,
          country: address.country.try(:name),
          country_code: address.country.iso,
          zip: address.zipcode,
          phone: (order.present? ? order.ship_address.phone : address.phone)
          )
      else
        Riskified::Adapter::Address.new(
          first_name: address.firstname,
          last_name: address.lastname,
          address1: address.address1,
          address2: address.address2,
          company: address.company,
          country: address.country.try(:name),
          country_code: address.country.iso,
          phone: address.phone,
          city: address.city,
          province: address.state.try(:name),
          province_code: address.state.try(:abbr),
          zip: address.zipcode
          )
      end
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

    def adapt_device_type
      return nil unless @order.device_type
      if @order.device_type == "mobile"
        "mobile"
      else
        "web"
      end
    end

    def adapt
      @adapted_order ||= Riskified::Adapter::Order.new(
        id: @order.id,
        name: @order.number,
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
        billing_address: adapt_address(@order.billing_address, :billing, @order),
        shipping_address: adapt_address(@order.shipping_address),
        checkout_id: checkout_id,
        source: adapt_device_type,
        cart_token: @order.guest_token
        )
    end

    def checkout_id
      addr_id = @order.ship_address.id
      payment_id = current_payment.id
      "#{@order.id}-#{addr_id}-#{payment_id}"
    end

    def as_checkout(resp)
      @checkout ||= adapt
      @checkout.id = checkout_id
      @checkout.payment_details = adapt_payment_details_for_checkout(resp)
      @checkout.as_json
    end
  end
end