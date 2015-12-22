require 'sinatra/base'
require 'sinatra/json'

class AuthController < Sinatra::Base

  session_create = session_delete  = lambda do
    json :response => 'Work in progress'
  end

  routes_missing = lambda do
    json :response => "Cette route n'existe pas"
  end


  post '/', &session_create
  delete '/', &session_delete

  get '*', &routes_missing

end
