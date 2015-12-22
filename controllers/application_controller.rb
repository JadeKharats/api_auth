require 'sinatra/base'
require 'sinatra/json'

class ApplicationController < Sinatra::Base

  routes_missing = lambda do
    json :response => "Cette route n'existe pas"
  end

  get '*', &routes_missing

end
