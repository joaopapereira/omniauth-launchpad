$:.push File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'bundler'
Bundler.setup :default, :development, :example, ENV['RACK_ENV']

require 'sinatra'
require 'omniauth-launchpad'
require 'pry'
require 'httplog'
HttpLog.options[:log_headers]   = true

use Rack::Session::Cookie
use OmniAuth::Strategies::Launchpad

get '/' do
  "<a href='/auth/launchpad'>Auth with BrowserID</a>"
end

post '/auth/launchpad/callback' do
  content_type 'text/plain'
  request.env['omniauth.auth'].to_hash.inspect
end