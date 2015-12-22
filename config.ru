require 'sinatra'
require 'securerandom'
require 'json'
require 'mongo'
require 'json/ext'

require_relative 'controllers/application_controller'

Dir.glob('./{models,controllers}/*.rb').each { |file| require file }

configure do
  db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'auth_api')
  set :mongo_db, db[:auth_api]
end

map('/users') {run UserController}
map('/auth') {run AuthController}
map('/token') {run TokenController}
map('/') {run ApplicationController}

