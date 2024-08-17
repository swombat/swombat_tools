require_relative "../test_helper"

class OpenRouterMetaLlama3ApiTest < DryApiTest
  self.api_token = openrouter_api_token
  self.yaml_file = "test/support/open_router_meta_llama3_api_test_data.yml"
end
