require "spec_helper"

describe TestSwarm::Job do
  let(:params) {{
    :rcs        => {
      :type     => 'git',
      :url      => 'git://github.com/songkick/foo.git'
    },
    
    :directory  => "/var/www/testswarm/changeset/skweb",
    :build      => 'coffee -c spec/',
    :inject     => 'spec/*.html'
  }}
  
  describe :new do
    def raises_error
      lambda {
        TestSwarm::Job.new(params)
      } .should raise_error(TestSwarm::Job::MissingConfig)
    end
    
    it "raises an error if no RCS is given" do
      params.delete(:rcs)
      raises_error
    end
    
    it "raises an error if no RCS type is given" do
      params[:rcs].delete(:type)
      raises_error
    end
    
    it "raises an error if no RCS URL is given" do
      params[:rcs].delete(:url)
      raises_error
    end
    
    it "raises an error if no directory is given" do
      params.delete(:directory)
      raises_error
    end
    
    it "raises an error if no inject is given" do
      params.delete(:inject)
      raises_error
    end
  end
end

