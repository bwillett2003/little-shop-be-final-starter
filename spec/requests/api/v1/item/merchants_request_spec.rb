require "rails_helper"

RSpec.describe "Item Merchant endpoints" do
  it "should return merchant info for a given item" do
    merchant1 = create(:merchant)
    item1 = create(:item, merchant_id: merchant1.id)

    get "/api/v1/items/#{item1.id}/merchant"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data][:type]).to eq("merchant")
    expect(json[:data][:id]).to eq(merchant1.id.to_s)
    expect(json[:data][:attributes][:name]).to eq(merchant1.name)
  end

  it "should return 404 and error message when item is not found" do
    get "/api/v1/items/100000/merchant"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to have_http_status(:not_found)
    
    expect(json[:errors]).to be_a Array
    expect(json[:errors][0][:status]).to eq("422")
    expect(json[:errors][0][:detail]).to eq("Couldn't find Item with 'id'=100000")
  end
end