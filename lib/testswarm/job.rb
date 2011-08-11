module TestSwarm
  class Job
    
    attr_reader :suites
    
    def initialize
      @suites = {}
    end
    
    def add_suite(name, url)
      @suites[name] = url
    end
    
  end
end

