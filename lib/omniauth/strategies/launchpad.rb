require 'omniauth'
require 'omniauth-oauth'
require 'oauth/signature/plaintext'
require 'omniauth-launchpad'
#require 'faraday'

module Omniauth
  module Strategies
    class Launchpad < OmniAuth::Strategies::OAuth
      include OmniAuth::Strategy
      option :name, 'launchpad'
      option :fields, [:username, :name, :email]
      option :uid_field, :username
    
      option :client_options, {
        :site => "https://launchpad.net",
        :realm => "https://api.launchpad.net/",
        :authorize_path => '/+authorize-token',
        :access_token_path => '/+access-token',
        :request_token_path => '/+request-token',
        :signature_method   => 'PLAINTEXT',
        :http_method => :post,
        :scheme        =>:body
      }
      def initialize(app, consumer_key="babun", options={}, &block)
        options[:oauth_consumer_key] = consumer_key
        options[:oauth_consumer_secret] = consumer_secret
        super(app, consumer_key, nil, options, &block)
      end
    
      def raw_user_info
          puts "before: #{@access_token.inspect}"
          request_options = {:oauth_consumer_key => options[:oauth_consumer_key], :realm => "https://api.launchpad.net/"}
          request_options.merge!(options[:authorize_params])
          @access_token.consumer.options[:scheme] = :header
          info = @access_token.get('https://api.launchpad.net/devel/people/+me', {'Accept' => 'application/json'})
          info = @access_token.get(info["location"], {'Accept' => 'application/json'})
          @raw_user_info ||= MultiJson.load info.body
      end
    
      uid { raw_user_info['name'] }
    
      info do
        {
          name: raw_user_info['display_name'],
          email: raw_user_info['preferred_email_address_link'].split(/\//)[-1],
          username: raw_user_info['name']
        }
      end
    
      extra do
        { raw_user_info: raw_user_info }
      end
      def request_phase
        puts "Request info: #{options.request_param}"
          request_options = {:oauth_consumer_key => options[:oauth_consumer_key], :realm => "https://api.launchpad.net/"}
            request_options.merge!(options[:authorize_params])
          
            request_token = consumer.get_request_token({:oauth_callback => callback_url}, request_options)
            session['oauth'] ||= {}
            session['oauth'][name.to_s] = {'callback_confirmed' => request_token.callback_confirmed?, 'request_token' => request_token.token, 'request_secret' => request_token.secret}
            r = Rack::Response.new
          
            if request_token.callback_confirmed?
              r.redirect(request_token.authorize_url)
            else
              r.redirect(request_token.authorize_url(:oauth_callback => callback_url))
            end
            @request_token = request_token
            r.finish
          
            rescue ::Timeout::Error => e
              fail!(:timeout, e)
            rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError => e
              fail!(:service_unavailable, e)
          end
    end
  end
end
