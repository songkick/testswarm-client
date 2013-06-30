Gem::Specification.new do |s|
  s.name              = "testswarm-client"
  s.version           = "0.2.1"
  s.summary           = "Client library for Mozilla TestSwarm"
  s.author            = "James Coglan"
  s.email             = "jcoglan@gmail.com"

  s.extra_rdoc_files  = %w(README.rdoc)
  s.rdoc_options      = %w(--main README.rdoc)

  s.files             = %w(README.rdoc) + Dir.glob("{lib,spec}/**/*")
  s.require_paths     = ["lib"]

  s.add_development_dependency("fakeweb")
  s.add_development_dependency("rspec")
end

