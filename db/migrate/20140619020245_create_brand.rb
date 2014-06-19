class CreateBrand < ActiveRecord::Migration
  def change
    create_table :brands do |t|
      t.string :name
      t.string :description
    end
  end
end
