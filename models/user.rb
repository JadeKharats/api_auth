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

  before_save :encrypt_password

  def authenticate(login,password)
    user_in_db = User.where(login: login).first
    user_in_db.password = password
    if user_in_db
      if Password.new(user_in_db.password_hash) == password
        user_in_db.session_token = SecureRandom.urlsafe_base64
        user_in_db.session_expire_date = Time.now + 3 * 60 * 60
        user_in_db.save!
        return user_in_db
      else
        return {message: 'Bad Bad Password'}
      end
    else
      return {message: "user #{login} not found!"}
    end
  end

  protected

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
