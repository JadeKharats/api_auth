require 'sinatra'
require './app.rb'

Dir.glob('./{controllers}/*.rb').each { |file| require file }

map('/users') {run UserController}
map('/auth') {run AuthController}
map('/token') {run TokenController}
map('/') {run ApplicationController}

