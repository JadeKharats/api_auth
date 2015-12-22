require 'sinatra/base'
require 'sinatra/json'

class App < Sinatra::Base

  users_list =  users_create =  users_show = users_update = users_delete = session_create = session_delete = token_show = lambda do
    json :response => 'Work in progress'
  end

  routes_missing = lambda do
    json :response => "Cette route n'existe pas"
  end

  get '/users', &users_list
  post '/users', &users_create
  get '/users/:id', &users_show
  put '/users/:id', &users_update
  delete '/users/:id', &users_delete

  post '/auth', &session_create
  delete '/auth', &session_delete

  post '/token', &token_show

  get '*', &routes_missing

end
