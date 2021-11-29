require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: 'todos')
    @logger = logger
    setup_schema
  end

  def all_lists # => array of hashes
    sql = 'SELECT * FROM lists;'
    result = query(sql)

    result.map do |tuple|
      { id: tuple['id'].to_i, name: tuple['name'], todos: all_todos(tuple['id']) }
    end
  end

  def find_list(list_id) # => Hash corresponding to given list
    sql = 'SELECT name FROM lists WHERE id = $1'
    result = query(sql, list_id)

    { id: list_id.to_i, name: result.first['name'], todos: all_todos(list_id) }
  end

  def add_list(list_name)
    sql = 'INSERT INTO lists (name) VALUES ($1);'
    query(sql, list_name)
  end

  def delete_list(list_id)
    sql = 'DELETE FROM lists WHERE id = $1;'
    query(sql, list_id)
  end

  def update_list_name(list_id, new_name)
    sql = 'UPDATE lists SET name = $1 WHERE id = $2;'
    query(sql, new_name, list_id)
  end

  def add_todo_to_list(list_id, todo_item)
    sql = 'INSERT INTO todos (lists_id, name) VALUES ($1, $2);'
    query(sql, list_id, todo_item)
  end

  def delete_todo_from_list(list_id, item_id)
    sql = 'DELETE FROM todos WHERE lists_id = $1 AND id = $2;'
    query(sql, list_id, item_id)
  end

  def update_todo_status(list_id, item_id, status)
    sql = 'UPDATE todos SET completed = $1 WHERE id = $2 AND lists_id = $3;'
    query(sql, status == 'complete', item_id, list_id)
  end

  def complete_all_todos(list_id)
    sql = 'UPDATE todos SET completed = TRUE where lists_id = $1'
    query(sql, list_id)
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

  def all_todos(list_id)
    sql = 'SELECT * FROM todos WHERE lists_id = $1'
    result = query(sql, list_id)

    return [] if result.ntuples == 0

    result.map do |tuple|
      status = tuple['completed'] == 't' ? 'complete' : ''
      { id: tuple['id'].to_i, name: tuple['name'], status: status }
    end
  end

  def find_todo_from_list(list_id, item_id)
    sql = 'SELECT * FROM todos WHERE lists_id = $1 AND id = $2'
    result = query(sql, list_id, item_id)
  end
end