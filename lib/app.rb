DB = Sequel.sqlite('url') unless defined?(DB)

def dataset; DB[:urls]; end

AppError = Class.new(Exception)

get '/p/:url' do
  begin
    @url = dataset.filter(:id => params[:url].to_i(36)).first[:url]
    @url = assume_http(@url)
    haml :preview
  rescue
    missing_url
  end
end

get '/:url' do
  begin
    url = dataset.filter(:id => params[:url].to_i(36)).first[:url]
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
