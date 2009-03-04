require 'rubygems'
require 'sinatra'
require 'yaml'
require 'sequel'


begin
	database = YAML::load(File.open("config/database.yml"))
	if database["adapter"] == "sqlite" || database["adapter"] == "sqlite3"
		DB = Sequel.sqlite('url') unless defined?(DB)
	elsif database["adapter"] == "mysql"
		DB = Sequel.mysql(database["database"],
											:user => database["user"] || database["username"],
											:password => database["password"],
											:host => database["host"] || 'localhost') unless defined?(DB)
	end
	
	unless DB.table_exists?(:urls)
		DB.create_table :urls do
			primary_key :id
			column :url, :text
		end
	end
	$dataset = DB[:urls]
end

class AppError < Exception
	
end

# We paginate 7 because the twitter search url can only be so long, we'll be conservative and try to keep this under 255.
def paginate
  @paginated_rows = $dataset.reverse_order(:id).paginate(params[:page].to_i, 7)
end

def next_page
  !$dataset.reverse_order(:id).paginate(params[:page].to_i + 1, 7).empty?
end

def previous_page
  return false if params[:page] == "1"
  !$dataset.reverse_order(:id).paginate(params[:page].to_i - 1, 7).empty?
end

get '/urls' do
  params[:page] = "1"
  paginate
  haml :index
end

get '/urls/:page' do
  paginate
  haml :index
end

get '/p/:url' do
	begin
		@url = $dataset.filter(:id => params[:url].to_i(36)).first[:url]
		@url = assume_http(@url)
		haml :preview
	rescue Exception => e
		missing_url
	end
end

get '/:url' do
	begin
		url = $dataset.filter(:id => params[:url].to_i(36)).first[:url]
		redirect assume_http(url)
	rescue
		missing_url
	end
end

get '/' do
  content_type 'text/html', :charset => 'utf-8'
	haml :form
end

# A get based creator so that bookmarklet can be used
get '/c/*' do
	create_and_display(params[:splat].to_s)
end

post '/create' do
	create_and_display(params[:url])
end

[AppError, Sinatra::NotFound].each do |e|
	error e do
		@error = request.env["sinatra.error"].name
		haml :error
	end
end



def missing_url
	raise Sinatra::NotFound, "We could not find that URL."
end

def create_and_display(url)
	url
	url = assume_http(url)
	if url_chain?(url)
		@error = "You've been bad.<br />You cannot create URL chains."
		haml :error
	elsif url.length.zero?
		@error = "Input a URL, please."
		haml :error
	elsif !validate(url)
    @error = "That's not how you make URL!"
  	haml :error
	else
		if $dataset.filter(:url => url).empty?
			$dataset << {:url => url }
		end
	
		url = $dataset.filter(:url => url)
		@id = url[:id][:id].to_s(36)
		haml :url
	end
end
 
def url_chain?(string)
	blacklist = [request.env['HTTP_HOST'], "tinyurl", "is.gd", "tr.im", "rubyurl"]
	!!blacklist.detect { |url| string.include?(url) }
end

# Assume http if nothing is specified.
def assume_http(url)
	if !/^(.*):\/\//.match(url)
		url = "http://#{url}"
	end
	url
end

def validate(url)
  !/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/.match(url).nil?
end
