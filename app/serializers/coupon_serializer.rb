class CouponSerializer
  include JSONAPI::Serializer
  attributes :name, :code, :discount_value, :active
end