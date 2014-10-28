$LOAD_PATH.unshift File.expand_path('..', __FILE__)
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'rack/test'

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'omniauth'
require 'omniauth-vph'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.extend OmniAuth::Test::StrategyMacros, type: :strategy

  # http://stackoverflow.com/a/7853245/1535165
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
