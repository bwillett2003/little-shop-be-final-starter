require "rails_helper"

RSpec.describe Invoice, type: :model do
  describe "#calculate_total" do
    it "calculates the total based on invoice_items quantity and unit_price" do
      merchant = Merchant.create!(name: "Merchant 1")
      customer = Customer.create!(first_name: "John", last_name: "Doe")
      invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged")
      item = Item.create!(name: "Sample Item", description: "A test item", unit_price: 100, merchant: merchant)

      InvoiceItem.create!(invoice: invoice, item: item, quantity: 2, unit_price: 100)
      InvoiceItem.create!(invoice: invoice, item: item, quantity: 1, unit_price: 50)

      expect(invoice.calculate_total).to eq(250)
    end
  end

  describe "#total_after_coupon" do
    let(:merchant) { Merchant.create!(name: "Merchant 1") }
    let(:customer) { Customer.create!(first_name: "John", last_name: "Doe") }
    let(:item) { Item.create!(name: "Sample Item", description: "A test item", unit_price: 100, merchant: merchant) }

    context "when there is no coupon" do
      it "returns the original total" do
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged")
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 2, unit_price: 100)

        expect(invoice.total_after_coupon).to eq(200)
      end
    end

    context "when there is a dollar-off coupon" do
      it "applies the dollar discount without going below zero" do
        coupon = Coupon.create!(merchant: merchant, name: "10 Off", code: "TENOFF", discount_value: 10, discount_type: "dollar")
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 1, unit_price: 20)

        expect(invoice.total_after_coupon).to eq(10)
      end

      it "does not allow the total to go below zero" do
        coupon = Coupon.create!(merchant: merchant, name: "100 Off", code: "HUNDREDOFF", discount_value: 100, discount_type: "dollar")
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 1, unit_price: 50)

        expect(invoice.total_after_coupon).to eq(0)
      end
    end

    context "when there is a percent-off coupon" do
      it "applies the percentage discount" do
        coupon = Coupon.create!(merchant: merchant, name: "50% Off", code: "HALFOFF", discount_value: 50, discount_type: "percent")
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 2, unit_price: 100)

        expect(invoice.total_after_coupon).to eq(100)
      end

      it "applies the percentage discount without going below zero" do
        coupon = Coupon.create!(merchant: merchant, name: "100% Off", code: "ALLFREE", discount_value: 100, discount_type: "percent")
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 1, unit_price: 100)

        expect(invoice.total_after_coupon).to eq(0)
      end
    end

    context "when there is an invalid or nil discount type" do
      it "returns the original total when discount_type is invalid" do
        coupon = Coupon.new(merchant: merchant, name: "Invalid Discount", code: "INVALID", discount_value: 20, discount_type: "invalid_type")
        coupon.save(validate: false)
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 2, unit_price: 100)

        expect(invoice.total_after_coupon).to eq(200)
      end

      it "returns the original total when discount_type is nil" do
        coupon = Coupon.new(merchant: merchant, name: "Nil Discount", code: "NILTYPE", discount_value: 10, discount_type: nil)
        coupon.save(validate: false)
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 2, unit_price: 100)

        expect(invoice.total_after_coupon).to eq(200)
      end
    end

    context "when the discount value is zero" do
      it "does not alter the total for a zero dollar discount" do
        coupon = Coupon.new(merchant: merchant, name: "Zero Dollar", code: "ZERODOLLAR", discount_value: 0, discount_type: "dollar")
        coupon.save(validate: false)
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 2, unit_price: 100)

        expect(invoice.total_after_coupon).to eq(200)
      end

      it "does not alter the total for a zero percent discount" do
        coupon = Coupon.new(merchant: merchant, name: "Zero Percent", code: "ZEROPERCENT", discount_value: 0, discount_type: "percent")
        coupon.save(validate: false)
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 2, unit_price: 100)

        expect(invoice.total_after_coupon).to eq(200)
      end
    end

    context "when the percentage discount is very small" do
      it "calculates the total correctly with a near-zero percent discount" do
        coupon = Coupon.create!(merchant: merchant, name: "Tiny Discount", code: "TINYDISCOUNT", discount_value: 0.01, discount_type: "percent")
        invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
        InvoiceItem.create!(invoice: invoice, item: item, quantity: 1, unit_price: 100)

        expected_total = (100 * (1 - 0.0001)).round(2)
        expect(invoice.total_after_coupon).to eq(expected_total)
      end
    end
  end
end
