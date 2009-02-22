require 'rubygems'
require 'sinatra'
require 'sequel'

DB = Sequel.sqlite('url') unless defined?(DB)

dataset = DB[:urls]

get '/:url' do
  redirect dataset.filter(:id => params[:url].to_i(36)).first[:url]
end

get '/' do
  layout_head +
  "URL goes here: <form action='create' method='post'>
     <p>
       <label for='url'>
       <input type='text' name='url' id='url' size='100'> <input type='submit' name='submit' value='URLize'>
     </p>
   </form>" +
   layout_footer
end

post '/create' do
  dataset << {:url => params[:url] }
  url = dataset.filter(:url => params[:url])
  # Dunno why we have to call [:id] twice...
  id = url[:id][:id].to_s(36)
  layout_head +
  "Your new URL is http://url.com/#{id}" +
  layout_footer
end

def layout_head
  "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\"
     \"http://www.w3.org/TR/html4/strict.dtd\">

  <html lang='en'>
  <head>
  	<meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
  	<title>url</title>
  </head>
  <body>
  "
end

def layout_footer
  "</body>
  </html>"
end