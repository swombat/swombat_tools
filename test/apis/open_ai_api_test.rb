require_relative "../test_helper"

class OpenAiApiTest < DryApiTest
  self.api_token = openai_api_token
  self.yaml_file = "test/support/open_ai_api_test_data.yml"
end
