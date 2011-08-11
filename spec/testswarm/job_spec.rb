require "spec_helper"

describe TestSwarm::Job do
  describe :paylooad do
    before do
      @job = TestSwarm::Job.new
      @job.add_suite "Foo", "http://testswarm.songkick.net/changeset/skweb/1f7103f/test/browser.html?spec=FooSpec"
      @job.add_suite "Bar", "http://testswarm.songkick.net/changeset/skweb/1f7103f/test/browser.html?spec=BarSpec"
    end
    
    it "returns CGI-encoded data to be submitted to the server" do
      @job.payload(:name => "Job Name", :user => "skweb", :auth => "123abc").should == [
        "auth=123abc",
        "browsers=all",
        "job_name=Job+Name",
        "max=1",
        "output=dump",
        "state=addjob",
        "user=skweb",
        "suites[]=Bar",
        "urls[]=http%3A%2F%2Ftestswarm.songkick.net%2Fchangeset%2Fskweb%2F1f7103f%2Ftest%2Fbrowser.html%3Fspec%3DBarSpec",
        "suites[]=Foo",
        "urls[]=http%3A%2F%2Ftestswarm.songkick.net%2Fchangeset%2Fskweb%2F1f7103f%2Ftest%2Fbrowser.html%3Fspec%3DFooSpec"
      ].join("&")
    end
    
    it "allows defaults to be overridden" do
      @job.payload(:browsers => "popular").should =~ /browsers=popular/
      @job.payload(:max => 5).should =~ /max=5/
    end
  end
  
end

