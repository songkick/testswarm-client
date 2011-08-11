require "spec_helper"

describe TestSwarm::Project do
  let(:uri)     { URI.new("http://testswarm.songkick.net") }
  let(:client)  { TestSwarm::Client.new("http://testswarm.songkick.net") }
  let(:project) { client.project("skweb", :auth => "123abc") }
  
  describe :submit_job do
    let(:http)     { mock Net::HTTP }
    let(:job)      { TestSwarm::Job.new }
    let(:response) { mock Net::HTTPOK }
    
    it "posts the job's CGI payload to the server" do
      Net::HTTP.should_receive(:start).with("testswarm.songkick.net", 80).and_return(http)
      params = {:name => "Job Name", :user => "skweb", :auth => "123abc"}
      job.should_receive(:payload).with(params).and_return("cgi-data")
      http.should_receive(:post).with("/", "cgi-data").and_return(response)
      response.should_receive(:body).and_return("/job/75/")
      project.submit_job("Job Name", job)
    end
    
    it "passes options through when constructing the payload" do
      params = {:name => "Job Name", :user => "skweb", :auth => "123abc", :browsers => "beta"}
      job.should_receive(:payload).with(params).and_return("cgi-data")
      FakeWeb.register_uri(:post, "http://testswarm.songkick.net/", :body => "/job/75/")
      project.submit_job("Job Name", job, :browsers => "beta")
    end
    
    it "returns the ID of the job" do
      FakeWeb.register_uri(:post, "http://testswarm.songkick.net/", :body => "/job/75/")
      project.submit_job("Job Name", job).should == "75"
    end
  end
end

