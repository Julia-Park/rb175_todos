
class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def all_lists
    @session[:lists]
  end

  def find_list(list_id)
    @session[:lists].find { |list| list[:id] == list_id }
  end

  def add_list(list_name)
    @session[:lists] << { id: next_id(all_lists), name: list_name, todos: [] }
  end

  def delete_list(list_id)
    all_lists.delete_if { |list| list[:id] == list_id }
  end

  def update_list_name(list_id, new_name)
    list = find_list(list_id)
    list[:name] = new_name
  end

  def add_todo_to_list(list_id, todo_item)
    item_id = next_id(find_list(list_id)[:todos])
    list = find_list(list_id)
    list[:todos] << { id: item_id, name: todo_item, status: '' }
  end

  def find_todo_from_list(list_id, item_id)
    list = find_list(list_id)
    list[:todos].select { |item| item[:id] == item_id }.first
  end

  def delete_todo_from_list(list_id, item_id)
    list = find_list(list_id)
    list[:todos].delete_if { |item| item[:id] == item_id }
  end

  def update_item_status(list_id, item_id, status)
    find_todo_from_list(list_id, item_id)[:status] = status
  end

  def complete_all_todos(list_id)
    list = find_list(list_id)
    list[:todos].each { |item| item[:status] = 'complete' }
  end

  private

  def next_id(items_with_id)
    max_id = items_with_id.map { |item| item[:id] }.max || 0
    max_id + 1
  end
end