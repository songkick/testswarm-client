require 'cgi'
require 'fileutils'
require 'json'
require 'net/http'
require 'uri'

require File.dirname(__FILE__) + '/job'
require File.dirname(__FILE__) + '/project'

module TestSwarm

  DEFAULT_BROWSERS = 'all'
  DEFAULT_MAX      = 1
  INJECT_SCRIPT    = '/js/inject.js'

  class Client
    attr_reader :url

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

