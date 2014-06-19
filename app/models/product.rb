class Product < ActiveRecord::Base
  serialize :type, Array
  belongs_to :category
  has_many :line_items, dependent: :destroy
  validates :name, :price, :quantity, :category_id, presence: true
  validates_numericality_of :price, :quantity, greater_than: 0
  has_attached_file :image, styles: {medium: "300x300>", thumb: "100x100>"}
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
end
