require_relative "../test_helper"

class ClaudeApiTest < DryApiTest
  self.api_token = claude_api_token
  self.yaml_file = "test/support/claude_api_test_data.yml"
end
