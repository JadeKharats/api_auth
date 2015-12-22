class UserController < ApplicationController

  users_list =  users_create =  users_show = users_update = users_delete = lambda do
    json :response => 'Work in progress'
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

end
