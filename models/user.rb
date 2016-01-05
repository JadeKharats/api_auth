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

  protected

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
