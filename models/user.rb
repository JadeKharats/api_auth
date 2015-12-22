class User

  def initialize(login = 'itsme', password = 'plop1234')
    @id = 153
    @login = login
    @password = password
    @salt = SecureRandom.hex
    @api_token = SecureRandom.hex
    @session_token = SecureRandom.hex
    @session_expire_date = Time.now
    @created_at = Time.now
    @updated_at = Time.now
  end

end
