module TestSwarm
  class Project
    
    attr_reader :name
    
    def initialize(client, name, options = {})
      @client  = client
      @name    = name
      @options = options
    end
    
    def payload(job, params = {})
      params = {
        'auth'     => @options[:auth],
        'browsers' => params[:browsers] || DEFAULT_BROWSERS,
        'job_name' => params[:name],
        'max'      => params[:max] || DEFAULT_MAX,
        'output'   => 'dump',
        'state'    => 'addjob',
        'user'     => @name
      }
      query  = ''
      params.keys.sort.each do |key|
        query += '&' unless query.empty?
        query += "#{key}=#{escape params[key]}"
      end
      job.suites.keys.sort.each do |name|
        query += "&suites[]=#{escape name}&urls[]=#{escape job.suites[name]}"
      end
      query
    end
    
    def submit_job(name, job, options = {})
      http = Net::HTTP.start(@client.uri.host, @client.uri.port)
      data = payload(job, job_params(name, options))
      response = http.post('/', data)
      response.body.match(/\/job\/(\d+)\//)[1]
    end
    
  private
    
    def escape(string)
      CGI.escape(string.to_s)
    end
    
    def job_params(name, options)
      options.merge(:name => name)
    end
    
  end
end

