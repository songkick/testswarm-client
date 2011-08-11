module TestSwarm
  class Job
    
    DEFAULT_BROWSERS = 'all'
    DEFAULT_MAX      = 1
    
    def initialize(project)
      @project = project
      @suites  = {}
    end
    
    def add_suite(name, url)
      @suites[name] = url
    end
    
    def payload(options = {})
      params = {
        'auth'     => @project.auth,
        'browsers' => options[:browsers] || DEFAULT_BROWSERS,
        'job_name' => options[:name],
        'max'      => options[:max] || DEFAULT_MAX,
        'output'   => 'dump',
        'state'    => 'addjob',
        'user'     => @project.name
      }
      query  = ''
      params.keys.sort.each do |key|
        query += '&' unless query.empty?
        query += "#{key}=#{escape params[key]}"
      end
      @suites.keys.sort.each do |name|
        query += "&suites[]=#{escape name}&urls[]=#{escape @suites[name]}"
      end
      query
    end
    
  private
    
    def escape(string)
      CGI.escape(string.to_s)
    end
    
  end
end

