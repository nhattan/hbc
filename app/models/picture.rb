class Picture < ActiveRecord::Base
  belongs_to :product
  attachment :file, content_type: ["image/jpeg", "image/png", "image/gif"]

  validates_uniqueness_of :file_filename

  def file_name
    file_filename
  end
end
