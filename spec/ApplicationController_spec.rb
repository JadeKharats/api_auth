require File.expand_path '../../controllers/application_controller.rb', __FILE__

ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'

include Rack::Test::Methods

def app
  ApplicationController
end

describe "call a missing route" do
  it "should return a message about routes missing" do
    get '/'
    last_response.body.must_include "Cette route n'existe pas"
  end
end
