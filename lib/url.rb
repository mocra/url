require 'rubygems'
require 'sinatra'
require 'sequel'
require 'haml'

def missing_url
  raise Sinatra::NotFound, "We could not find that URL."
end

def create_and_display(url)
  url = assume_http(url)
  if url_chain?(url)
    raise "You've been bad.<br />You cannot create URL chains."
  elsif url.length.zero?
    raise "Input a URL, please."
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