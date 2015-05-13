require 'bundler'
Bundler.require

include BCrypt

DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/main.db')
require './models.rb'

use Rack::Session::Cookie, :key => 'rack.session',
    :expire_after => 2592000,
    :secret => SecureRandom.hex(64)

get '/signin' do
  erb :signin
end

get '/' do
  erb :newuser
end

post '/user/create' do
  u = User.new
  u.username = params[:username]
  u.password = Password.create(params[:password])
  u.save
  redirect '/signin'
end

post '/' do
  user = User.first(:username => params[:name])
  if user && Password.new(user.password) == params[:password]
    session[:id] = user.id

    redirect '/threads'
  else
    redirect '/'
  end
end

get '/threads' do
  @topics = Topic.order(:time)

  erb :threads
end

post '/threads/create' do
  t = Topic.new
  t.topic = params[:topic]
  t.description = params[:description]
  t.time = Time.now
  #t.time = time.strftime("%D at %I:%M:%S %p")
  t.save
  redirect '/threads'
end

post '/thread/:id/delete' do
  t = Topic.first(:id => params[:id])
  @posts = t.posts
  t.destroy
  @posts.each do |p|
    p.destroy
  end

  redirect '/threads'
end

get '/thread/:id' do
  @thread = Topic.first(:id => params[:id])
  @posts = @thread.posts
  @authors = []
  @author = []
  @posts.each do |post|
    user = User.first(:id => post.user_id)
    @authors.push(user.username)
    @author.push(post.user_id)
  end
  erb :view_thread
end

post '/thread/:id/posts' do
  p = Post.new
  p.title = params[:title]
  p.info = params[:info]
  p.time = Time.now
  p.user_id = session[:id]
  p.topic_id = params[:id]
  p.save
  redirect '/thread/' + params[:id]
end

get '/users' do
  @users = User.order(:username)
  erb :show_users
end

get '/out' do
  session.clear
  redirect '/signin'
end

post '/post/:id/delete' do
  p = Post.first(:id => params[:id])
  t = Topic.first(:id => p.topic_id)
  p.destroy

  redirect '/thread/' + t.id.to_s
end

get '/user/:id' do
  @user = User.first(:id => params[:id])
  @posts = @user.posts
  @threads = []
  @topics = []
  @posts.each do |post|
    t = Topic.first(:id => post.topic_id)
    @threads.push(t.id)
    @topics.push(t.topic)
  end
  erb :view_user
end

post '/searchuser/' do
  searched = params[:search]
  u = User.first(:username => searched)
  if u
    redirect '/user/' + u.id.to_s
  else
    redirect '/users'
  end
end