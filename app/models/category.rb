class Category < ActiveRecord::Base
  belongs_to :brand
  has_many :products
  validates :name, :brand_id, presence: true
  validates :name, uniqueness: true
end
