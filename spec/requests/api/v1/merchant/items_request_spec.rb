require "rails_helper"

RSpec.describe "Merchant items endpoints" do
  it "should return all items for a given merchant" do
    merchant1 = create(:merchant)
    item1 = create(:item, merchant_id: merchant1.id)
    item2 = create(:item, merchant_id: merchant1.id)
    item3 = create(:item, merchant_id: merchant1.id)
    merchant2 = create(:merchant)
    create(:item, merchant_id: merchant2.id)

    get "/api/v1/merchants/#{merchant1.id}/items"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(3)
    expect(json[:data][0][:id]).to eq(item1.id.to_s)
    expect(json[:data][1][:id]).to eq(item2.id.to_s)
    expect(json[:data][2][:id]).to eq(item3.id.to_s)
  end

  it "should return 404 and error message when merchant is not found" do
    get "/api/v1/merchants/100000/items"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to have_http_status(:not_found)

    expect(json[:errors]).to be_a Array
    expect(json[:errors][0][:status]).to eq("422")
    expect(json[:errors][0][:title]).to eq("Unprocessable Entity")
    expect(json[:errors][0][:detail]).to eq("Couldn't find Merchant with 'id'=100000")
  end
end