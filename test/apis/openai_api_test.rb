require_relative "../test_helper"

class OpenAIApiTest < ActiveSupport::TestCase
  test "should be able to make a simple request from OpenAiApi" do
    request = "Hi there! Please tell me something nice as a greeting."
    expected_response = "Hello there! It's wonderful to connect with you. I hope your day is filled with joy and positivity. How can I assist you today?"

    vcr("OpenAI simple request") do
      response = openai_api.get_response(
        params: {
          model: "gpt-4o",
          user: request,
        }
      )
      assert response["content"].present?
      assert_equal expected_response, response["content"][0]["text"]
    end
    assert true
  end

  test "should be able to make a streaming request from OpenAiApi" do
    request = "Hi there! Please tell me something nice as a greeting."
    expected_response = "Hello! It's wonderful to connect with you. I hope your day is filled with joy and inspiration. How can I assist you today?"

    vcr("OpenAI streaming request") do
      streamed_response = ""
      response = openai_api.get_response(
        params: {
          model: "gpt-4o",
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

  test "should be able to make a streaming json request from OpenAiApi" do
    request = "Hi there! Please give me three fun and interesting facts about cats. Respond ONLY with a JSON array, without any additional text or explanation. Each object in the array should have 'fact' and 'category' keys."
    # format = "[{\"category\":\"age\",\"fact\":\"Cats are usually between 1-15 years old.\"}, ... ]"
    expected_response = %([\n    {\n        \"fact\": \"Cats have a special reflective layer behind their retinas called the tapetum lucidum, which enhances their night vision.\",\n        \"category\": \"Vision\"\n    },\n    {\n        \"fact\": \"A cat's purr can have a frequency between 25 and 150 Hertz, which is known to be medically therapeutic for both the cat and humans.\",\n        \"category\": \"Health\"\n    },\n    {\n        \"fact\": \"Domestic cats share about 95.6% of their DNA with tigers.\",\n        \"category\": \"Genetics\"\n    }\n])
    expected_objects = JSON.parse(expected_response)

    vcr("OpenAI JSON streaming request") do
      response_array = []
      response = openai_api.get_response(
        params: {
          model: "gpt-4o",
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

  test "should be able to make a streaming json request from OpenAiApi which deals with text around the JSON array" do
    request = "Hi there! Please give me three fun and interesting facts about cats. Respond with a JSON array, along with a preamble and conclusion. Each object in the array should have 'fact' and 'category' keys."
    # format = "[{\"category\":\"age\",\"fact\":\"Cats are usually between 1-15 years old.\"}, ... ]"
    expected_response = "Sure, I'd be happy to share some fun and interesting facts about cats! Below is a JSON array containing three unique facts about our feline friends:\n\n```json\n[\n  {\n    \"fact\": \"Cats have a special reflective layer behind their retinas called the tapetum lucidum, which enhances their night vision.\",\n    \"category\": \"Anatomy\"\n  },\n  {\n    \"fact\": \"A group of cats is called a 'clowder,' and a group of kittens is known as a 'kindle.'\",\n    \"category\": \"Terminology\"\n  },\n  {\n    \"fact\": \"Cats can rotate their ears 180 degrees, thanks to the 32 muscles that they use to control their ear movements.\",\n    \"category\": \"Behavior\"\n  }\n]\n```\n\nI hope you enjoyed these fascinating insights into the world of cats! Whether it's their remarkable night vision, unique terminology, or impressive ear flexibility, there's always something new to learn about these incredible creatures."
    expected_response_clean = %([\n  {\n    \"fact\": \"Cats have a special reflective layer behind their retinas called the tapetum lucidum, which enhances their night vision.\",\n    \"category\": \"Anatomy\"\n  },\n  {\n    \"fact\": \"A group of cats is called a 'clowder,' and a group of kittens is known as a 'kindle.'\",\n    \"category\": \"Terminology\"\n  },\n  {\n    \"fact\": \"Cats can rotate their ears 180 degrees, thanks to the 32 muscles that they use to control their ear movements.\",\n    \"category\": \"Behavior\"\n  }\n])
    expected_objects = JSON.parse(expected_response_clean)

    vcr("OpenAI JSON noisy streaming request") do
      response_array = []
      response = openai_api.get_response(
        params: {
          model: "gpt-4o",
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

  def openai_api
    @openai_api ||= OpenAiApi.new(access_token: openai_api_token)
  end

end
