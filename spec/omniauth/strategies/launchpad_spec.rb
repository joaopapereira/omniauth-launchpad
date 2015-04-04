require 'spec_helper'
require 'omniauth-launchpad'

describe OmniAuth::Strategies::Launchpad do
  def app
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use OmniAuth::Builder do
        provider :launchpad, "testing-launchpad"
      end
      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end
    def strategy
    # return the parameters to a Rack::Builder map call:
    [OmniAuth::Strategies::Launchpad.new, 'bamm']
  end
  def session
    last_request.env['rack.session']
  end

  before do
    stub_request(:post, 'https://launchpad.net/+request-token').
      to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret&oauth_callback_confirmed=true")
  end
  it 'can be camel-cased' do
    OmniAuth::Utils.camelize( 'launchpad' ).should == 'Launchpad'
  end

  describe '/auth/launchpad' do
    context 'successful' do
      before do
        get '/auth/launchpad'
      end

      it 'should redirect to authorize_url' do
        last_response.should be_redirect
        last_response.headers['Location'].should == 'https://launchpad.net/+authorize-token?oauth_token=yourtoken'
      end


      it 'should set appropriate session variables' do
        session['oauth'].should == {"launchpad"=>{"callback_confirmed"=>true, "request_token"=>"yourtoken", "request_secret"=>"yoursecret"}}
      end
    end

    context 'unsuccessful' do
      before do
        stub_request(:post, 'https://launchpad.net/+request-token').
           to_raise(::Net::HTTPFatalError.new(%Q{502 "Bad Gateway"}, nil))
        get '/auth/launchpad'
      end

      it 'should call fail! with :service_unavailable' do
        last_request.env['omniauth.error'].should be_kind_of(::Net::HTTPFatalError)
        last_request.env['omniauth.error.type'] = :service_unavailable
      end

      context "SSL failure" do
        before do
          stub_request(:post, 'https://launchpad.net/+request-token').
             to_raise(::OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed"))
          get '/auth/launchpad'
        end

        it 'should call fail! with :service_unavailable' do
          last_request.env['omniauth.error'].should be_kind_of(::OpenSSL::SSL::SSLError)
          last_request.env['omniauth.error.type'] = :service_unavailable
        end
      end
    end
  end

  describe '/auth/launchpad/callback' do
    before do
      body =<<BODY
oauth_token=PsK9cpbll1KwehhRDckr&oauth_token_secret=M2hsnmsfEIAjS3bTWg6t8X2GKhlm152PRDjLLmtQdr9C8KFZWPl9c8QbLfWddE0qpz5L56pMKKFKEfv1&lp.context=None
BODY

      stub_request(:post, 'https://launchpad.net/+request-token').
        to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret")
      stub_request(:post, "https://launchpad.net/+access-token").
         with(:body =>  hash_including({"oauth_consumer_key"=>"testing-launchpad", 
                                        "oauth_signature"=>"&yoursecret", 
                                        "oauth_signature_method"=>"PLAINTEXT", 
                                        "oauth_token"=>"yourtoken", 
                                        "oauth_version"=>"1.0"})).
         to_return(:status => 200, :body => body, :headers => {})
      stub_request(:get, "https://api.launchpad.net/devel/people/+me").
        to_return(:status => 302, :headers => {"location" =>"https://api.launchpad.net/devel/~theguy"})
      stub_request(:get, "https://api.launchpad.net/devel/~theguy").
        to_return(:status => 200, :body => "bamm")
        
       get '/auth/launchpad/callback', {}, {'rack.session' => {'oauth' => {"launchpad" => {'callback_confirmed' => true, 'request_token' => 'yourtoken', 'request_secret' => 'yoursecret'}}}}
    end


    context "bad gateway (or any 5xx) for access_token" do
      before do
        stub_request(:post, 'https://launchpad.net/+access-token').
           to_raise(::Net::HTTPFatalError.new(%Q{502 "Bad Gateway"}, nil))
        get '/auth/launchpad/callback', {:oauth_verifier => 'dudeman'}, {'rack.session' => {'oauth' => {"launchpad" => {'callback_confirmed' => true, 'request_token' => 'yourtoken', 'request_secret' => 'yoursecret'}}}}
      end

      it 'should call fail! with :service_unavailable' do
        last_request.env['omniauth.error'].should be_kind_of(::Net::HTTPFatalError)
        last_request.env['omniauth.error.type'] = :service_unavailable
      end
    end

    context "SSL failure" do
      before do
        stub_request(:post, 'https://launchpad.net/+access-token').
           to_raise(::OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed"))
        get '/auth/launchpad/callback', {:oauth_verifier => 'dudeman'}, {'rack.session' => {'oauth' => {"launchpad" => {'callback_confirmed' => true, 'request_token' => 'yourtoken', 'request_secret' => 'yoursecret'}}}}
      end

      it 'should call fail! with :service_unavailable' do
        last_request.env['omniauth.error'].should be_kind_of(::OpenSSL::SSL::SSLError)
        last_request.env['omniauth.error.type'] = :service_unavailable
      end
    end
  end

  describe '/auth/launchpad/callback with expired session' do
    before do
      stub_request(:post, 'https://launchpad.net/+request-token').
         to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret")
      get '/auth/launchpad/callback', {:oauth_verifier => 'dudeman'}, {'rack.session' => {}}
    end

    it 'should call fail! with :session_expired' do
      last_request.env['omniauth.error'].should be_kind_of(::OmniAuth::NoSessionError)
      last_request.env['omniauth.error.type'] = :session_expired
    end
  end
end