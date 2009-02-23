require 'rubygems'
require 'sinatra'
require 'sequel'
require 'haml'

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
  
get '/p/:url' do
  begin
    @url = dataset.filter(:id => params[:url].to_i(36)).first[:url]
    @url = assume_http(@url)
    haml :preview
  rescue
    haml :error
  end
end

get '/:url' do
  begin
    url = dataset.filter(:id => params[:url].to_i(36)).first[:url]
    redirect assume_http(url)
  rescue
    @error = "We could not find that URL."
    haml :error
  end
end

get '/' do
  haml :form
end

post '/create' do
  # Don't create duplicate!
  if url_chain?(params[:url])
    @error = "You've been bad.<br />You cannot create URL chains."
    haml :error
  
  else
    
    params[:url] = assume_http(params[:url])
    
    if dataset.filter(:url => params[:url]).empty?
      dataset << {:url => params[:url] }
    end
  
    url = dataset.filter(:url => params[:url])
    # Dunno why we have to call [:id] twice...
    @id = url[:id][:id].to_s(36)
    haml :url
  end
end
 
def url_chain?(string)
  blacklist = [request.env['HTTP_HOST'], "tinyurl", "is.gd", "tr.im", "rubyurl"]
  !!blacklist.detect { |url| params[:url].include?(url) }
end

# Assume http if nothing is specified.
def assume_http(url)
  if !/^(.*):\/\//.match(url)
    url = "http://#{url}"
  end
  url
end