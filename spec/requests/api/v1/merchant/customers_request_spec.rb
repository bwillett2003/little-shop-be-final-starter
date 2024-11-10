require "rails_helper"

RSpec.describe "Merchant customers endpoints" do
  it "should return all customers for a given merchant" do
    merchant1 = create(:merchant)
    customer1 = create(:customer)
    customer2 = create(:customer)
    customer3 = create(:customer)
    merchant2 = create(:merchant)
    create_list(:invoice, 3, merchant_id: merchant1.id, customer_id: customer1.id)
    create_list(:invoice, 2, merchant_id: merchant1.id, customer_id: customer2.id)
    
    create_list(:invoice, 2, merchant_id: merchant2.id, customer_id: customer3.id)

    get "/api/v1/merchants/#{merchant1.id}/customers"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(2)
    expect(json[:data][0][:id]).to eq(customer1.id.to_s)
    expect(json[:data][0][:type]).to eq("customer")
    expect(json[:data][0][:attributes][:first_name]).to eq(customer1.first_name)
    expect(json[:data][0][:attributes][:last_name]).to eq(customer1.last_name)

    expect(json[:data][1][:id]).to eq(customer2.id.to_s)
    expect(json[:data][1][:type]).to eq("customer")
    expect(json[:data][1][:attributes][:first_name]).to eq(customer2.first_name)
    expect(json[:data][1][:attributes][:last_name]).to eq(customer2.last_name)
  end

  it "should return 404 and error message when merchant is not found" do
    get "/api/v1/merchants/100000/customers"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to have_http_status(:not_found)
    
    expect(json[:errors]).to be_a Array
    expect(json[:errors][0][:status]).to eq("422")
    expect(json[:errors][0][:title]).to eq("Unprocessable Entity")
    expect(json[:errors][0][:detail]).to eq("Couldn't find Merchant with 'id'=100000")
  end
end