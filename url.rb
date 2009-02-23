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
  if dataset.filter(:url => url).empty?
    dataset << {:url => url }
  end
  
  url = dataset.filter(:url => url)
  # Dunno why we have to call [:id] twice...
  url[:id][:id].to_s(36)
  haml :url
end