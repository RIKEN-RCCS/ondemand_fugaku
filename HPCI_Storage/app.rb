require 'erubi'
require './command'

set :erb, :escape_html => true

if development?
  require 'sinatra/reloader'
  also_reload './command.rb'
end

helpers do
  def dashboard_title
    "Open OnDemand"
  end

  def dashboard_url
    "/pun/sys/dashboard/"
  end

  def title
    "HPCI Shared Storage"
  end
end

# Define a route at the root '/' of the app.
get '/' do
  @command = Command.new
  @data, @error = @command.exec(nil)

  # Render the view
  erb :index
end

post '/' do
  @command = Command.new
  @data, @error = @command.exec(params)
  @params = params

  # Render the view
  erb :index
end
