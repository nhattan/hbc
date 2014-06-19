class Admin::BrandsController < ApplicationController
  before_filter :authenticate_admin!
  load_and_authorize_resource param_method: :brand_params
  
  def show
    @brand = Brand.find params[:id]
  end

  def index
    @brands = Brand.all
    @brand = Brand.new
  end

  def new
    @brand = Brand.new
  end

  def create
    @brand = Brand.new brand_params
    if @brand.save
      flash[:success] = "Created"
      redirect_to admin_brand_url(@brand)
    else
      render :new
    end
  end

  def edit
    @brand = Brand.find params[:id]
  end

  def update
    @brand = Brand.find params[:id]
    if @brand.update_attributes brand_params
      flash[:success] = "Updated"
      redirect_to admin_brands_url
    else
      render :edit
    end
  end

  def destroy
    @brand = Brand.find params[:id]
    @brand.destroy
    flash[:success] = "Deleted"
    redirect_to admin_brands_url
  end

  private
  def brand_params
    params.require(:brand).permit(:name, :image)
  end
end