require_relative "../test_helper"

class OpenRouterApiTest < ActiveSupport::TestCase
  test "should be able to make a simple request from Llama3Api" do
    request = "Hi there! Please tell me something nice as a greeting."
    expected_response = "You deserve a warm welcome! Here it is: You are amazing just the way you are, and I'm so glad you're here! I hope your day is filled with joy, laughter, and all your favorite things. How can I make your day even brighter?"

    vcr("OpenRouter Meta Llama3 simple request") do
      response = openrouter_api.get_response(
        params: {
          model: "meta-llama/llama-3.1-405b-instruct",
          user: request,
        }
      )
      assert response["content"].present?
      puts "Unexpected response: #{response.inspect}" if response["content"][0]["text"] != expected_response
      assert_equal expected_response, response["content"][0]["text"]
    end
    assert true
  end

  test "should be able to make a streaming request from Llama3Api" do
    request = "Hi there! Please tell me something nice as a greeting."
    expected_response = "Hello! It's wonderful to meet you! You know what's amazing? You're a unique and special person, and the world is a little bit brighter just because you're in it. I'm so glad we get to chat and share some kindness together. How's your day going so far?"

    vcr("OpenRouter Meta Llama3 streaming request") do
      streamed_response = ""
      response = openrouter_api.get_response(
        params: {
          model: "meta-llama/llama-3.1-405b-instruct",
          user: request,
        },
        stream_proc: Proc.new { |incremental_response, delta| streamed_response += delta },
        stream_response_type: :text
      )
      assert response["content"].present?
      puts "Unexpected response: #{response.inspect}" if streamed_response != expected_response
      assert_equal expected_response, streamed_response
      assert_equal expected_response, response["content"][0]["text"]
    end
  end

  test "should be able to make a streaming json request from Llama3Api" do
    request = "Hi there! Please give me three fun and interesting facts about cats. Respond ONLY with a JSON array, without any additional text or explanation. Each object in the array should have 'fact' and 'category' keys."
    # format = "[{\"category\":\"age\",\"fact\":\"Cats are usually between 1-15 years old.\"}, ... ]"
    expected_response = %([\n  {\n    \"fact\": \"Cats have a unique nose print, just like human fingerprints.\",\n    \"category\": \"Behavior\"\n  },\n  {\n    \"fact\": \"Cats can't taste sweetness.\",\n    \"category\": \"Physiology\"\n  },\n  {\n    \"fact\": \"Cats spend up to 1/3 of their waking hours grooming themselves.\",\n    \"category\": \"Behavior\"\n  }\n])
    expected_objects = JSON.parse(expected_response)

    vcr("OpenRouter Meta Llama3 JSON streaming request") do
      response_array = []
      response = openrouter_api.get_response(
        params: {
          model: "meta-llama/llama-3.1-8b-instruct",
          user: request
        },
        stream_proc: Proc.new { |json_object| response_array << json_object },
        stream_response_type: :json
      )
      assert response["content"].present?
      puts "Unexpected response: #{response.inspect}" if expected_response != response["content"][0]["text"]
      assert_equal expected_response, response["content"][0]["text"]
      expected_objects.each do |expected_object|
        assert_includes response_array, expected_object
      end
    end
  end

  test "should be able to make a streaming json request from Llama3Api which deals with text around the JSON array" do
    request = "Hi there! Please give me three fun and interesting facts about cats. Respond with a JSON array, along with a preamble and conclusion. Each object in the array should have 'fact' and 'category' keys."
    # format = "[{\"category\":\"age\",\"fact\":\"Cats are usually between 1-15 years old.\"}, ... ]"
    expected_response = "A cat lover, eh? Well, you've come to the right place! Here are three fun and interesting facts about our feline friends:\n\n```json\n[\n  {\n    \"fact\": \"Cats have scent glands on their faces, near their whiskers, and on their paws. They use these glands to mark their territory and communicate with other cats.\",\n    \"category\": \"Biology\"\n  },\n  {\n    \"fact\": \"The ancient Egyptians worshipped a cat goddess named Bastet, who was often depicted as a woman with the head of a cat. They believed that cats were sacred animals and would often mummify them to ensure their safe passage into the afterlife.\",\n    \"category\": \"History\"\n  },\n  {\n    \"fact\": \"Cats have unique nose prints, just like human fingerprints. No two cats have the same nose print, making each one a unique snowflake... er, cat!\",\n    \"category\": \"Biology\"\n  }\n]\n```\n\nThere you have it - three fun facts about cats that showcase their fascinating biology and rich history. Whether you're a seasoned cat owner or just a cat enthusiast, there's always more to learn about these amazing creatures!"
    expected_response_clean = %([\n  {\n    \"fact\": \"Cats have scent glands on their faces, near their whiskers, and on their paws. They use these glands to mark their territory and communicate with other cats.\",\n    \"category\": \"Biology\"\n  },\n  {\n    \"fact\": \"The ancient Egyptians worshipped a cat goddess named Bastet, who was often depicted as a woman with the head of a cat. They believed that cats were sacred animals and would often mummify them to ensure their safe passage into the afterlife.\",\n    \"category\": \"History\"\n  },\n  {\n    \"fact\": \"Cats have unique nose prints, just like human fingerprints. No two cats have the same nose print, making each one a unique snowflake... er, cat!\",\n    \"category\": \"Biology\"\n  }\n])
    expected_objects = JSON.parse(expected_response_clean)

    vcr("OpenRouter Meta Llama3 JSON noisy streaming request") do
      response_array = []
      response = openrouter_api.get_response(
        params: {
          model: "meta-llama/llama-3.1-405b-instruct",
          user: request
        },
        stream_proc: Proc.new { |json_object| response_array << json_object },
        stream_response_type: :json
      )
      assert response["content"].present?
      puts "Unexpected response: #{response.inspect}" if expected_response != response["content"][0]["text"]
      expected_objects.each do |expected_object|
        assert_includes response_array, expected_object
      end
      assert_equal expected_response, response["content"][0]["text"]
    end
  end

  def openrouter_api
    @openrouter_api ||= OpenRouterApi.new(access_token: openrouter_api_token)
  end

end
