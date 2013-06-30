require "spec_helper"

describe TestSwarm::Project do
  let(:uri)     { URI.new("http://testswarm.songkick.net") }
  let(:client)  { TestSwarm::Client.new("http://testswarm.songkick.net") }
  let(:project) { client.project("skweb", :auth => "123abc") }
  let(:job)     { TestSwarm::Job.new(:rcs => {:type => '', :url => ''}, :directory => '', :inject => '') }

  describe :paylooad do
    before do
      job.add_suite "Foo", "http://testswarm.songkick.net/changeset/skweb/1f7103f/test/browser.html?spec=FooSpec"
      job.add_suite "Bar", "http://testswarm.songkick.net/changeset/skweb/1f7103f/test/browser.html?spec=BarSpec"
    end

    it "returns CGI-encoded data to be submitted to the server" do
      project.payload(job, :name => "Job Name").should == [
        "action=addjob",
        "authID=skweb",
        "authToken=123abc",
        "jobName=Job+Name",
        "runMax=1",
        "browserSets[]=all",
        "runNames[]=Bar",
        "runUrls[]=http%3A%2F%2Ftestswarm.songkick.net%2Fchangeset%2Fskweb%2F1f7103f%2Ftest%2Fbrowser.html%3Fspec%3DBarSpec",
        "runNames[]=Foo",
        "runUrls[]=http%3A%2F%2Ftestswarm.songkick.net%2Fchangeset%2Fskweb%2F1f7103f%2Ftest%2Fbrowser.html%3Fspec%3DFooSpec"
      ].join("&")
    end

    it "allows defaults to be overridden" do
      project.payload(job, :browsers => "popular").should =~ /browserSets\[\]=popular/
      project.payload(job, :max => 5).should =~ /runMax=5/
    end
  end

  describe :submit_job do
    let(:http)     { mock Net::HTTP }
    let(:response) { mock Net::HTTPOK }

    before { job.stub(:inject_script) }

    it "posts the job's CGI payload to the server" do
      Net::HTTP.should_receive(:start).with("testswarm.songkick.net", 80).and_return(http)
      params = {:name => "Job Name"}
      project.should_receive(:payload).with(job, params).and_return("cgi-data")
      http.should_receive(:post).with("/api.php", "cgi-data").and_return(response)
      response.should_receive(:body).at_least(1).and_return(%{{"addjob":{"id":1}}})
      project.submit_job("Job Name", job)
    end

    it "passes options through when constructing the payload" do
      params = {:name => "Job Name", :browsers => "beta"}
      project.should_receive(:payload).with(job, params).and_return("cgi-data")
      FakeWeb.register_uri(:post, "http://testswarm.songkick.net/api.php", :body => %{{"addjob":{"id":75}}})
      project.submit_job("Job Name", job, :browsers => "beta")
    end

    it "returns the ID of the job" do
      FakeWeb.register_uri(:post, "http://testswarm.songkick.net/api.php", :body => %{{"addjob":{"id":75,"runTotal":2,"uaTotal":8}}})
      project.submit_job("Job Name", job).should == "75"
    end
  end

end

