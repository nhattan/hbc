class User < ActiveRecord::Base
  TEMP_EMAIL_PREFIX = "change@me"
  TEMP_EMAIL_REGEX = /\Achange@me/

  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
    :trackable, :validatable, :omniauthable

  validates_format_of :email, without: TEMP_EMAIL_REGEX, on: :update

  def self.find_for_oauth(auth, signed_in_resource = nil)
    identity = Identity.find_for_oauth(auth)
    user = signed_in_resource ? signed_in_resource : identity.user
    unless user
      verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
      email = auth.info.email if verified
      user = User.where(email: email).first if email
      unless user
        user = User.new(
          name: auth.extra.raw_info.name,
          email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
          password: "password"
        )
        user.save!
      end
    end
    unless identity.user == user
      identity.user = user
      identity.save!
    end
    user
  end
  def email_verified?
    email && email !~ TEMP_EMAIL_REGEX
  end
end
