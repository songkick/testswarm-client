module TestSwarm
  class Project
    
    attr_reader :name
    
    def initialize(client, name, options = {})
      @client  = client
      @name    = name
      @options = options
    end
    
    def submit_job(name, job)
      http = Net::HTTP.start(@client.uri.host, @client.uri.port)
      data = job.payload(job_params(name))
      response = http.post('/', data)
      response.body.match(/\/job\/(\d+)\//)[1]
    end
    
  private
    
    def job_params(name)
      {:name => name, :user => @name, :auth => @options[:auth]}
    end
    
  end
end

