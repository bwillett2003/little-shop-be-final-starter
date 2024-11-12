require "rails_helper"

RSpec.describe "Merchant invoices endpoints" do
  before :each do
    @merchant2 = Merchant.create!(name: "Merchant")
    @merchant1 = Merchant.create!(name: "Merchant Again")

    @customer1 = Customer.create!(first_name: "Papa", last_name: "Gino")
    @customer2 = Customer.create!(first_name: "Jimmy", last_name: "John")

    @invoice1 = Invoice.create!(customer: @customer1, merchant: @merchant1, status: "packaged")
    Invoice.create!(customer: @customer1, merchant: @merchant1, status: "shipped")
    Invoice.create!(customer: @customer1, merchant: @merchant1, status: "shipped")
    Invoice.create!(customer: @customer1, merchant: @merchant1, status: "shipped")
    @invoice2 = Invoice.create!(customer: @customer1, merchant: @merchant2, status: "shipped")
  end

  it "should return all invoices for a given merchant based on status param" do
    get "/api/v1/merchants/#{@merchant1.id}/invoices?status=packaged"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(1)
    expect(json[:data][0][:id]).to eq(@invoice1.id.to_s)
    expect(json[:data][0][:type]).to eq("invoice")
    expect(json[:data][0][:attributes][:customer_id]).to eq(@customer1.id)
    expect(json[:data][0][:attributes][:merchant_id]).to eq(@merchant1.id)
    expect(json[:data][0][:attributes][:status]).to eq("packaged")
  end

  it "should get multiple invoices if they exist for a given merchant and status param" do
    get "/api/v1/merchants/#{@merchant1.id}/invoices?status=shipped"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(3)
  end

  it "should only get invoices for merchant given" do
    get "/api/v1/merchants/#{@merchant2.id}/invoices?status=shipped"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(1)
    expect(json[:data][0][:id]).to eq(@invoice2.id.to_s)
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

  it "returns all invoices for a given merchant without filtering by status" do
    get "/api/v1/merchants/#{@merchant1.id}/invoices"
  
    json = JSON.parse(response.body, symbolize_names: true)
  
    expect(response).to be_successful
    
    expect(json[:data].count).to eq(4)
  
    expect(json[:data].map { |invoice| invoice[:attributes][:merchant_id] }.uniq).to eq([@merchant1.id])
  end

  it "returns the original total when no coupon is applied" do
    merchant = Merchant.create!(name: "Merchant Test")
    customer = Customer.create!(first_name: "Test", last_name: "Customer")
    invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged")
  
    item1 = Item.create!(name: "Item 1", description: "Test Item", unit_price: 100, merchant: merchant)
    InvoiceItem.create!(invoice: invoice, item: item1, quantity: 2, unit_price: 100)
  
    expect(invoice.total_after_coupon).to eq(invoice.calculate_total)
  end

  it "calculates the total for an invoice based on quantity and unit_price of its items" do
    merchant = Merchant.create!(name: "Merchant Test")
    customer = Customer.create!(first_name: "Test", last_name: "Customer")
    invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged")

    item1 = Item.create!(name: "Item 1", description: "Test Item", unit_price: 50, merchant: merchant)
    item2 = Item.create!(name: "Item 2", description: "Another Item", unit_price: 100, merchant: merchant)

    InvoiceItem.create!(invoice: invoice, item: item1, quantity: 2, unit_price: 50)
    InvoiceItem.create!(invoice: invoice, item: item2, quantity: 1, unit_price: 100)

    expect(invoice.calculate_total).to eq(200)
  end

  it "calculates the total after applying a dollar-off coupon without going below zero" do
    merchant = Merchant.create!(name: "Merchant Test")
    customer = Customer.create!(first_name: "Test", last_name: "Customer")
    coupon = Coupon.create!(merchant: merchant, name: "$50 Off", code: "SAVE50", discount_value: 50, discount_type: "dollar")
    invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
  
    item1 = Item.create!(name: "Item 1", description: "Test Item", unit_price: 30, merchant: merchant)
    InvoiceItem.create!(invoice: invoice, item: item1, quantity: 1, unit_price: 30)
  
    expect(invoice.total_after_coupon).to eq(0)
  end

  it "calculates the total after applying a percent-off coupon" do
    merchant = Merchant.create!(name: "Merchant Test")
    customer = Customer.create!(first_name: "Test", last_name: "Customer")
    coupon = Coupon.create!(merchant: merchant, name: "10% Off", code: "SAVE10", discount_value: 10, discount_type: "percent")
    invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)

    item1 = Item.create!(name: "Item 1", description: "Test Item", unit_price: 100, merchant: merchant)
    item2 = Item.create!(name: "Item 2", description: "Another Item", unit_price: 50, merchant: merchant)
    
    InvoiceItem.create!(invoice: invoice, item: item1, quantity: 1, unit_price: 100)
    InvoiceItem.create!(invoice: invoice, item: item2, quantity: 2, unit_price: 50)

    expect(invoice.total_after_coupon).to eq(180)
  end

  it "returns the original total when discount_type is unrecognized" do
    merchant = Merchant.create!(name: "Merchant Test")
    customer = Customer.create!(first_name: "Test", last_name: "Customer")
    
    coupon = Coupon.new(merchant: merchant, name: "Unknown Type", code: "UNKNOWN", discount_value: 20)
    coupon[:discount_type] = nil
    coupon.save!(validate: false)
    
    invoice = Invoice.create!(customer: customer, merchant: merchant, status: "packaged", coupon: coupon)
  
    item1 = Item.create!(name: "Item 1", description: "Test Item", unit_price: 100, merchant: merchant)
    InvoiceItem.create!(invoice: invoice, item: item1, quantity: 2, unit_price: 100)
  
    expect(invoice.total_after_coupon).to eq(invoice.calculate_total)
  end
  
end