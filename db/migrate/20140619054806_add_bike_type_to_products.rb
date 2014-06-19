class AddBikeTypeToProducts < ActiveRecord::Migration
  def change
    add_column :products, :bike_type, :text
  end
end
