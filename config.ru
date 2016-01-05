require 'sinatra'
require 'securerandom'
require 'json'
require 'mongoid'
require 'bcrypt'
require 'securerandom'


require_relative 'controllers/application_controller'

Dir.glob('./{models,controllers}/*.rb').each { |file| require file }

Mongoid.load!("config/mongoid.yml")

map('/users') {run UserController}
map('/auth') {run AuthController}
map('/token') {run TokenController}
map('/') {run ApplicationController}

