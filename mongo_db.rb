require 'mongo'

class MongoDB 
  def initialize()
    @client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'todoUsers')
  end

  def login(username)
    collection = @client[:userLogIns]
    user = {
      name: username,
      logInTime: Time.now.strftime("%d/%m/%Y %H:%M")
    }

    collection.insert_one(user)
  end

  def current_user() 
    collection = @client[:userLogIns]
    user = collection.find({}, { :sort => { :_id => - 1}}).first # .limit(1)

    user.class == BSON::Document ? user : nil
  end

  def disconnect() 
    @client.close
  end
end