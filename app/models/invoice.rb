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
  
    applicable_total = invoice_items
                        .select { |item| coupon.applicable_to_item?(item) }
                        .sum { |item| item.quantity * item.unit_price }
  
    discounted_total = case coupon.discount_type
                       when "dollar"
                         [total - [coupon.discount_value, applicable_total].min, 0].max
                       when "percent"
                         total - (applicable_total * (coupon.discount_value / 100.0))
                       else
                         total
                       end
  
    [discounted_total, 0].max
  end
end