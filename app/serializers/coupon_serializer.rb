class CouponSerializer
  include JSONAPI::CouponSerializer
  attributes :name, :code, :discount_value, :active
end