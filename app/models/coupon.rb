class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :discount_type, presence: true, inclusion: { in: ["dollar", "percent"] }

  validates :discount_value, numericality: { greater_than: 0, less_than_or_equal_to: 100, message: "must be between 1 and 100 for percent discounts" },
                             if: -> { discount_type == "percent" }
  validates :discount_value, numericality: { greater_than: 0, message: "must be greater than 0 for dollar discounts" },
                             if: -> { discount_type == "dollar" }

  validate :active_coupon_limit, on: :create, if: :active?

  def activate
    if can_be_activated?
      update(active: true)
      true
    else
      errors.add(:base, "This merchant already has 5 active coupons")
      false
    end
  end

  def deactivate
    if can_be_deactivated?
      update(active: false)
      true
    else
      errors.add(:base, "Coupon cannot be deactivated while there are pending invoices")
      false
    end
  end

  def can_be_activated?
    merchant.coupons.where(active: true).count < 5
  end

  def can_be_deactivated?
    invoices.where(status: 'packaged').empty?
  end

  private

  def active_coupon_limit
    return if merchant.nil?

    if merchant.coupons.where(active: true).count >= 5
      errors.add(:base, "This merchant already has 5 active coupons")
    end
  end
end
