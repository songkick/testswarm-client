require "bundler/setup"
require File.dirname(__FILE__) + '/../lib/testswarm/client'
require 'fakeweb'

FakeWeb.allow_net_connect = false

