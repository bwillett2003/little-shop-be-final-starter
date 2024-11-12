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

  validate :active_coupon_limit, if: -> { new_record? && active? || activating? }
  validate :can_be_deactivated, if: :deactivating?

  def applicable_to_item?(invoice_item)
    invoice_item.item.merchant_id == merchant_id
  end

  private

  def active_coupon_limit
    if merchant.coupons.where(active: true).count >= 5
      errors.add(:base, "This merchant already has 5 active coupons")
    end
  end

  def can_be_deactivated
    if invoices.where(status: 'packaged').exists?
      errors.add(:base, "Coupon cannot be deactivated while there are pending invoices")
      false
    else
      true
    end
  end

  def activating?
    will_save_change_to_active? && active
  end

  def deactivating?
    will_save_change_to_active? && !active
  end
end
