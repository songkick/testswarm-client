require File.dirname(__FILE__) + '/job'
require File.dirname(__FILE__) + '/project'

module TestSwarm
  class Client
    
    def project(name, options = {})
      Project.new(self, name, options)
    end
    
  end
end

