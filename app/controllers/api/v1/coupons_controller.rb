class Api::V1::CouponsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  def index
    merchant = Merchant.find(params[:merchant_id])
    coupons = filter_coupons(merchant.coupons)
    render json: CouponSerializer.new(coupons)
  end

  def show
    coupon = Coupon.find(params[:id])
    usage_count = coupon.invoices.count
    render json: CouponSerializer.new(coupon)
  end

  def create
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.new(coupon_params)

    coupon.save!
    render json: CouponSerializer.new(coupon), status: :created
  end

  def deactivate
    coupon = Coupon.find(params[:id])

    if coupon.deactivate
      render json: CouponSerializer.new(coupon), status: :ok
    else
      render json: ErrorSerializer.format_errors(coupon.errors.full_messages), status: :unprocessable_entity
    end
  end

  def activate
    coupon = Coupon.find(params[:id])

    if coupon.activate
      render json: CouponSerializer.new(coupon), status: :ok
    else
      render json: ErrorSerializer.format_errors(coupon.errors.full_messages), status: :unprocessable_entity
    end
  end

  private

  def coupon_params
    params.require(:coupon).permit(:name, :code, :discount_value, :discount_type, :active)
  end

  def filter_coupons(coupons)
    return coupons.where(active: true) if params[:active] == 'true'
    return coupons.where(active: false) if params[:active] == 'false'
    coupons
  end

  def unprocessable_entity(exception)
    render json: ErrorSerializer.format_errors(exception.record.errors.full_messages), status: :unprocessable_entity
  end  

  def record_not_found(exception)
    render json: ErrorSerializer.format_error(exception, 404), status: :not_found
  end
end