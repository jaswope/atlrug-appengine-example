require 'sinatra'
require 'haml'
require 'appengine-apis/users'
require 'models.rb'

before do
  redirect AppEngine::Users.create_login_url(request.url) unless AppEngine::Users.logged_in?
  @count = Counter.increment("pageviews") || Counter.get_count("pageviews")
  @user = AppEngine::Users.current_user
  @userinfo = UserInfo.first(:appengine_user_id => @user.user_id) || UserInfo.new(:appengine_user_id => @user.user_id)
  @userinfo.views += 1
  @userinfo.save
end

get '/' do
  @title = "Hello!"
  haml :index
end

get '/stats' do
  @title = "Memcache Stats"
  @stats = Counter.stats
  haml :stats
end
