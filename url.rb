require 'rubygems'
require 'sinatra'
require 'sequel'
require 'haml'

DB = Sequel.sqlite('url') unless defined?(DB)

dataset = DB[:urls]

get '/p/:url' do
  begin
    @url = dataset.filter(:id => params[:url].to_i(36)).first[:url]
    haml :preview
  rescue
    haml :error
  end
end

get '/:url' do
  begin
    redirect dataset.filter(:id => params[:url].to_i(36)).first[:url]
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
    
    # Assume http if nothing is specified.
    if !/^(.*):\/\//.match(params[:url])
      params[:url] = "http://#{params[:url]}"
    end
    
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