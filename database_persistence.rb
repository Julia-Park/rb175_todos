require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: 'todos')
    @logger = logger
    setup_schema
  end

  def all_lists # => array of hashes
    # each has needs to contain id: '', name: '', todos: []
    sql = 'SELECT * FROM lists;'
    result = query(sql)

    result.map do |tuple|
      id = tuple['id']
      name = tuple['name']
      {id: id, name: name, todos: []}
    end
  end

  def find_list(list_id)
    sql = 'SELECT * FROM lists WHERE id = $1'
    result = query(sql, list_id)

    tuple = result.first
    id = tuple['id']
    name = tuple['name']
    {id: id, name: name, todos: []}
  end

  def add_list(list_name)
    # @session[:lists] << { id: next_id(all_lists), name: list_name, todos: [] }
  end

  def delete_list(list_id)
    # all_lists.delete_if { |list| list[:id] == list_id }
  end

  def update_list_name(list_id, new_name)
    # list = find_list(list_id)
    # list[:name] = new_name
  end

  def add_todo_to_list(list_id, todo_item)
    # item_id = next_id(find_list(list_id)[:todos])
    # list = find_list(list_id)
    # list[:todos] << { id: item_id, name: todo_item, status: '' }
  end

  def find_todo_from_list(list_id, item_id)
    # list = find_list(list_id)
    # list[:todos].select { |item| item[:id] == item_id }.first
  end

  def delete_todo_from_list(list_id, item_id)
    # list = find_list(list_id)
    # list[:todos].delete_if { |item| item[:id] == item_id }
  end

  def update_item_status(list_id, item_id, status)
    # find_todo_from_list(list_id, item_id)[:status] = status
  end

  def complete_all_todos(list_id)
    # list = find_list(list_id)
    # list[:todos].each { |item| item[:status] = 'complete' }
  end

  private

  def setup_schema
    result = @db.exec( <<-SQL
      SELECT COUNT(*) 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'lists';
      SQL
    )

    if result.values[0][0] == '0'
      sql = File.read('./schema.sql')
      @db.exec(sql)
    end
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end