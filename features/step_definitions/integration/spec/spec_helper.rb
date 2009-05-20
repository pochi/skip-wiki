$LOAD_PATH << File.expand_path("../lib", File.dirname(__FILE__))
require 'rubygems'
require 'spec'
require 'rr'

Spec::Runner.configure do |config|
  config.mock_with :rr
end
