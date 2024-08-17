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

def openrouter_api_token
  ENV["OPENROUTER_API_KEY"] || YAML.load_file("test/api_keys.yml")["openrouter"]
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
  config.filter_sensitive_data("<OPENROUTER_API_KEY>") { openrouter_api_token }
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


class DryApiTest < ActiveSupport::TestCase

  class_attribute :api_token
  class_attribute :yaml_file

  def yaml_data
    @yaml_data ||= YAML.load_file(yaml_file)
  end

  def api_class
    yaml_data["class"].constantize
  end

  def api
    @api ||= api_class.new(access_token: api_token)
  end

  def model
    yaml_data["model"]
  end

  test "yaml_file is set" do
    skip if self.class == DryApiTest
    assert_not_nil self.class.yaml_file
  end

  test "api_token is set" do
    skip if self.class == DryApiTest
    assert_not_nil self.class.api_token
  end

  test "api is available" do
    skip if self.class == DryApiTest
    assert_not_nil api
  end

  test "should be able to make a simple request" do
    skip if self.class == DryApiTest
    request = yaml_data["simple"]["request"]
    expected_response = yaml_data["simple"]["expected_response"]

    vcr("#{api_class} simple request") do
      response = api.get_response(
        params: {
          model: model,
          user: request,
        }
      )
      assert response["content"].present?
      puts "Actual response (simple): #{response.inspect}" if expected_response != response["content"][0]["text"]
      assert_equal expected_response, response["content"][0]["text"]
    end
    assert true
  end

  test "should be able to make a streaming request" do
    skip if self.class == DryApiTest
    request = yaml_data["streaming"]["request"]
    expected_response = yaml_data["streaming"]["expected_response"]

    vcr("#{api_class} streaming request") do
      streamed_response = ""
      response = api.get_response(
        params: {
          model: model,
          user: request,
        },
        stream_proc: Proc.new { |incremental_response, delta| streamed_response += delta },
        stream_response_type: :text
      )
      assert response["content"].present?
      puts "Actual response (streaming): #{response.inspect}" if expected_response != response["content"][0]["text"]
      assert_equal expected_response, streamed_response
      assert_equal expected_response, response["content"][0]["text"]
    end
  end

  test "should be able to make a streaming json request" do
    skip if self.class == DryApiTest
    request = yaml_data["JSON_streaming"]["request"]
    expected_response = yaml_data["JSON_streaming"]["expected_response"]
    expected_objects = JSON.parse(expected_response)

    vcr("#{api_class} JSON streaming request") do
      response_array = []
      response = api.get_response(
        params: {
          model: model,
          user: request
        },
        stream_proc: Proc.new { |json_object| response_array << json_object },
        stream_response_type: :json
      )
      assert response["content"].present?
      puts "Actual response (JSON streaming): #{response.inspect}" if expected_response != response["content"][0]["text"]
      expected_objects.each do |expected_object|
        assert_includes response_array, expected_object
      end
      assert_equal expected_response, response["content"][0]["text"]
    end
  end

  test "should be able to make a streaming json request which deals with text around the JSON array" do
    skip if self.class == DryApiTest
    request = yaml_data["JSON_noisy_streaming"]["request"]
    expected_response = yaml_data["JSON_noisy_streaming"]["expected_response"]
    expected_response_clean = yaml_data["JSON_noisy_streaming"]["expected_response_clean"]
    expected_objects = JSON.parse(expected_response_clean)

    vcr("#{api_class} JSON noisy streaming request") do
      response_array = []
      response = api.get_response(
        params: {
          model: model,
          user: request
        },
        stream_proc: Proc.new { |json_object| response_array << json_object },
        stream_response_type: :json
      )
      assert response["content"].present?
      puts "Actual response (JSON Noisy): #{response.inspect}" if expected_response != response["content"][0]["text"]
      expected_objects.each do |expected_object|
        assert_includes response_array, expected_object
      end
      assert_equal expected_response, response["content"][0]["text"]
    end
  end


end
