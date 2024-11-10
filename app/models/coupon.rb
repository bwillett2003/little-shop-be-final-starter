class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :discount_type, presence: true, inclusion: { in: ["dollar", "percent"] }

  validates :discount_value, numericality: { greater_than: 0, less_than_or_equal_to: 100, message: "must be between 1 and 100 for percent discounts" },
                             if: -> { discount_type == "percent" }

  validates :discount_value, numericality: { greater_than: 0, message: "must be greater than 0 for dollar discounts" },
                             if: -> { discount_type == "dollar" }

  validate :active_coupon_limit, on: :create
  
  private

  def active_coupon_limit
    if merchant.coupons.where(active: true).count >= 5
      errors.add(:base, "This merchant already has 5 active coupons")
    end
  end
end