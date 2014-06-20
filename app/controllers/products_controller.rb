class ProductsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @products = Product.paginate(page: params[:page], per_page: 15)
  end
end