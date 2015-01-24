class CreatePictures < ActiveRecord::Migration
  def change
    create_table :pictures do |t|
      t.string :product_id
      t.string :file_id
      t.string :file_filename
      t.integer :file_size
      t.string :file_content_type

      t.timestamps
    end
  end
end
