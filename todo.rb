require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  # use this block to make sure the user session contains at least an empty array
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do # view all lists
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/lists/new" do # renders the new list form
  erb :new_list, layout: :layout
end

post "/lists" do # create a new list
  session[:lists] << {name: params[:list_name], todos: []}
  session[:success] = "The list has been created."
  redirect "/lists"
end