class AddBikeTypeToProducts < ActiveRecord::Migration
  def change
    add_column :products, :bike_types, :text
  end
end
