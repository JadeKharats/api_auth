require 'sinatra/base'
require 'sinatra/json'

class UserController < Sinatra::Base

  users_list =  users_create =  users_show = users_update = users_delete = lambda do
    json :response => 'Work in progress'
  end

  routes_missing = lambda do
    json :response => "Cette route n'existe pas"
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

  get '*', &routes_missing

end
