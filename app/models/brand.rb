class Brand < ActiveRecord::Base
  has_many :products
  validates :name, presence: true
  attachment :avatar, content_type: ["image/jpeg", "image/png", "image/gif"]

  def file_name
    avatar_filename
  end
end
