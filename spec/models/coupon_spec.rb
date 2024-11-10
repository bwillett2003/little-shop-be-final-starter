require 'rails_helper'

RSpec.describe Coupon, type: :model do
  let!(merchant) { create(merchant) }

  describe 'validations' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :code }
    it { should validate_presence_of :discount_value }
    it { should validate_numericality_of(:discount_value).is_greater_than(0) }

    it 'can validate the coupon code is unique for each merchant' do
      create(:coupon, merchant: merchant, code: "TESTCODE")
      should validate_uniqueness_of(:code).case_insensitive.scoped_to(:merchant_id)
    end
  end

  describe 'associations' do
    it { should belong_to :merchant }
  end
end