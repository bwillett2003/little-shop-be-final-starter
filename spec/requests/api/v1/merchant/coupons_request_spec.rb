require 'rails_helper'

RSpec.describe "Coupon", type: :request do
  let!(:merchant) { create(:merchant) }

  describe "index" do
    it "returns a list of coupons for a merchant" do
      create(:coupon, merchant: merchant, name: "Ten Dollars Off", code: "OFF10", discount_value: 10)
      create(:coupon, merchant: merchant, name: "Twenty Dollars Off", code: "OFF20", discount_value: 20)

      get "/api/v1/merchants/#{merchant.id}/coupons"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data].size).to eq(2)
      expect(json[:data][0][:attributes][:name]).to eq("Ten Dollars Off")
      expect(json[:data][1][:attributes][:name]).to eq("Twenty Dollars Off")
    end
  end
end