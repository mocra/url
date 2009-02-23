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

post '/create' do
  # Don't create duplicate!
  if dataset.filter(:url => params[:url]).empty?
    dataset << {:url => params[:url] }
  end
  
  url = dataset.filter(:url => params[:url])
  # Dunno why we have to call [:id] twice...
  @id = url[:id][:id].to_s(36)
  haml :url
end
 