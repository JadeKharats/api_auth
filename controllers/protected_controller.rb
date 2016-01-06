class ProtectedController < ApplicationController

  before do
    halt 403 unless User.where(api_token: env['HTTP_AUTHORIZATION']).first
  end

end
