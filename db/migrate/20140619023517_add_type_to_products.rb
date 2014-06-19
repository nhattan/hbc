class AddTypeToProducts < ActiveRecord::Migration
  def change
    add_column :products, :type, :text
  end
end
