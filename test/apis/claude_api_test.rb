require_relative "../test_helper"

class ClaudeApiTest < ActiveSupport::TestCase
  test "should be able to make a simple request from ClaudeApi" do
    request = "Hi there! Please tell me something nice as a greeting."
    expected_response = "Hello! It's wonderful to hear from you today. I hope you're having a fantastic day filled with joy, positivity, and exciting opportunities. Remember, you are unique, valuable, and capable of amazing things. Your presence brightens the world around you!"

    vcr("Claude simple request") do
      response = claude_api.get_response(
        params: {
          model: "claude-3-5-sonnet-20240620",
          user: request,
        }
      )
      assert response["content"].present?
      assert_equal expected_response, response["content"][0]["text"]
    end
    assert true
  end

  test "should be able to make a streaming request from ClaudeApi" do
    request = "Hi there! Please tell me something nice as a greeting."
    expected_response = "Hello! It's wonderful to see you today. I hope you're having a fantastic day so far, and if not, I hope our conversation brings a smile to your face. Remember, you are valued, appreciated, and capable of amazing things. Wishing you all the best!"

    vcr("Claude streaming request") do
      streamed_response = ""
      response = claude_api.get_response(
        params: {
          model: "claude-3-5-sonnet-20240620",
          user: request,
        },
        stream_proc: Proc.new { |incremental_response, delta| streamed_response += delta },
        stream_response_type: :text
      )
      assert_equal expected_response, streamed_response
      assert response["content"].present?
      assert_equal expected_response, response["content"][0]["text"]
    end
  end

  test "should be able to make a streaming json request from ClaudeApi" do
    request = "Hi there! Please give me three fun and interesting facts about cats. Respond ONLY with a JSON array, without any additional text or explanation. Each object in the array should have 'fact' and 'category' keys."
    # format = "[{\"category\":\"age\",\"fact\":\"Cats are usually between 1-15 years old.\"}, ... ]"
    expected_response = %([\n  {\n    \"fact\": \"Cats can make over 100 different vocal sounds, while dogs can only make about 10.\",\n    \"category\": \"Communication\"\n  },\n  {\n    \"fact\": \"A group of cats is called a 'clowder'.\",\n    \"category\": \"Terminology\"\n  },\n  {\n    \"fact\": \"Cats can jump up to six times their length in a single bound.\",\n    \"category\": \"Physical Abilities\"\n  }\n])
    expected_objects = JSON.parse(expected_response)

    vcr("Claude JSON streaming request") do
      response_array = []
      response = claude_api.get_response(
        params: {
          model: "claude-3-5-sonnet-20240620",
          user: request
        },
        stream_proc: Proc.new { |json_object| response_array << json_object },
        stream_response_type: :json
      )
      # assert_equal expected_response, streamed_response
      assert response["content"].present?
      expected_objects.each do |expected_object|
        assert_includes response_array, expected_object
      end
      assert_equal expected_response, response["content"][0]["text"]
    end
  end

  test "should be able to make a streaming json request from ClaudeApi which deals with text around the JSON array" do
    request = "Hi there! Please give me three fun and interesting facts about cats. Respond with a JSON array, along with a preamble and conclusion. Each object in the array should have 'fact' and 'category' keys."
    # format = "[{\"category\":\"age\",\"fact\":\"Cats are usually between 1-15 years old.\"}, ... ]"
    expected_response = "Here's a JSON array with three fun and interesting facts about cats, along with a preamble and conclusion:\n\nPreamble: Cats are fascinating creatures that have captivated humans for thousands of years. Here are some intriguing facts about our feline friends:\n\n[\n  {\n    \"fact\": \"Cats can make over 100 different vocal sounds, while dogs can only make about 10.\",\n    \"category\": \"Communication\"\n  },\n  {\n    \"fact\": \"A group of cats is called a 'clowder'.\",\n    \"category\": \"Terminology\"\n  },\n  {\n    \"fact\": \"Cats spend approximately 70% of their lives sleeping.\",\n    \"category\": \"Behavior\"\n  }\n]\n\nConclusion: These facts demonstrate just how unique and interesting cats can be. From their diverse vocal range to their sleeping habits, cats continue to surprise and delight us with their quirks and behaviors."
    expected_response_clean = %([{\"fact\":\"Cats can make over 100 different vocal sounds, while dogs can only make about 10.\",\"category\":\"Communication\"},{\"fact\":\"A group of cats is called a 'clowder'.\",\"category\":\"Terminology\"},{\"fact\":\"Cats spend approximately 70% of their lives sleeping.\",\"category\":\"Behavior\"}])
    expected_objects = JSON.parse(expected_response_clean)

    vcr("Claude JSON noisy streaming request") do
      response_array = []
      response = claude_api.get_response(
        params: {
          model: "claude-3-5-sonnet-20240620",
          user: request
        },
        stream_proc: Proc.new { |json_object| response_array << json_object },
        stream_response_type: :json
      )
      # assert_equal expected_response, streamed_response
      assert response["content"].present?
      expected_objects.each do |expected_object|
        assert_includes response_array, expected_object
      end
      assert_equal expected_response, response["content"][0]["text"]
    end
  end



  def claude_api
    @claude_api ||= ClaudeApi.new(access_token: claude_api_token)
  end

end
