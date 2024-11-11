class Invoice < ApplicationRecord
  belongs_to :customer
  belongs_to :merchant
  has_many :invoice_items, dependent: :destroy
  has_many :transactions, dependent: :destroy
  belongs_to :coupon, optional: true

  validates :status, inclusion: { in: ["shipped", "packaged", "returned"] }

  def calculate_total
    invoice_items.sum("quantity * unit_price")
  end

  def total_after_coupon
    total = calculate_total
    return total unless coupon

    if coupon.discount_type == "dollar"
      [total - coupon.discount_value, 0].max
    elsif coupon.discount_type == "percent"
      [total * (1 - coupon.discount_value / 100.0), 0].max
    else
      total
    end
  end
end