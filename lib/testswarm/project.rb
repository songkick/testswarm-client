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
      cgi = {
        'action'    => 'addjob',
        'authID'    => @name,
        'authToken' => @options[:auth],
        'jobName'   => params[:name],
        'runMax'    => params[:max] || DEFAULT_MAX
      }

      query = ''
      cgi.keys.sort.each do |key|
        query += '&' unless query.empty?
        query += "#{key}=#{escape cgi[key]}"
      end

      browsers = [params[:browsers] || DEFAULT_BROWSERS].flatten
      browsers.each do |browser|
        query += "&browserSets[]=#{escape browser}"
      end

      job.each_suite do |name, url|
        query += "&runNames[]=#{escape name}&runUrls[]=#{escape url}"
      end
      query
    end

    def submit_job(name, job, options = {})
      job.inject_script(@client.url + INJECT_SCRIPT)

      http = Net::HTTP.start(@client.uri.host, @client.uri.port)
      data = payload(job, job_params(name, options))

      job.log "POST #{@client.url} #{data}"

      response = http.post('/api.php', data)
      job.log "Response: #{response.body}"
      job_data = JSON.parse(response.body)['addjob'] rescue nil

      unless job_data
        job.log 'Job submission failed'
        job.log response.body
        return nil
      end

      job.log "Job ID: #{job_data['id']}"
      job.log "Runs: #{job_data['runTotal']}, user agents: #{job_data['uaTotal']}"

      job_data['id'].to_s

    rescue => e
      job.log 'Job submission failed'
      job.log e.message
      job.log e.backtrace
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

