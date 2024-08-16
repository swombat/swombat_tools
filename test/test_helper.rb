require 'vcr'
require_relative "support/vcr_multipart_matcher"

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

unless defined?(Team)
  class Team
  end
end

def claude_api_token
  ENV["CLAUDE_API_KEY"] || YAML.load_file("test/api_keys.yml")["claude"]
end

def openai_api_token
  ENV["OPENAI_API_KEY"] || YAML.load_file("test/api_keys.yml")["openai"]
end

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
  # config.cassette_library_dir = "spec/fixtures/cassettes"
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri, VCRMultipartMatcher.new]
  }
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { claude_api_token }
  config.filter_sensitive_data("<OPENAI_API_KEY>") { openai_api_token }
end


require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

Dir[Rails.root.join('test/app/apis/**/*_test.rb')].each { |f| require f }

def vcr(cassette_name)
  VCR.use_cassette(cassette_name, record: :new_episodes) do
    yield
  end
end
