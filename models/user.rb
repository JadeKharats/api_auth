class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  attr_accessor   :password

  field :login
  field :password_hash
  field :api_token
  field :session_token
  field :session_expire_date

  validates :login, uniqueness: true

  validates :login, presence: true
  validates :password, presence: true
  validates :password, length: { minimum: 8, maximum: 16 }

  def check_password? (password)
    Password.new(self.password_hash) == password
  end

  def create_token
    self.session_token = SecureRandom.urlsafe_base64
    self.session_expire_date = Time.now + 3 * 60 * 60
    self.save!(validate: false)
    format_token
  end

  def format_token
    {token: self.session_token, session_expire_date: self.session_expire_date}
  end

  def remove_token
    self.session_token = nil
    self.session_expire_date = nil
    self.save!(validate: false)
  end

  def create_api_token
    self.api_token = SecureRandom.urlsafe_base64
    self.save!(validate: false)
    format_api_token
  end

  def format_api_token
    {token: self.api_token}
  end

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
