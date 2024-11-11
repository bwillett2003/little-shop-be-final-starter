require 'rails_helper'

RSpec.describe Coupon, type: :model do
  let!(:merchant) { create(:merchant) }

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_inclusion_of(:discount_type).in_array(["dollar", "percent"]) }

    it "validates that discount_value is present" do
      coupon = build(:coupon, merchant: merchant, discount_value: nil, discount_type: "dollar")
      expect(coupon).not_to be_valid
      expect(coupon.errors[:discount_value]).to include("must be greater than 0 for dollar discounts")
    end

    it "validates that discount_value is a number greater than 0" do
      coupon = build(:coupon, merchant: merchant, discount_value: -1, discount_type: "dollar")
      expect(coupon).not_to be_valid
      expect(coupon.errors[:discount_value]).to include("must be greater than 0 for dollar discounts")
    end

    context "when validating discount value based on discount type" do
      it "validates discount_value is between 1 and 100 if discount_type is percent" do
        coupon = build(:coupon, merchant: merchant, discount_type: "percent", discount_value: 101)
        expect(coupon).not_to be_valid
        expect(coupon.errors[:discount_value]).to include("must be between 1 and 100 for percent discounts")
      end

      it "validates discount_value is greater than 0 if discount_type is dollar" do
        coupon = build(:coupon, merchant: merchant, discount_type: "dollar", discount_value: -5)
        expect(coupon).not_to be_valid
        expect(coupon.errors[:discount_value]).to include("must be greater than 0 for dollar discounts")
      end
    end

    context "when validating active coupon limit" do
      it "does not allow more than 5 active coupons for a merchant" do
        create_list(:coupon, 5, merchant: merchant, active: true)
        extra_coupon = build(:coupon, merchant: merchant, active: true)
        
        expect(extra_coupon).not_to be_valid
        expect(extra_coupon.errors[:base]).to include("This merchant already has 5 active coupons")
      end
    end
  end

  describe "associations" do
    it { should belong_to(:merchant) }
    it { should have_many(:invoices) }
  end

  describe "methods" do
    describe "#can_be_activated?" do
      it "returns true if there are fewer than 5 active coupons" do
        create_list(:coupon, 4, merchant: merchant, active: true)
        coupon = build(:coupon, merchant: merchant)
        
        expect(coupon.can_be_activated?).to be true
      end

      it "returns false if there are already 5 active coupons" do
        create_list(:coupon, 5, merchant: merchant, active: true)
        coupon = build(:coupon, merchant: merchant)
        
        expect(coupon.can_be_activated?).to be false
      end
    end

    describe "#activate" do
      it "activates the coupon if it can be activated" do
        create_list(:coupon, 4, merchant: merchant, active: true)
        coupon = create(:coupon, merchant: merchant, active: false)
        
        expect(coupon.activate).to be true
        expect(coupon.reload.active).to be true
      end

      it "does not activate the coupon if the merchant already has 5 active coupons" do
        create_list(:coupon, 5, merchant: merchant, active: true)
      
        coupon = Coupon.new(name: "Extra Coupon", code: "EXTRA123", discount_value: 10, discount_type: "dollar", active: false, merchant: merchant)
        coupon.save(validate: false)
    
        expect(coupon.activate).to be false
        expect(coupon.errors[:base]).to include("This merchant already has 5 active coupons")
      end
    end

    describe "#can_be_deactivated?" do
      it "returns true if there are no pending invoices with the coupon" do
        coupon = create(:coupon, merchant: merchant)
        create(:invoice, coupon: coupon, status: "shipped")

        expect(coupon.can_be_deactivated?).to be true
      end

      it "returns false if there are pending invoices with the coupon" do
        coupon = create(:coupon, merchant: merchant)
        create(:invoice, coupon: coupon, status: "packaged")

        expect(coupon.can_be_deactivated?).to be false
      end
    end

    describe "#deactivate" do
      it "deactivates the coupon if it can be deactivated" do
        coupon = create(:coupon, merchant: merchant, active: true)
        create(:invoice, coupon: coupon, status: "shipped")

        expect(coupon.deactivate).to be true
        expect(coupon.reload.active).to be false
      end

      it "does not deactivate the coupon if there are pending invoices" do
        coupon = create(:coupon, merchant: merchant, active: true)
        create(:invoice, coupon: coupon, status: "packaged")

        expect(coupon.deactivate).to be false
        expect(coupon.errors[:base]).to include("Coupon cannot be deactivated while there are pending invoices")
      end
    end
  end
end
