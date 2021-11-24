# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def all_lists
    @session[:lists]
  end

  def find_list(list_id)
    @session[:lists].find { |list| list[:id] == list_id}
  end

  def add_list(list_name)
    @session[:lists] << { id: next_id(all_lists), name: list_name, todos: [] }
  end

  def delete_list(list_id)
    all_lists.delete_if { |list| list[:id] == list_id }
  end

  def update_list_name(list_id, new_name)
    find_list(list_id)[:name] = new_name
  end

  def add_todo_to_list(list_id, todo_item)
    item_id = next_id(find_list(list_id)[:todos])
    list = find_list(list_id)
    list[:todos] << { id: item_id, name: todo_item, status: '' }
  end

  def find_item_from_list(list_id, item_id)
    find_list(list_id)[:todos].select { |item| item[:id] == item_id }.first
  end

  def delete_todo_from_list(list_id, item_id)
    list = find_list(list_id)
    list[:todos].delete_if { |item| item[:id] == item_id }
  end

  def update_item_status(list_id, item_id, status)
    find_item_from_list(list_id, item_id)[:status] = status
  end

  private

  def next_id(items_with_id)
    max_id = items_with_id.map { |item| item[:id] }.max || 0
    max_id + 1
  end
end

def error_for_list_name(name)
  if !(1..100).cover?(name.length)
    'The list name must be between 1 and 100 characters.'
  elsif @storage.all_lists.any? { |list| list[:name].downcase == name.downcase }
    'The list name must be unique.'
  end
end

def error_for_todo_item(list_id, new_item)
  if !(1..100).cover?(new_item.length)
    'The todo item must be between 1 and 100 characters.'
  elsif @storage.find_list(list_id)[:todos].any? { |item| item[:name].downcase == new_item.downcase }
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

def load_list(list_id)
  list = @storage.find_list(list_id)
  return list if list

  session[:error] = 'The specified list was not found.'
  redirect '/lists'
end

def load_item(list, item_id)
  list[:todos].select { |item| item[:id] == item_id }.first
end


configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  @storage = SessionPersistence.new(session)
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
  @lists = @storage.all_lists
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
    @storage.add_list(list_name)
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
  todo_item = params[:todo_item].strip
  session[:error] = error_for_todo_item(@id, todo_item)

  if session[:error]
    erb :todo_list, layout: :layout
  else
    @storage.add_todo_to_list(@id, todo_item)
    session[:success] = 'The item has been added.'
    redirect "/lists/#{@id}"
  end
end

post '/lists/:list_id/todos/:item_id/delete' do # Delete an existing todo item
  @id = params[:list_id].to_i
  item_id = params[:item_id].to_i
  @storage.delete_todo_from_list(@id, item_id)

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
  @storage.update_item_status(@id, params[:item_id].to_i, params[:status])
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
  list_name = params[:list_name].strip
  session[:error] = error_for_list_name(list_name)

  if session[:error]
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(@id, list_name)
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{@id}"
  end
end

post '/lists/:list_id/delete' do # Delete an existing todo list
  @id = params[:list_id].to_i
  @storage.delete_list(@id)

  session[:success] = 'The list has been deleted.'

  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    '/lists'
  else
    redirect '/lists'
  end
end
