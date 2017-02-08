module Riskified
  module Adapter
    class KeywordStruct < Struct
      def initialize(**kwargs)
        super(kwargs.keys)
        kwargs.each { |k, v| self[k] = v }
      end
    end
    
    Order = KeywordStruct.new(
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
    LineItem = KeywordStruct.new(
      :price,
      :quantity,
      :title,
      :product_id,
      :sku, #optional
      :category,
      :sub_category, #optional
      :brand,
      :product_type,
      :requires_shipping, #optional
      )
    LineItemDigitalGoods = KeywordStruct.new(
      :price,
      :quantity,
      :title,
      :product_id,
      :sku, #optional
      :category,
      :sub_category, #optional
      :brand,
      :product_type,
      :requires_shipping, #optional
      :sender_name,
      :photo_uploaded,
      :photo_url,
      :message,
      :recipient # [Recipient]
      )
    DiscountCode = KeywordStruct.new(
      :amount,
      :code
      )
    ShippingLine = KeywordStruct.new(
      :price,
      :title,
      :code #optional
      )
    CreditCardPaymentDetails = KeywordStruct.new(
      :credit_card_bin,
      :avs_result_code,
      :cvv_result_code,
      :credit_card_number,
      :credit_card_company,
      :authorization_id, #optional
      :authorization_error #optional AuthorizationError
      )
    PaypalPaymentDetails = KeywordStruct.new(
      :payer_email,
      :payer_status,
      :payer_address_status,
      :protection_eligibility
      )
    Customer = KeywordStruct.new(
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
    Social = KeywordStruct.new(
      :network,
      :public_username,
      :account_url,
      :email,
      :id
      )
    Address = KeywordStruct.new(
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
    BillingAddress = KeywordStruct.new(
      :first_name,
      :last_name,
      :country,
      :country_code,
      :zip
      )
    ClientDetails = KeywordStruct.new(
      :accept_language, #optional
      :user_agent #optional
      )
    AuthorizationError = KeywordStruct.new(
      :created_at,
      :error_code,
      :message #optional
      )
    Recipient = KeywordStruct.new(
      :email
      )
  end
end