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
    
    def submit_job(name, job)
      http = Net::HTTP.start(@client.uri.host, @client.uri.port)
      data = job.payload(:name => name)
      response = http.post('/', data)
      response.body.match(/\/job\/(\d+)\//)[1]
    end
    
  end
end

