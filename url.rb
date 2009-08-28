require 'rubygems'
require 'sinatra'
require 'haml'
require 'yaml'
require 'sequel'
require 'sequel/extensions/pagination'

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
			column :clicks, :integer, :default => 0
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
	rescue Exception => e
	  missing_url
  end
	
	@url = assume_http(@url)
	haml :preview
end

get '/:url' do
		set = $dataset.filter(:id => url2int(params[:url])).limit(1)
		record = set.first
		set.update(:clicks => record[:clicks].to_i + 1)
		redirect assume_http(record[:url])
end

get '/' do
	haml :form
end

# A get based creator so that bookmarklet can be used
get '/c/*' do
  url = params[:splat].to_s
  
  # Extrapolate extra parameters as belonging to the url passed in, not to /c!
  if params.size > 1
    params.delete('splat')
    url += '?' + params.map { |p| "#{p.first}=#{p.last}" }.join("&") 
  end
	create_and_display(url)
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
  @error = "ooh ahh"
  haml :error
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

