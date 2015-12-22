class AuthController < ApplicationController

  session_create = session_delete  = lambda do
    json :response => 'Work in progress'
  end

  post '/', &session_create
  delete '/', &session_delete

end
