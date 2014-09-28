Bài viết sau hướng dẫn dùng các gem devise và omniauth nhằm mục đích dùng các tài khoản từ mạng xã hội để đăng ký tài khoản tại trang web của bạn.
Để hiểu được bạn viết này kiến thức tối thiểu của bạn là đã biết gem devise trước đó hoặc bạn có thể đọc tài liệu về devise ngay bây giờ tại https://github.com/plataformatec/devise

Add to Gemfile, sau đó `bundle install`

```ruby
gem "devise"
gem "omniauth"
gem "omniauth-twitter"
gem "omniauth-facebook"
gem "omniauth-linkedin"
```

Generate migrations and model:

```
rails generate devise:install
rails g migration create_users name:string
rails generate devise user
rails g model identity user:references provider:string uid:string
```

Ngoài ra bạn còn phải generate view của users để custom sau này:

```
rails generate devise:views users
```

app/models/indentity.rb

```ruby
class Identity < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :uid, :provider
  validates_uniqueness_of :uid, scope: :provider

  def self.find_for_oauth(auth)
    find_or_create_by(uid: auth.uid, provider: auth.provider)
  end
end
```

Tạo tài khoản trên các trang facebook, twitter, linkedin nếu chưa có. Sau đó lần lượt tạo app ở các địa chỉ:

Facebook: https://developers.facebook.com/

Sau khi tạo app, Setting -> Basic -> Add platform -> Website -> điền vào Site URL của bạn ví dụ như: http://hbcnt.herokuapp.com/

Settting -> Advanced -> Deauthorize Callback URL ví dụ như http://hbcnt.herokuapp.com/

Twitter và LinkedIn các bạn làm tương tự ở địa chỉ bên dưới:

Twitter: https://apps.twitter.com/

LinkedIn: https://www.linkedin.com/secure/developer

Sau đó vào app setting copy lần lượt app_key và app_secret vào devise.rb

app/config/initializers/devise.rb

```ruby
Devise.setup do |config|
...
config.omniauth :facebook, "KEY", "SECRET"
config.omniauth :twitter, "KEY", "SECRET"
config.omniauth :linked_in, "KEY", "SECRET"
...
end
```

Giả sử bạn có cả tài khoản Facebook và Twitter. Đầu tiên bạn đăng ký bằng tài khoản facebook sau đó thoát ra và dùng Twitter có email khác tài khoản facebook kia để đăng ký thì hệ thống sẽ tạo một tài khoản mới cho bạn vì không có cách nào liên kết hai tài khoản kia lại với nhau.

config/routes.rb

```ruby
...
devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }
...
```

app/controllers/omniauth_callbacks_controller.rb
```ruby
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def self.provides_callback_for(provider)
    class_eval %Q{
      def #{provider}
        @user = User.find_for_oauth(env["omniauth.auth"], current_user)

        if @user.persisted?
          sign_in @user, event: :authentication
          if @user.email_verified?
            redirect_to edit_user_registration_path
          else
            redirect_to finish_signup_path(@user)
          end
          set_flash_message(:notice, :success, kind: "#{provider}".capitalize) if is_navigational_format?
        else
          session["devise.#{provider}_data"] = env["omniauth.auth"]
          redirect_to new_user_registration_url
        end
      end
    }
  end

  [:twitter, :facebook, :linked_in].each do |provider|
    provides_callback_for provider
  end

  def after_sign_in_path_for(resource)
    if resource.email_verified?
      super resource
    else
      finish_signup_path(resource)
    end
  end
end
```

```ruby
class User < ActiveRecord::Base
  TEMP_EMAIL_PREFIX = "change@me"
  TEMP_EMAIL_REGEX = /\Achange@me/

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  validates_format_of :email, without: TEMP_EMAIL_REGEX, on: :update

  def self.find_for_oauth(auth, signed_in_resource = nil)
    identity = Identity.find_for_oauth(auth)

    user = signed_in_resource ? signed_in_resource : identity.user

    if user.nil?
      email_is_verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
      email = auth.info.email if email_is_verified
      user = User.where(email: email).first if email

      if user.nil?
        user = User.new(
          name: auth.extra.raw_info.name,
          email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
          password: "password"
        )
        user.save!
      end
    end

    if identity.user != user
      identity.user = user
      identity.save!
    end
    user
  end

  def email_verified?
    self.email && self.email !~ TEMP_EMAIL_REGEX
  end
end
```
Hoàn thành quá trình đăng ký

Nếu Oauth provider không cung cấp thông tin cần thiết (ví dụ email) để đăng ký tài khoản thì bạn phải làm thêm một số bước để xác nhận đầy đủ thông tin

config/routes.rb

```ruby
...
match "/users/:id/finish_signup", to: "users#finish_signup", via: [:get, :patch], as: :finish_signup
...
```

app/controllers/users_controller.rb
```ruby
class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!

  def index
    @users = User.all
  end

  def show
  end

  def update
    if @user.update(user_params)
      sign_in(@user == current_user ? @user : current_user, bypass: true)
      edirect_to @user, notice: "Your profile was successfully updated."
    else
      render "edit"
    end
  end

  def finish_signup
    if request.patch? && params[:user]
      if @user.update(user_params)
        sign_in(@user, bypass: true)
        redirect_to @user, notice: "Your profile was successfully updated."
      else
        @show_errors = true
      end
    end
  end

  private
  def set_user
    @user = User.find params[:id]
  end

  def user_params
    accessibles = [ :name, :email ]
    accessibles << [ :password, :password_confirmation ] unless params[:user][:password].blank?
    params.require(:user).permit(accessibles)
  end
end
```

app/views/users/finish_signup.html.erb
Xác nhận email từ user nếu provider không cung cấp thông tin đầy đủ (email)
```html
<div id="add-email" class="container">
  <h1>Add Email</h1>
  <%= form_for(current_user, as: "user", url: finish_signup_path(current_user),
    html: { role: "form"}) do |f| %>
    <% if @show_errors && current_user.errors.any? %>
      <div id="error_explanation">
        <% current_user.errors.full_messages.each do |msg| %>
          <%= msg %><br>
        <% end %>
      </div>
    <% end %>
    <div class="form-group">
      <%= f.label :email %>
      <div class="controls">
        <%= f.text_field :email, autofocus: true, class: "form-control input-lg", placeholder: "Example: email@me.com" %>
        <p class="help-block">Please confirm your email address. No spam.</p>
      </div>
    </div>
    <div class="actions">
      <%= f.submit "Continue", class: "btn btn-primary" %>
    </div>
  <% end %>
</div>
```

Để đảm báo quá trình đăng ký hoàn tất bạn phải thêm vào `application_controller.rb` hàm `ensure_signup_complete` nhằm mục đích kiểm tra email đã được xác thực hay chưa

app/controllers/application_controller.rb
```ruby
class ApplicationController < ActionController::Base
  before_filter :ensure_signup_complete, only: [:new, :create, :update, :destroy]
...

  def ensure_signup_complete
    return if action_name == "finish_signup"
    if current_user && !current_user.email_verified?
      redirect_to finish_signup_path(current_user)
    end
  end
...
end
```


Done!

Demo:  http://hbcnt.herokuapp.com/users/sign_in

Để test demo trên vui lòng gửi username facebook qua chatwork để add tester vào facebook app vì facebook app chưa được publish.

Detail Source Code: https://github.com/nhattan/hbc/