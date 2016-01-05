class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  attr_accessor   :password

  field :login
  field :password_hash
  field :salt
  field :api_token
  field :session_token
  field :session_expire_date

  validates :login, uniqueness: true

  validates :login, presence: true
  validates :password, presence: true
  validates :password, length: { minimum: 8, maximum: 16 }

  def authenticate(login,password)
    user_in_db = User.where(login: login).first
    if user_in_db
      if Password.new(user_in_db.password_hash) == password
        user_in_db.session_token = SecureRandom.urlsafe_base64
        user_in_db.session_expire_date = Time.now + 3 * 60 * 60
        user_in_db.save!(validate: false)
        return {token: user_in_db.session_token, session_expire_date: user_in_db.session_expire_date}
      else
        return {message: 'Bad Bad Password'}
      end
    else
      return {message: "user #{login} not found!"}
    end
  end

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
