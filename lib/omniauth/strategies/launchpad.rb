
require 'omniauth'
require 'omniauth-oauth'
require 'omniauth-launchpad'
require 'oauth/signature/plaintext'
module OmniAuth
  module Strategies
    class Launchpad < OmniAuth::Strategies::OAuth
      option :client_options, {
        scheme:              :header,
        http_method:         :post,
        signature_method:    "PLAINTEXT",
        access_token_path:   '/+access-token',
        authorize_path:      '/+authorize-token',
        request_token_path:  '/+request-token',
        site:                'https://launchpad.net'
      }
      
      #def initialize(app, consumer_key=nil, consumer_secret=nil, options={}, &block)
      #  client_options = {
      #    :access_token_path => '/+access-token',
      #    :authorize_path => '/+authorize-token',
      #    :request_token_path => '/+request-token',
      #    :site => 'https://launchpad.net',
      #  }
      #  
      #  options[:client_options] = client_options

      #  super(app, consumer_key, consumer_secret, options, &block)
      #end

      uid do
        user_info['uid']
      end
      
      info do
        user_info
      end
      
      extra do
        { 'user_hash' => user_hash }
      end

      def user_info
        email = user_hash['feed']['id']['$t']

        name = user_hash['feed']['author'].first['name']['$t']
        name = email if name.strip == '(unknown)'

        {
          'email' => email,
          'uid' => email,
          'name' => name,
        }
      end
      
      def user_hash
        # Google is very strict about keeping authorization and
        # authentication separated.
        # They give no endpoint to get a user's profile directly that I can
        # find. We *can* get their name and email out of the contacts feed,
        # however. It will fail in the extremely rare case of a user who has
        # a Google Account but has never even signed up for Gmail. This has
        # not been seen in the field.
        @user_hash ||= MultiJson.decode(@access_token.get('https://www.google.com/m8/feeds/contacts/default/full?max-results=1&alt=json').body)
      end
      def callback_phase 
        raise OmniAuth::NoSessionError.new("Session Expired") if session['oauth'].nil?
        puts 
        token = ::OAuth::Token.new session['oauth'][name.to_s].delete('request_token'), session['oauth'][name.to_s].delete('request_secret')
        request_token = ::OAuth::RequestToken.new(consumer, token.token, token.secret)
        puts "->#{request_token.inspect}"
        puts "...#{request_token.token}"
        _consumer = request_token.consumer
        opts = {:oauth_consumer_key => "bandalho", :oauth_signature => "&#{token.secret}", :oauth_signature_method =>"PLAINTEXT", :oauth_token => token.token}
        #if session['oauth'][name.to_s]['callback_confirmed']
        #  opts[:oauth_verifier] = request['oauth_verifier']
        #else
        #  opts[:oauth_callback] = callback_url
        #end
        
        puts "Going to do the request: #{request_token.authorize_url(opts)}"
        @access_token = _consumer.get_access_token(request_token, opts, opts)
        
        puts @access_token.inspect
        super
      end 
      #def consumer
      #  @consumer = ::OAuth::Consumer.new("baddass", "", {
      #    :scheme             => :header,
      #    :http_method        => :post,
      #    :access_token_path => '/+access-token',
      #    :authorize_path => '/+authorize-token',
      #    :request_token_path => '/+request-token',
      #    :site => 'https://launchpad.net',
      #    :signature_method => 'PLAINTEXT'
      #   })
      #end
      # Monkeypatch OmniAuth to pass the scope and authorize_params in the consumer.get_request_token call
      def request_phase
        request_options = {:oauth_consumer_key => "bandalho", :oauth_signature => "&", :oauth_signature_method =>"PLAINTEXT"}
        request_options = {:oauth_consumer_key => "masta_giga",:oauth_signature => "&", :oauth_signature_method => "PLAINTEXT"}
        
        request_token = consumer.get_request_token({:oauth_callback => "bamm/badabamm"}, request_options)
        session['oauth'] ||= {}
        session['oauth'][name.to_s] = {'callback_confirmed' => request_token.callback_confirmed?, 'request_token' => request_token.token, 'request_secret' => request_token.secret}
        r = Rack::Response.new
      
        if request_token.callback_confirmed?
          r.redirect(request_token.authorize_url)
        else
          r.redirect(request_token.authorize_url(:oauth_callback => callback_url))
        end
        puts "request token is: #{request_token.inspect}"
      
        r.finish
      
        rescue ::Timeout::Error => e
          fail!(:timeout, e)
        rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError => e
          fail!(:service_unavailable, e)
      end
    end
  end
end
