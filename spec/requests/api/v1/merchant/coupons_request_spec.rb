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

  describe "show" do
    it "returns a specific coupon" do
      coupon = create(:coupon, merchant: merchant, name: "15 Dollars Off", code: "OFF15", discount_value: 15)
  
      get "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}"
  
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body, symbolize_names: true)
  
      expect(json[:data][:attributes][:name]).to eq("15 Dollars Off")
      expect(json[:data][:attributes][:code]).to eq("OFF15")
      expect(json[:data][:attributes][:discount_value].to_i).to eq(15)
    end
  end

  describe "create" do
    it "can create a new coupon for a merchant" do
      coupon_params = {
        coupon: {
          name: "10 Dollars Off",
          code: "OFF10",
          discount_value: 10,
          active: true
        }
      }

      post "/api/v1/merchants/#{merchant.id}/coupons", params: coupon_params

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data][:attributes][:name]).to eq("10 Dollars Off")
      expect(json[:data][:attributes][:code]).to eq("OFF10")
      expect(json[:data][:attributes][:discount_value].to_i).to eq(10)
      expect(json[:data][:attributes][:active]).to be true
    end

    it "has a sad path for not being able to create a coupon due to missing params" do
      invalid_coupon_params = {
        coupon: {
          discount_value: 10,
          active: true
        }
      }
  
      post "/api/v1/merchants/#{merchant.id}/coupons", params: invalid_coupon_params
  
      expect(response).to have_http_status(422)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors]).to include("Name can't be blank", "Code can't be blank")
    end
  end

  describe "Updating a coupon's status to active" do
    it "allows a merchant to activate a coupon" do
      inactive_coupon = create(:coupon, merchant: merchant, active: false, code: "INACTIVE01")

      patch "/api/v1/merchants/#{merchant.id}/coupons/#{inactive_coupon.id}", params: { coupon: { active: true } }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:data][:attributes][:active]).to be true
    end

    it "does not activate a coupon if the merchant already has 5 active coupons" do
      create(:coupon, merchant: merchant, active: true, code: "OFF1")
      create(:coupon, merchant: merchant, active: true, code: "OFF2")
      create(:coupon, merchant: merchant, active: true, code: "OFF3")
      create(:coupon, merchant: merchant, active: true, code: "OFF4")

      inactive_coupon = create(:coupon, merchant: merchant, active: false, code: "INACTIVE02")

      create(:coupon, merchant: merchant, active: true, code: "OFF5")

      patch "/api/v1/merchants/#{merchant.id}/coupons/#{inactive_coupon.id}", params: { coupon: { active: true } }
      
      expect(response).to have_http_status(422)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors]).to eq("Merchant can only have 5 active coupons.")
    end

    it "deactivates a coupon" do
      coupon = create(:coupon, merchant: merchant, active: true, code: "ACTIVE01")

      patch "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}", params: { coupon: { active: false } }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:data][:attributes][:active]).to be false
    end

    it "returns error messages if the update fails" do
      coupon = create(:coupon, merchant: merchant, name: "20 Dollars Off", code: "OFF20", discount_value: 20)

      patch "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}", params: { coupon: { name: "", code: "" } }

      expect(response).to have_http_status(422)
      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:errors]).to include("Name can't be blank", "Code can't be blank")
    end

    it "returns a 404 error if the coupon to update is not found" do
      patch "/api/v1/merchants/#{merchant.id}/coupons/999999", params: { coupon: { name: "New Name" } }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors]).to eq("Record not found")
    end
  end
end
