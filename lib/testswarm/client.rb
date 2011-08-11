require 'cgi'
require 'net/http'
require 'uri'

require File.dirname(__FILE__) + '/job'
require File.dirname(__FILE__) + '/project'

module TestSwarm
  
  DEFAULT_BROWSERS = 'all'
  DEFAULT_MAX      = 1
  
  class Client
    def initialize(url)
      @url = url
    end
    
    def project(name, options = {})
      Project.new(self, name, options)
    end
    
    def uri
      @uri ||= URI.parse(@url)
    end
    
  end
  
end

