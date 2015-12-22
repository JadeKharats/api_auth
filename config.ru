require 'sinatra'

require_relative 'controllers/application_controller'

Dir.glob('./{controllers}/*.rb').each { |file| require file }

map('/users') {run UserController}
map('/auth') {run AuthController}
map('/token') {run TokenController}
map('/') {run ApplicationController}

