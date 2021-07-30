# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  # use this block to make sure the user session contains at least an empty array
  session[:lists] ||= []
end

helpers do
  def error_for_list_name(name)
    if !(1..100).cover?(name.length)
      'The list name must be between 1 and 100 characters.'
    elsif session[:lists].any? { |list| list[:name].downcase == name.downcase }
      'The list name must be unique.'
    end
  end

  def error_for_todo_item(new_item)
    if !(1..100).cover?(new_item.length)
      'The todo item must be between 1 and 100 characters.'
    elsif @list[:todos].any? { |item| item.downcase == new_item.downcase }
      'The todo item must be unique.'
    end
  end
end

get '/' do
  redirect '/lists'
end

get '/lists' do # view all lists
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get '/lists/new' do # renders the new list form
  erb :new_list, layout: :layout
end

post '/lists' do # create a new list
  list_name = params[:list_name].strip
  session[:error] = error_for_list_name(list_name)

  if session[:error]
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

get '/lists/:number' do
  @list = session[:lists][params[:number].to_i]
  erb :todo_list
end

post '/lists/:number' do
  @list = session[:lists][params[:number].to_i]
  todo_item = params[:todo_item].strip
  session[:error] = error_for_todo_item(todo_item)

  if session[:error]
    erb :todo_list, layout: :layout
  else
    @list[:todos] << todo_item
    session[:success] = 'The item has been added.'
    redirect '/lists/' + params[:number]
  end
end