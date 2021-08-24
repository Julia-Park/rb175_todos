# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

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
  elsif @list[:todos].any? { |item| item[:name].downcase == new_item.downcase }
    'The todo item must be unique.'
  end
end

def complete?(object)
  if !object[:status].nil? # check if object is a single item or a todo list
    object[:status] == 'complete'
  else
    !object[:todos].empty? &&
      object[:todos].all? { |item| item[:status] == 'complete' }
  end
end

def load_list(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list

  session[:error] = 'The specified list was not found.'
  redirect '/lists'
end

def load_item(list, item_id)
  list[:todos].select { |item| item[:id] == item_id }.first
end

def next_id(items_with_id)
  max_id = items_with_id.map { |item| item[:id] }.max || 0
  max_id + 1
end

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
end

helpers do
  def incomplete_todos_count(list)
    list[:todos].select { |item| item[:status] == '' }.size
  end

  def todos_count(list)
    list[:todos].size
  end

  def list_class(list)
    'complete' if complete?(list)
  end

  def opposite_status(item)
    'complete' if item[:status].empty?
  end

  def each_by_status(list, &block)
    list.each_with_index do |element, idx|
      yield(element, idx) unless complete?(element)
    end

    list.each_with_index do |element, idx|
      yield(element, idx) if complete?(element)
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
    list_id = next_list_id(session[:lists])
    session[:lists] << { id: list_id, name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

get '/lists/:list_id' do # Renders contents of a list
  @id = params[:list_id].to_i
  @list = load_list(@id)

  erb :todo_list
end

post '/lists/:list_id/todos' do # Add a todo item
  @id = params[:list_id].to_i
  @list = load_list(@id)
  todo_item = params[:todo_item].strip
  session[:error] = error_for_todo_item(todo_item)

  if session[:error]
    erb :todo_list, layout: :layout
  else
    item_id = next_id(@list[:todos])
    @list[:todos] << { id: item_id, name: todo_item, status: '' }
    session[:success] = 'The item has been added.'
    redirect "/lists/#{@id}"
  end
end

post '/lists/:list_id/todos/:item_id/delete' do # Delete an existing todo item
  @id = params[:list_id].to_i
  @list = load_list(@id)
  @list[:todos].delete_if { |item| item[:id] == params[:item_id].to_i }

  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    status 204 # indicates success with no content
  else
    session[:success] = 'The todo item has been deleted.'
    redirect "/lists/#{@id}"
  end
end

post '/lists/:list_id/complete_all' do # complete all items
  @id = params[:list_id].to_i
  @list = load_list(@id)
  @list[:todos].each { |item| item[:status] = params[:status] }
  session[:success] = 'The todo items have been updated.'
  redirect "/lists/#{@id}"
end

post '/lists/:list_id/todos/:item_id' do # toggles the status on item
  @id = params[:list_id].to_i
  @list = load_list(@id)
  item = load_item(@list, params[:item_id].to_i)
  item[:status] = params[:status]
  session[:success] = 'The todo item has been updated.'
  redirect "/lists/#{@id}"
end

get '/lists/:list_id/edit' do # Renders page to edit an existing list
  @id = params[:list_id].to_i
  @list = load_list(@id)
  erb :edit_list, layout: :layout
end

post '/lists/:list_id/edit' do # Rename an existing todo list
  @id = params[:list_id].to_i
  @list = load_list(@id)
  list_name = params[:list_name].strip
  session[:error] = error_for_list_name(list_name)

  if session[:error]
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{@id}"
  end
end

post '/lists/:list_id/delete' do # Delete an existing todo list
  @id = params[:list_id].to_i
  session[:lists].delete_at(@id)

  session[:success] = 'The list has been deleted.'

  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    '/lists'
  else
    redirect '/lists'
  end
end
