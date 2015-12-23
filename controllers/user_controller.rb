class UserController < ApplicationController

  users_list =  users_create =  users_show = users_update = users_delete = lambda do
    u1 = User.new
    u1.login = 'plop'
    u1.password = '1234'
    u1.save
    json :response => u1.inspect
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

end
