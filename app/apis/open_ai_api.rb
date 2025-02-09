require 'openai'

class OpenAiApi < LlmApi
  def initialize(access_token: "x")
    super()
    @access_token = access_token
    @client = OpenAI::Client.new(
      access_token: @access_token,
      request_timeout: 256,
      log_errors: true
      )
  end

  def models
    if @access_token == "x"
      @models = ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo", "o3-mini", "o1"]
    else
      @models ||= @client.models.list["data"]
        .select { |model| model["id"].starts_with?("gpt") || model["id"].include?("o1") || model["id"].include?("o3") }
        .sort_by { |model| model["created"] }.reverse
        .collect { |model| model["id"] }
    end
  end

  def get_response(params:, stream_proc: nil, stream_response_type: :text)
    params = params.transform_keys(&:to_sym)
    incremental_response = ""
    raise "Unsupported stream response type #{stream_response_type}" unless [:text, :json].include?(stream_response_type)
    response = {
      usage: {
        input_tokens: OpenAI.rough_token_count("#{params[:system]} #{params[:user]}"),
        output_tokens: 0,
      },
      id: nil
    }

    json_stack = ""

    parameters = {
      model: params[:model] || @model,
      messages: []
    }

    parameters[:temperature] ||= 0.7 unless params[:model].include?("o1")

    if stream_proc.present? && !params[:model].include?("o1")
      parameters[:stream] = proc do |chunk, _bytesize|
        response[:id] = chunk["id"] if response[:id].nil? && chunk["id"].present?
        delta = chunk.dig("choices", 0, "delta", "content")
        next if delta.nil?
        incremental_response += delta
        if stream_response_type == :text
          response[:usage][:output_tokens] += 1
          stream_proc.call(incremental_response, delta)
        elsif stream_response_type == :json
          json_stack.concat(delta)
          begin
            if json_stack.strip.include?("}")
              matches = json_stack.match(/\{(?:[^{}]|\g<0>)*\}/)
              stream_proc.call(JSON.parse(matches[0]))
              json_stack.clear
            end
          rescue StandardError => e
            log(e)
          ensure
            json_stack.clear if json_stack.strip.include?("}")
          end
        end
      end
    end

    parameters[:messages] << { role: "system", content: params[:system] } if params[:system]
    parameters[:messages] << { role: "user", content: params[:user] } if params[:user]

    parameters[:messages] = params[:messages] if params[:messages]

    if stream_proc.present? && !params[:model].include?("o1")
      @client.chat(parameters: parameters)
      response["choices"] = [ { "index": 0, "message": {
          "role": "assistant",
          "content": incremental_response
        },
        "finish_reason": "stop"} ]
      response = JSON.parse(response.to_json) # Get all keys to be strings
    elsif stream_proc.present? && params[:model].include?("o1")
      response = @client.chat(parameters: parameters)
      stream_proc.call(response["choices"][0]["message"]["content"], response["choices"][0]["message"]["content"])
      response
    else
      response = @client.chat(parameters: parameters)
    end

    # Adjust to match Claude response format
    response[:content] = [{ type: "text", text: response["choices"][0]["message"]["content"] }]

    JSON.parse(response.to_json)
  end

  def log(error)
    logger = Logger.new($stdout)
    logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "\033[31mOpenAI JSON Error (spotted in swombat_tools): #{msg}\n\033[0m"
    end
    logger.error(error)
  end

end

LlmApi.register(OpenAiApi)
