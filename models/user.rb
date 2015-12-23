class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :login
  field :password
  field :salt
  field :api_token
  field :session_token
  field :session_expire_date

  validates :login, uniqueness: true

  validates :login, presence: true
  validates :password, presence: true
  validates :password, length: { minimum: 8, maximum: 16 }
end
