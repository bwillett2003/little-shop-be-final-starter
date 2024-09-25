class Coupon < ApplicationRecord
  belongs_to :merchant

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { case_sensitive: false, scope: :merchant_id }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
end
