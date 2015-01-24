class Product < ActiveRecord::Base
  UPDATABLE_ATTRIBUTES_FOR_ADMINS = [:brand_id, :category_id, :name, :description,
    :price, :quantity, pictures_attributes: [:id, :file, :_destroy]]
  BIKE_TYPES = ["MTB", "ROAD", "CITY", "HYBRID", "BMX"]
  serialize :bike_types
  belongs_to :category
  belongs_to :brand
  has_many :line_items, dependent: :destroy
  validates :name, :price, :quantity, :category_id, :brand_id, presence: true
  validates_numericality_of :price, :quantity, greater_than: 0
  has_many :pictures
  accepts_nested_attributes_for :pictures, allow_destroy: true

  def create_pictures! picture_params
    transaction do
      picture_params.each do |picture_param|
        pictures.create!(file: picture_param)
      end
    end
  end
end
