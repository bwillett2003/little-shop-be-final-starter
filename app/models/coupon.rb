class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { case_sensitive: false, scope: :merchant_id }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :discount_type, presence: true, inclusion: { in: ["dollar", "percent"] }

  validates :discount_value, numericality: { greater_than: 0, less_than_or_equal_to: 100, message: "must be between 1 and 100 for percent discounts" },
                             if: -> { discount_type == "percent" }

  validates :discount_value, numericality: { greater_than: 0, message: "must be greater than 0 for dollar discounts" },
                             if: -> { discount_type == "dollar" }
end