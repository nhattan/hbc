class Admin::ProductsController < ApplicationController
  before_filter :authenticate_admin!
  load_and_authorize_resource param_method: :product_params
  
  def index
    @products = Product.all
  end

  def show
    @product = Product.find params[:id]
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new product_params
    if @product.save
      redirect_to admin_category_url(@product.category)
    else
      render :new
    end
  end

  def edit
    @product = Product.find params[:id]
  end

  def update
    @product = Product.find params[:id]
    if @product.update_attributes product_params
      redirect_to admin_category_url(@product.category)
    else
      render :edit
    end
  end

  def destroy
    @product = Product.find params[:id]
    @product.destroy
    redirect_to admin_category_url(@product.category)
  end

  private
  def product_params
    params.require(:product).permit(:category_id, :name, :description, :price, :quantity, :image)
  end
end