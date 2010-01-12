require 'appengine-rack'
require 'app'

AppEngine::Rack.configure_app(
  :application => 'jaswope-sandbox',  
  :version => 5)

run Sinatra::Application
