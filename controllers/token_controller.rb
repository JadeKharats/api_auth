class TokenController < ApplicationController

  token_show = lambda do
    json :response => 'Work in progress'
  end

  post '/', &token_show

end
