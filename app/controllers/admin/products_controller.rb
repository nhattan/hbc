class Admin::ProductsController < ApplicationController
  before_filter :authenticate_admin!
  load_and_authorize_resource param_method: :product_params

  def index
    @products = Product.paginate(page: params[:page], per_page: 8)
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
      if params[:pictures].present?
        begin
          @product.create_pictures! params[:pictures]
        rescue ActiveRecord::RecordInvalid
          redirect_to [:admin, @product] and return
        end
      end
      redirect_to [:admin, @product]
    else
      render :new
    end
  end

  def edit
    @product = Product.find params[:id]
  end

  def update
    @product = Product.find params[:id]
    if @product.update(product_params)
      if params[:pictures].present?
        begin
          @product.create_pictures! params[:pictures]
        rescue ActiveRecord::RecordInvalid
          redirect_to [:admin, @product] and return
        end
      end
      redirect_to [:admin, @product]
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
    params.require(:product).permit(Product::UPDATABLE_ATTRIBUTES_FOR_ADMINS).tap do |while_listed|
      while_listed[:bike_types] = params[:product][:bike_types]
    end
  end
end