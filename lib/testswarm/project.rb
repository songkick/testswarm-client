module TestSwarm
  class Project
    
    class SubmissionFailed < StandardError ; end
    
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
      job.each_suite do |name, url|
        query += "&suites[]=#{escape name}&urls[]=#{escape url}"
      end
      query
    end
    
    def submit_job(name, job, options = {})
      return nil unless job.new?
      
      job.inject_script(@client.url + INJECT_SCRIPT)
      
      http = Net::HTTP.start(@client.uri.host, @client.uri.port)
      data = payload(job, job_params(name, options))
      
      job.log "POST #{@client.url} #{data}"
      
      response = http.post('/', data)
      job.log "Response: #{response.body}"
      
      matches = response.body.match(/\/job\/(\d+)\//)
      unless matches
        raise SubmissionFailed, "Server returned unexpected response: #{response.body}"
      end
      
      job_id = matches[1]
      job.log "Job ID: #{job_id}"
      job_id
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

