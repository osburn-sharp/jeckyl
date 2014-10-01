$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'jeckyl'
require 'rspec'

RSpec.configure do |config|
  config.color = true
  config.formatter = :doc
  # using older shoulds for the time being
  config.expect_with :rspec do |c|
    c.syntax = :should             # disables `expect` and deprecation warnings
  end
end
