class AuthController < ApplicationController

  session_create = lambda do
    user = User.where(login: params[:login]).first
    if user
      if user.check_password?(params[:password])
        json user.create_token
      else
        json :message => 'Bad credential'
      end
    else
      json :message => 'Bad credential'
    end
  end


  session_delete  = lambda do
    json :response => 'Work in progress'
  end

  post '/', &session_create
  delete '/', &session_delete

end
