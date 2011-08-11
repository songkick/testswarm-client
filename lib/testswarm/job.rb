module TestSwarm
  class Job
    
    def initialize
      @suites = {}
    end
    
    def add_suite(name, url)
      @suites[name] = url
    end
    
    def each_suite
      @suites.keys.sort.each do |name|
        yield(name, @suites[name])
      end
    end
    
  end
end

