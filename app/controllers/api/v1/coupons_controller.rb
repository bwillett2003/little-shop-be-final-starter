class Api::V1::CouponsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    merchant = Merchant.find(params[:merchant_id])
    coupons = merchant.coupons
    render json: CouponSerializer.new(coupons)
  end

  def show
    coupon = Coupon.find(params[:id])
    render json: CouponSerializer.new(coupon)
  end

  def create
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.new(coupon_params)

    if coupon.save
      render json: CouponSerializer.new(coupon), status: :created
    else
      render json: { errors: coupon.errors.full_messages }, status: 422
    end
  end

  def update
    coupon = Coupon.find(params[:id])
    merchant = coupon.merchant
  
    if activating_coupon? && merchant_active_coupon_limit_reached?(merchant)
      return render json: { errors: "Merchant can only have 5 active coupons." }, status: 422
    end
  
    if coupon.update(coupon_params)
      render json: CouponSerializer.new(coupon)
    else
      render json: { errors: coupon.errors.full_messages }, status: 422
    end
  end

  private

  def activating_coupon?
    coupon_params[:active].to_s == "true"
  end
  
  def merchant_active_coupon_limit_reached?(merchant)
    merchant.coupons.where(active: true).count >= 5
  end

  def coupon_params
    params.require(:coupon).permit(:name, :code, :discount_value, :active)
  end

  def record_not_found
    render json: { errors: 'Record not found' }, status: :not_found
  end
end
