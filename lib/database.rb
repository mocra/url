begin
  database = YAML::load(File.open("config/database.yml"))
  if database["adapter"] == "sqlite" || database["adapter"] == "sqlite3"
    DB = Sequel.sqlite('url') unless defined?(DB)
  elsif database["adapter"] == "mysql"
    DB = Sequel.mysql(database["database"],
                      :user => database["user"] || database["username"],
                      :password => database["password"],
                      :host => database["host"] || 'localhost') unless defined?(DB)
    unless DB.table_exists?(:urls)
      DB.create_table :urls do
        primary_key :id
        column :url, :text
      end
    end
    
  end
  dataset = DB[:urls]
end
