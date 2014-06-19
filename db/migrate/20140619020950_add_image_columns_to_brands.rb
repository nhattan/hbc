class AddImageColumnsToBrands < ActiveRecord::Migration
  def self.up
    add_attachment :brands, :image
  end

  def self.down
    remove_attachment :brands, :image
  end
end
