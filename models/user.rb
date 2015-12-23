class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :login
  field :password
  field :salt
  field :api_token
  field :session_token
  field :session_expire_date

end
