require 'rails_helper'

RSpec.describe "Coupon", type: :request do
  let!(:merchant) { create(:merchant) }
  let!(:coupons) do
    [
      create(:coupon, merchant: merchant, name: "Ten Dollars Off", code: "OFF10", discount_value: 10, discount_type: "dollar"),
      create(:coupon, merchant: merchant, name: "Twenty Dollars Off", code: "OFF20", discount_value: 20, discount_type: "dollar")
    ]
  end

  it "returns a list of coupons for a merchant" do
    get api_v1_merchant_coupons_path(merchant_id: merchant.id)

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body, symbolize_names: true)

    expect(json[:data].size).to eq(2)
    expect(json[:data][0][:attributes][:name]).to eq("Ten Dollars Off")
    expect(json[:data][1][:attributes][:name]).to eq("Twenty Dollars Off")
  end

  it "returns a single coupon with usage count" do
    coupon = coupons.first
    get api_v1_merchant_coupon_path(merchant_id: merchant.id, id: coupon.id)

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body, symbolize_names: true)
    data = json[:data]

    expect(data[:id]).to eq(coupon.id.to_s)
    expect(data[:attributes][:name]).to eq("Ten Dollars Off")
    expect(data[:attributes][:code]).to eq("OFF10")
    expect(data[:attributes][:discount_value]).to eq("10.0")
    expect(data[:attributes][:discount_type]).to eq("dollar")
    expect(data[:attributes][:usage_count]).to eq(0)
  end

  it "returns a 404 not found error when coupon does not exist" do
    get api_v1_merchant_coupon_path(merchant_id: merchant.id, id: 10000)

    expect(response).to have_http_status(:not_found)
    json = JSON.parse(response.body, symbolize_names: true)
    
    expect(json[:errors]).to be_an(Array)
    expect(json[:errors][0][:status]).to eq(404)
    expect(json[:errors][0][:title]).to eq("Not Found")
    expect(json[:errors][0][:detail]).to eq("Couldn't find Coupon with 'id'=10000")
  end

  describe "POST /api/v1/merchants/:merchant_id/coupons" do
    let(:valid_attributes) do
      {
        coupon: {
          name: "Fifty Percent Off",
          code: "OFF50",
          discount_value: 50,
          discount_type: "percent",
          active: true
        }
      }
    end

    context "when the request is valid" do
      it "creates a new coupon" do
        expect { post api_v1_merchant_coupons_path(merchant_id: merchant.id), params: valid_attributes }.to change(Coupon, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body, symbolize_names: true)
        data = json[:data]

        expect(data[:attributes][:name]).to eq("Fifty Percent Off")
        expect(data[:attributes][:code]).to eq("OFF50")
        expect(data[:attributes][:discount_value]).to eq("50.0")
        expect(data[:attributes][:discount_type]).to eq("percent")
        expect(data[:attributes][:active]).to eq(true)
      end
    end

    context "when the request is invalid (merchant has 5 active coupons)" do
      it "returns a validation error" do
      
        create_list(:coupon, 3, merchant: merchant, active: true)

        post api_v1_merchant_coupons_path(merchant_id: merchant.id), params: valid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body, symbolize_names: true)
        
        expect(json[:errors]).to be_an(Array)
        expect(json[:errors][0][:status]).to eq("422")
        expect(json[:errors][0][:title]).to eq("Unprocessable Entity")
        expect(json[:errors][0][:detail]).to eq("This merchant already has 5 active coupons")
      end
    end

    context "when the request is invalid (duplicate coupon)" do
      it "returns a validation error" do
        duplicate_code_attributes = {
          coupon: {
            name: "Duplicate Coupon",
            code: "OFF10",
            discount_value: 5,
            discount_type: "dollar",
            active: true
          }
        }

        post api_v1_merchant_coupons_path(merchant_id: merchant.id), params: duplicate_code_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body, symbolize_names: true)
        
        expect(json[:errors]).to be_an(Array)
        expect(json[:errors][0][:status]).to eq("422")
        expect(json[:errors][0][:title]).to eq("Unprocessable Entity")
        expect(json[:errors][0][:detail]).to eq("Code has already been taken")
      end
    end
  end

  describe "PATCH /api/v1/merchants/:merchant_id/coupons/:id/deactivate" do
    let!(:coupon) { create(:coupon, merchant: merchant, active: true) }
    
    context "when there are no pending invoices" do
      it "can deactivate a coupon" do
        patch deactivate_api_v1_merchant_coupon_path(merchant_id: merchant.id, id: coupon.id)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
        data = json[:data]
    
        expect(data[:id]).to eq(coupon.id.to_s)
        expect(data[:attributes][:active]).to eq(false)
      end
    end

    context "when there are pending invoices" do
      before do
        create(:invoice, coupon: coupon, status: 'packaged')
      end

      it "does not allow the coupon to be deactivated" do
        patch deactivate_api_v1_merchant_coupon_path(merchant_id: merchant.id, id: coupon.id)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body, symbolize_names: true)

        expect(json[:errors].first[:detail]).to eq("Coupon cannot be deactivated while there are pending invoices")
      end
    end
  end
end