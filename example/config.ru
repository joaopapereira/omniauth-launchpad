require 'bundler/setup'
require 'sinatra/base'
require 'omniauth'
require 'launchpad'



class App < Sinatra::Base

  get '/' do
    redirect '/auth/launchpad'
  end
  # Support both GET and POST for callbacks
  %w(get post).each do |method|
    send(method, "/auth/:provider/callback") do
      # Everything you care about is in env['omniauth.auth']
      # You'll probably want to keep track of your credential hash somewhere.
      # Loading it into a client object should be easy:
      # client.authorization.update_token!(credential_hash)
      content_type 'application/json'
      MultiJson.encode(request.env)
    end
  end
  get '/auth/failure' do
    content_type 'application/json'
    MultiJson.encode(request.env)
  end
end

use Rack::Session::Cookie

use OmniAuth::Builder do
  provider :launchpad,
    ENV['CLIENT_ID'],
    ENV['CLIENT_SECRET'],
    :scope => [
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/plus.me'
    ],
    :skip_info => false
end

run App.new
