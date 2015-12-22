require 'sinatra/base'
require 'sinatra/json'

class TokenController < Sinatra::Base

  token_show = lambda do
    json :response => 'Work in progress'
  end

  routes_missing = lambda do
    json :response => "Cette route n'existe pas"
  end


  post '/', &token_show

  get '*', &routes_missing

end
