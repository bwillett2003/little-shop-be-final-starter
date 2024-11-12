FactoryBot.define do
  factory :coupon do
    name { "Sample Coupon" }
    sequence(:code) { |n| "CODE#{n}" }
    discount_value { 10 }
    discount_type { "dollar" }
    active { true }
    association :merchant
  end
end
