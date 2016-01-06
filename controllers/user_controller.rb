class UserController < ProtectedController

  users_list =  lambda do
    json User.all
  end

  users_show = lambda do
    if User.where(id: params[:id]).exists?
      json User.find(params[:id])
    else
      json :message => 'ID not found'
    end
  end

  users_delete = lambda do
    if User.where(id: params[:id]).exists?
      User.where(id: params[:id]).destroy
      json :message => "ID #{params[:id]} destroy"
    else
      json :message => 'ID not found'
    end
  end

  users_create = lambda do
    user = User.new
    user.login = params[:login]
    user.password = params[:password]
    user.encrypt_password
    user.save
    json user
  end

  users_update = lambda do
    if User.where(id: params[:id]).exists?
      user = User.find(params[:id])
      user.login = params[:login] if params[:login]
      if params[:password]
        user.password = params[:password]
        user.encrypt_password
      end
      user.save
      json user
    else
      json :message => 'ID not found'
    end
  end

  get '/', &users_list
  post '/', &users_create
  get '/:id', &users_show
  put '/:id', &users_update
  delete '/:id', &users_delete

end
