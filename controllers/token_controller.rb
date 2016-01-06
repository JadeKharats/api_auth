class TokenController < ApplicationController

  token_show = lambda do
    user = User.where(login: params[:login]).first
    if user
      if user.check_password?(params[:password])
        json user.create_api_token
      else
        json :message => 'Bad credential'
      end
    else
      json :message => 'Bad credential'
    end
  end

  post '/', &token_show

end
