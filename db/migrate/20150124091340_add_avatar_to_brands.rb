class AddAvatarToBrands < ActiveRecord::Migration
  def change
    change_table :brands do |t|
      t.string :avatar_id
      t.string :avatar_filename
      t.integer :avatar_size
      t.integer :avatar_content_type
    end
  end
end
