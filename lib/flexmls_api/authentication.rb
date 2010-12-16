require 'openssl'
require 'faraday'
require 'faraday_middleware'
#require 'typhoeus'
require 'yajl'
require 'date'
module FlexmlsApi::Authentication

  def authenticate
    sig = sign("#{@api_secret}ApiKey#{@api_key}")
    url = "#{@endpoint}/v1/session?ApiKey=#{@api_key}&ApiSig=#{sig}"
    FlexmlsApi.logger.debug("Authenticating to #{url}")
    conn = connection
    resp = conn.post '/v1/session', "ApiKey" => @api_key, "ApiSig" => sig
    FlexmlsApi.logger.debug("Response: #{resp.inspect}")
    @session = Session.new(resp.body["D"]["Results"][0])
    FlexmlsApi.logger.debug("Session created: #{@session.inspect}")
  end
  
  def sign(sig)
    Digest::MD5.hexdigest(sig)
  end

  def sign_token(path, params = {}, post_data="")
    sign("#{@api_secret}ApiKey#{@api_key}ServicePath/#{version}#{path}#{build_param_string(params)}#{post_data}")
  end
  
  def build_param_string(param_hash)
    return "" if param_hash.nil?
      sorted = param_hash.sort do |a,b|
            a.to_s <=> b.to_s
      end
      params = ""
      sorted.each do |key,val|
        params += key.to_s + val.to_s
      end
      params
  end
  
  class Session
    attr_accessor :auth_token, :expires, :roles 
    def initialize(options)
      @auth_token = options["AuthToken"]
      @expires = DateTime.parse options["Expires"]
      @roles = options["Roles"]
    end
    def expired?
      DateTime.now > @expires
    end
  end
  
  def connection()
    conn = Faraday::Connection.new(:url => @endpoint, 
      :ssl => {:verify => false}, 
      :headers => {:accept => 'application/json'}) do |builder|
      builder.adapter Faraday.default_adapter
      builder.use FlexmlsApi::FaradayExt::ApiErrors
      builder.use Faraday::Response::ParseJson
    end
    FlexmlsApi.logger.debug("Connection: #{conn.inspect}")
    conn
  end
  

end

