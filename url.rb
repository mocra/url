require 'rubygems'
require 'sinatra'
require 'yaml'
require 'sequel'

__DIR__ = File.dirname(__FILE__)
begin

	database = YAML::load(File.open(__DIR__+"/config/database.yml"))
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
		@url = $dataset.filter(:id => url2int(params[:url])).first[:url]
		@url = assume_http(@url)
		haml :preview
	rescue Exception => e
		missing_url
	end
end

get '/:url' do
	begin
		url = $dataset.filter(:id => url2int(params[:url])).first[:url]
		redirect assume_http(url)
	rescue
		missing_url
	end
end

get '/' do
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
	else
		if $dataset.filter(:url => url).empty?
			$dataset << {:url => url }
		end
	
		url = $dataset.filter(:url => url)
		@id = int2url(url[:id][:id])
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


DIGITS = [ ('0'..'9').to_a, ('A'..'Z').to_a, ('a'..'z').to_a ].flatten
RADIX = DIGITS.length

def int2url(i)
  if i == 0
    return '0'
  end

  url = []

  while i != 0
    url.unshift DIGITS[i % RADIX]
    i /= RADIX
  end

  url * ''
end

def url2int(u)
  digits = u.split('').reverse
  int = 0

  digits.each_with_index do |d,offset|
    int += DIGITS.index(d) * (RADIX ** offset)
  end

  int
end

