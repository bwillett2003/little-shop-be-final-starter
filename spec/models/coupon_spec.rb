require 'rails_helper'

RSpec.describe Coupon, type: :model do
  let!(:merchant) { create(:merchant) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:discount_value) }
    it { should validate_numericality_of(:discount_value).is_greater_than(0) }
    it { should validate_inclusion_of(:discount_type).in_array(["dollar", "percent"]) }

    context 'when validating uniqueness of code' do
      it 'validates that the coupon code is unique per merchant' do
        create(:coupon, merchant: merchant, code: "TESTCODE")
        expect(subject).to validate_uniqueness_of(:code).case_insensitive
      end
    end

    context 'when validating discount value based on discount type' do
      it 'validates discount_value is between 1 and 100 if discount_type is percent' do
        coupon = build(:coupon, merchant: merchant, discount_type: "percent", discount_value: 101)
        expect(coupon).not_to be_valid
        expect(coupon.errors[:discount_value]).to include("must be between 1 and 100 for percent discounts")
      end

      it 'validates discount_value is greater than 0 if discount_type is dollar' do
        coupon = build(:coupon, merchant: merchant, discount_type: "dollar", discount_value: -5)
        expect(coupon).not_to be_valid
        expect(coupon.errors[:discount_value]).to include("must be greater than 0 for dollar discounts")
      end
    end

    context 'when validating active coupon limit' do
      it 'does not allow more than 5 active coupons for a merchant' do
        create_list(:coupon, 5, merchant: merchant, active: true)
        extra_coupon = build(:coupon, merchant: merchant, active: true)
        
        expect(extra_coupon).not_to be_valid
        expect(extra_coupon.errors[:base]).to include("This merchant already has 5 active coupons")
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:merchant) }
    it { should have_many(:invoices) }
  end
end
