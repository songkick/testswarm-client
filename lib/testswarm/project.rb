module TestSwarm
  class Project
    
    attr_reader :name
    
    def initialize(client, name, options = {})
      @client  = client
      @name    = name
      @options = options
    end
    
    def auth
      @options[:auth]
    end
    
  end
end

