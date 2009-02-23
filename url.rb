require 'rubygems'
require 'sinatra'
require 'sequel'
require 'haml'

DB = Sequel.sqlite('url') unless defined?(DB)
dataset = DB[:urls]

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

# A get based creator so that bookmarklet can be used
get '/c/*' do
  create_and_display(params[:splat])
end

post '/create' do
  create_and_display(params[:url])
end

def create_and_display(url)
  url = assume_http(url)
  if url_chain?(url)
    @error = "You've been bad.<br />You cannot create URL chains."
    haml :error
  elsif url.length.zero?
    @error = "Input a URL, please."
  else
    if dataset.filter(:url => params[:url]).empty?
      dataset << {:url => params[:url] }
    end

    url = dataset.filter(:url => params[:url])
    @id = url[:id][:id].to_s(36)
    haml :url
    # Don't create duplicate!
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