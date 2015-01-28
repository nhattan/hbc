# Upload multiple files to S3 with Refile

Chủ nhân của Carrierwave, [Jonas Nicklas](https://github.com/jnicklas) gần đây đã release một gem mới có tên Refile, theo [bài viết](http://www.elabs.se/blog/68-refile-fixing-ruby-file-uploads) của anh trên elabs thì Refile được gọi là CarrierWave's killer, Jonas Nicklas sẽ giải thích vì sao anh tạo Refile để thay thế cho Carrierwave.

Refile sẽ có nhiều điểm vượt trội như: đơn giản hơn, upload trực tiếp lên S3 chỉ với 1 config là xong, không phải quan tâm đến file được lưu ở đâu và như thế nào...


[Project Refile](https://github.com/elabs/refile) được khởi động vào khoảng cuối năm 2014, nó đã release 5 version tính đến thời điểm hiện tại.

Bài viết sau hướng dẫn sử dụng gem Refile để upload multiple files, trường hợp 1 file thì tương tự hướng dẫn README trên source code page, và đề cập đến những tính năng thiếu của nó do tuổi đời còn non trẻ.

Gemfile
```ruby
gem "refile", require: ["refile/rails"]
```

Ví dụ được đưa ra ở đây là ```product has_many :pictures``` và ```picture belongs_to :product```, và ```picture attachment :file```

Nếu khai báo ```attachment :file``` thì bạn cũng add ```file_id```, cũng như metadata của file vào như: ```file_filename, file_size, file_content_type```. Refile sẽ tự động điền metadata khi bạn tạo object.

Migration
```ruby
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
```


```ruby
class Picture < ActiveRecord::Base
  belongs_to :product
  attachment :file, content_type: ["image/jpeg", "image/png", "image/gif"]

  validates_uniqueness_of :file_filename
end

class Product < ActiveRecord::Base
  UPDATABLE_ATTRIBUTES_FOR_ADMINS = [:name, :description,
    :price, pictures_attributes: [:id, :file, :_destroy]]
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
```

Ở đây, ta dùng nested attributes của Rails để có thể submit một form với nhiều pictures, thêm ```pictures_attributes: [:id, :file, :_destroy]``` vào permited params.

```:_destroy``` ở đây là tham số của nested attributes, nếu :_destroy = 1 thì nested attribute picture cũng như file sẽ bị xoá. Bạn không cần phải dùng đến tham số :remove_file như attribute bình thường nữa.

Form
```ruby
<%= form_for [:admin, @product], html: {multipart: true} do |f| %>
  <%= f.fields_for :pictures do |builder| %>
    <%= builder.object.file_name %>
    <%= builder.check_box :_destroy %>
  <% end %>
  <%= file_field_tag "pictures[]", multiple: true %>
  <%= f.submit %>
<% end %>
```

Controller
```ruby
def create
  if @product.save
    if params[:pictures].present?
      begin
        @product.create_pictures! params[:pictures]
      rescue ActiveRecord::RecordInvalid
        redirect_to [:admin, @product] and return
      end
    end
    redirect_to [:admin, @product]
  else
    render :new
  end
end
```

Hàm update trong controller cũng viết tương tự như create như trên.

Backend
```ruby
require "refile/backend/s3"

aws = {
  access_key_id: "#{ENV["AWS_ACCESS_KEY_ID"]}",
  secret_access_key: "#{ENV["AWS_SECRET_ACCESS_KEY"]}",
  bucket: "#{ENV["AWS_BUCKET"]}",
}
Refile.cache = Refile::Backend::S3.new(prefix: "cache", **aws)
Refile.store = Refile::Backend::S3.new(prefix: "store", **aws)
```

Khi upload một file lên S3, trước khi record được validate và save thì file nằm ở trong ```Refile.cache``` nếu không có lỗi thì file sẽ được chuyển sang ```Refile.store```. Ngược lại, file vẫn nằm ở ```Refile.cache``` để submit lại hoặc để cleanup sau này.

Để cài đặt biến môi trường bạn có thể dùng gem [dotenv](https://github.com/bkeepers/dotenv) hoặc [figaro](https://github.com/laserlemon/figaro)


Còn phần upload 1 file bạn có thể đọc README trên [project page](https://github.com/elabs/refile)

Hiện tại Refile có một số tính năng để upload 1 file rất hay như:
- Presigned uploads: Upload trực tiếp lên S3 bucket mà không qua ứng dụng của bạn. Chỉ cần configure CORS và thêm ```presigned: true``` vào upload form.
- Direct upload: Upload ngay và luôn khi bạn vừa chọn file xong nhằm giảm thời gian chờ đợi. Chỉ cần thêm ```//= require refile``` và ```direct: true```
- Đặc biệt, đối với những file có dung lượng > 100MB, file được chia nhỏ ra từng phần có dung lượng 5MB, từng phần được upload lên S3 sau đó việc ghép nối cũng được thực hiện tự động (tham khảo thêm [Amazon S3: Multipart Upload](https://aws.amazon.com/blogs/aws/amazon-s3-multipart-upload/)). Mình đã tiến hành so sánh việc upload multiple files với Refile như trên và Carrierwave, kết quả là Refile luôn upload nhanh hơn từ 2-3 lần so với Carrierwave (15 files dung lượng khác nhau với tổng dung lượng khoảng 500MB, S3 standard storage, đo bằng tay, bạn nào biết gem gì có thể đo cái performance cho Rails 4 này thì bảo mình với :D)
- Image processing với mini_magick
- Các tính năng khác: validate file type, remove file, helper để hiển thị ảnh

Một số tính năng Refile còn thiếu và có định hướng phát triển:
- Upload multiple files directly and normally.
- Refile luôn truyền file qua app nên nó không thể tạo URLs cho file của bạn được. Bạn có thể thêm CDN hoặc một HTTP cache nằm trên tầng app. Tuy nhiên nếu bạn thực sự cần lấy URL của file thì bạn có thể dùng cách sau:
- Refile dùng ```SecureRandom.hex(30)``` để tạo ra id cho file nhằm tránh trùng lặp, điều này rất tiện cho việc xử lý trong gem tuy nhiên nếu bạn đang viết API và bạn dùng Refile, bạn muốn response là list file URL thì response trông không được đẹp cho lắm :D

```ruby
def file_url
  uri = file.to_io.base_uri
  scheme = uri.scheme
  host = uri.host
  request_uri = uri.request_uri
  "#{scheme}://#{host}#{request_uri}"
end
```

My source code: https://github.com/nhattan/hbc/pull/16/files
