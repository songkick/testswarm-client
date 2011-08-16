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
      @diff      = settings[:diff]
      @build     = settings[:build]
      @inject    = settings[:inject]
      @keep      = settings[:keep]
      @new       = true
      
      raise MissingConfig, "Required setting :rcs is missing" unless @rcs
      raise MissingConfig, "Required setting :rcs->:type is missing" unless @rcs[:type]
      raise MissingConfig, "Required setting :rcs->:url is missing" unless @rcs[:url]
      raise MissingConfig, "Required setting :directory is missing" unless @directory
      raise MissingConfig, "Required setting :inject is missing" unless @inject
      
      @directory = File.expand_path(@directory)
      
      Kernel.at_exit { close_logfile }
    end
    
    def add_suite(name, url)
      @suites[name] = url
    end
    
    def each_suite
      @suites.keys.sort.each do |name|
        yield(name, @suites[name])
      end
    end
    
    def new?
      @new
    end
    
    def prepare!
      raise AlreadyPrepared if @prepared
      @prepared = true
      
      @pwd = Dir.pwd
      
      enter_base_directory
      
      return @new = false unless acquire_lock
      
      checkout_codebase
      determine_revision
      discard_old_releases
      
      if existing_job? or not javascript_changed?
        @new = false
        return reset
      end
      
      build_project
      reset
    end
    
    def revision
      unless @revision
        raise UnknownRevision, "Job may not have been prepared"
      end
      @revision
    end
    
    def inject_script(url)
      return unless @inject
      
      log "chdir #{File.join @directory, revision}"
      Dir.chdir(File.join(@directory, revision))
      
      Dir.glob(@inject).each do |path|
        log "Injecting #{url} into #{path}"
        html = File.read(path)
        html.gsub! /<\/head>/, %Q{<script>document.write('<scr' + 'ipt src="#{url}?' + (new Date).getTime() + '"><\/scr' + 'ipt>');<\/script><\/head>}
        File.open(path, 'w') { |f| f.write(html) }
      end
    end
    
    def log(message)
      FileUtils.mkdir_p(@directory)
      @logfile ||= File.open(File.join(@directory, 'testswarm.log'), 'a')
      @logfile.sync = true
      @logfile.puts("[#{Time.now.strftime '%Y-%m-%d %H:%M:%S'}] #{message}")
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
    
    def acquire_lock
      if File.exist?('.lock')
        log "Locked, marking job as not new"
        return false
      end
      
      log "Writing lock to #{@directory}/.lock"
      File.open('.lock', 'w') do |f|
        f.sync = true
        f.write('')
      end
      true
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
      
      log "chdir #{tmp_dir}"
      Dir.chdir(tmp_dir)
      
      if @rcs[:branch]
        log "git checkout origin/#{@rcs[:branch]}"
        `git checkout origin/#{@rcs[:branch]}`
      end
      log "git submodule update --init --recursive"
      `git submodule update --init --recursive`
      
      log "chdir #{@directory}"
      Dir.chdir(@directory)
    end
    
    def determine_revision
      @revision = case @rcs[:type]
                  when 'svn' then determine_svn_revision
                  when 'git' then determine_git_revision
                  else ''
                  end
      
      @revision.strip!
      log "Revision: #{@revision}"
      log "Previous: #{@previous_revision}" if @previous_revision
      
      if @revision.empty?
        reset
        raise UnknownRevision, "Could not determine revision"
      end
      
      log "chdir #{@directory}"
      Dir.chdir(@directory)
    end
    
    def determine_svn_revision
      @previous_revision = Dir.entries(@directory).
                           grep(/^\d+$/).
                           sort_by { |s| s.to_i }.
                           last
      
      log "svn info | grep Revision"
      `svn info | grep Revision`.gsub(/Revision: /, '')
    end
    
    def determine_git_revision
      @previous_revision = Dir.entries(@directory).
                           grep(/^[0-9a-f]+$/).
                           sort_by { |s| latest_git_commits(100).index(s) }.
                           first
      
      log "git rev-parse --short HEAD"
      `git rev-parse --short HEAD`
    end
    
    def discard_old_releases
      return unless @keep
      
      log "chdir #{tmp_dir}"
      Dir.chdir(tmp_dir)
      
      latest_commits = case @rcs[:type]
                       when 'svn' then latest_svn_commits(@keep)
                       when 'git' then latest_git_commits(@keep)
                       end
      
      log "Keeping releases #{latest_commits.join ', '}"
      
      log "chdir #{@directory}"
      Dir.chdir(@directory)
      
      Dir.entries(@directory).each do |entry|
        next unless entry =~ /^[a-z0-9]+$/i
        next if latest_commits.include?(entry)
        
        log "rm -rf #{entry}"
        FileUtils.rm_rf(entry)
      end
    end
    
    def latest_svn_commits(n)
      `svn log --limit 5`.strip.
      split("\n").
      grep(/^r\d+/).
      map { |line| line.split(/^r|\s*\|\s*/)[1] }
    end
    
    def latest_git_commits(n)
      `git log --oneline | head -#{n} | cut -d ' ' -f 1`.strip.split("\n")
    end
    
    def existing_job?
      File.exists?(File.join(@directory, @revision))
    end
    
    def javascript_changed?
      return true unless @diff and @previous_revision
      
      log "chdir #{tmp_dir}"
      Dir.chdir(tmp_dir)
      
      [@diff].flatten.each do |pattern|
        return true if javascript_changed_in?(pattern)
      end
      false
    end
    
    def javascript_changed_in?(pattern)
      case @rcs[:type]
      when 'svn' then javascript_changed_in_svn?(pattern)
      when 'git' then javascript_changed_in_git?(pattern)
      end
    end
    
    def javascript_changed_in_svn?(pattern)
      counter = "svn diff -r #{@previous_revision}:#{@revision} | grep 'Index:' | grep '#{pattern}' | wc -l"
      count = `#{counter}`
      log "#{counter} -> #{count}"
      count.strip.to_i > 0
    end
    
    def javascript_changed_in_git?(pattern)
      counter = "git diff --stat #{@previous_revision} HEAD | grep '#{pattern}' | wc -l"
      count = `#{counter}`
      log "#{counter} -> #{count}"
      count.strip.to_i > 0
    end
    
    def build_project
      log "chdir #{@directory}"
      Dir.chdir(@directory)
      
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
      release_lock
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
    
    def release_lock
      log "rm #{@directory}/.lock"
      FileUtils.rm("#{@directory}/.lock")
    end
    
    def close_logfile
      @logfile.close if @logfile
      @logfile = nil
    end
    
  end
end

