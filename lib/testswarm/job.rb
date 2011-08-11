module TestSwarm
  class Job
    
    class AlreadyPrepared < StandardError ; end
    class MissingConfig   < StandardError ; end
    class FailedCheckout  < StandardError ; end
    class UnknownRevision < StandardError ; end
    class BuildFailed     < StandardError ; end
    
    def self.create(*args)
      job = new(*args)
      job.prepare!
      job
    end
    
    def initialize(settings)
      @suites    = {}
      @rcs       = settings[:rcs]
      @directory = settings[:directory]
      @build     = settings[:build]
      @inject    = settings[:inject]
      
      raise MissingConfig, "Required setting :rcs is missing" unless @rcs
      raise MissingConfig, "Required setting :rcs->:type is missing" unless @rcs[:type]
      raise MissingConfig, "Required setting :rcs->:url is missing" unless @rcs[:url]
      raise MissingConfig, "Required setting :directory is missing" unless @directory
      raise MissingConfig, "Required setting :inject is missing" unless @inject
      
      @directory = File.expand_path(@directory)
    end
    
    def add_suite(name, url)
      @suites[name] = url
    end
    
    def each_suite
      @suites.keys.sort.each do |name|
        yield(name, @suites[name])
      end
    end
    
    def prepare!
      raise AlreadyPrepared if @prepared
      @prepared = true
      
      @pwd = Dir.pwd
      
      enter_base_directory
      checkout_codebase
      determine_revision
      return reset if existing_job?
      build_project
      reset
    end
    
    def revision
      unless @revision
        raise UnknownRevision, "Job may not have been prepared"
      end
      @revision
    end
    
  private
    
    def tmp_dir
      @tmp_dir ||= "tmp-#{Time.now.to_i}"
    end
    
    def enter_base_directory
      log "mkdir -p #{@directory}"
      FileUtils.mkdir_p(@directory)
      
      log "chdir #{@directory}"
      Dir.chdir(@directory)
    end
    
    def checkout_codebase
      case @rcs[:type]
      when 'svn' then checkout_svn_codebase
      when 'git' then checkout_git_codebase
      end
      unless File.exists?(tmp_dir)
        reset
        raise FailedCheckout, "Failed to check out code from #{@rcs.inspect}"
      end
      log "chdir #{tmp_dir}"
      Dir.chdir(tmp_dir)
    end
    
    def checkout_svn_codebase
      log "svn co #{@rcs[:url]} #{tmp_dir}"
      `svn co #{@rcs[:url]} #{tmp_dir}`
    end
    
    def checkout_git_codebase
      log "git clone #{@rcs[:url]} #{tmp_dir}"
      `git clone #{@rcs[:url]} #{tmp_dir}`
    end
    
    def determine_revision
      @revision = case @rcs[:type]
                  when 'svn' then determine_svn_revision
                  when 'git' then determine_git_revision
                  else ''
                  end
      
      @revision.strip!
      log "Revision: #{@revision}"
      
      if @revision.empty?
        reset
        raise UnknownRevision, "Could not determine revision"
      end
      
      log "chdir #{@directory}"
      Dir.chdir(@directory)
    end
    
    def determine_svn_revision
      log "svn info | grep Revision"
      `svn info | grep Revision`.gsub(/Revision: /, '')
    end
    
    def determine_git_revision
      log "git rev-parse --short HEAD"
      `git rev-parse --short HEAD`
    end
    
    def existing_job?
      File.exists?(File.join(@directory, @revision))
    end
    
    def build_project
      log "mv #{tmp_dir} #{@revision}"
      FileUtils.mv(tmp_dir, @revision)
      
      log "chdir #{@revision}"
      Dir.chdir(@revision)
      
      return unless @build
      
      [@build].flatten.each do |step|
        log step
        `#{step}`
        unless $?.exitstatus.zero?
          reset
          raise BuildFailed, "Failed while running #{step}"
        end
      end
    end
    
    def reset
      remove_tmp
      restore_working_directory
      close_logfile
    end
    
    def remove_tmp
      log "chdir #{@directory}"
      Dir.chdir(@directory)
      log "rm -rf #{tmp_dir}"
      FileUtils.rm_rf(tmp_dir)
    end
    
    def restore_working_directory
      log "chdir #{@pwd}"
      Dir.chdir(@pwd)
    end
    
    def close_logfile
      @logfile.close if @logfile
    end
    
    def log(message)
      FileUtils.mkdir_p(@directory)
      @logfile ||= File.open(File.join(@directory, 'testswarm.log'), 'a')
      @logfile.sync = true
      @logfile.puts("[#{Time.now.strftime '%Y-%m-%d %H:%M:%S'}] #{message}")
    end
    
  end
end

