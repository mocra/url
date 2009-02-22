require 'rubygems'
require 'sinatra'
require 'sequel'

DB = Sequel.sqlite('url') unless defined?(DB)

dataset = DB[:urls]

get '/:url' do
  redirect dataset.filter(:id => params[:url].to_i(36)).first[:url]
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
  id = url[:id][:id].to_s(36)
  "Your new URL is http://url.com/#{id}"
end

__END__

@@ layout
%html
  %head
    %link{ :rel => "stylesheet", :href => "style.css"}
  %body
    = yield

@@ form
%form{ :action => "create", :method => "post", :class => "url_form"}
  %p
    %label{ :for => "url" } URL goes here
    %br/
    %input{ :type => "text", :name => "url", :id => "url", :size => 45 }
    %input{ :type => "submit", :name => "submit", :value => "URLize", :class => "button" }
    

.footer
  This site uses the
  %a{ :href => "http://github.com/radar/url"} url
  %a{ :href => "http://sinatrarb.com"} Sinatra
  application built by
  %a{ :href => "http://frozenplague.net"} Ryan Bigg
 