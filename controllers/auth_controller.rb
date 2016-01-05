class AuthController < ApplicationController

  session_create = lambda do
    user = User.new
    json user.authenticate(params[:login],params[:password])
  end


  session_delete  = lambda do
    json :response => 'Work in progress'
  end

  post '/', &session_create
  delete '/', &session_delete

end
