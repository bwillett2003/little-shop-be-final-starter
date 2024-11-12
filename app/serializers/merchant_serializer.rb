class MerchantSerializer
  include JSONAPI::Serializer
  attributes :name, :coupons_count, :invoice_coupon_count

  attribute :item_count, if: Proc.new { |merchant, params|
    params && params[:include_count] == true
  } do |merchant|
    merchant.item_count
  end

  attribute :coupons_count do |merchant|
    merchant.coupons.count
  end

  attribute :invoice_coupon_count do |merchant|
    merchant.invoices.where.not(coupon_id: nil).count
  end
end
