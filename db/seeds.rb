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

(1..5).each do |i|
  Category.create(name: "Category #{i}")
  (1..5).each do |j|
    Product.create(name: "Product #{i} #{j}", category_id: i, price: i*100, 
    	quantity: i)
  end
end