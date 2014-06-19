# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Admin.create(name: "Nhat Tan", email: "tan@hbc.com", password: "password", 
  password_confirmation: "password")
User.create(name: "Hai", email: "hai@hbc.com", password: "password",
  password_confirmation: "password")
User.create(name: "Quang", email: "quang@hbc.com", password: "password",
  password_confirmation: "password")

Brand.create(name: "Shimano")
Brand.create(name: "Avid")
Brand.create(name: "SRAM")
Brand.create(name: "Giant")
Brand.create(name: "Trek")
(1..5).each do |i|
  (1..5).each do |j|
    Category.create(name: "Category #{i} #{j}", brand_id: i)
    (1..5).each do |k|
      Product.create(name: "Product #{i} #{j} #{k}", category_id: j, 
        price: k*100, quantity: k)
    end
  end
end