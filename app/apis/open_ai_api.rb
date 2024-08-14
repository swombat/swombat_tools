require 'openai'

class OpenAiApi < LlmApi
  def initialize(access_token: "x")
    super()
    @access_token = access_token
    @client = OpenAI::Client.new(
      access_token: @access_token,
      request_timeout: 20
      )
  end

  def models
    if @access_token == "x"
      @models = ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"]
    else
      @models ||= @client.models.list["data"]
        .select { |model| model["id"].starts_with?("gpt") }
        .sort_by { |model| model["created"] }.reverse
        .collect { |model| model["id"] }
    end
  end

  def get_response(params:, stream_proc:, stream_response_type:)
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
      messages: [],
      temperature: params[:temperature] || 0.7,
      stream: proc do |chunk, _bytesize|
        response[:id] = chunk["id"] if response[:id].nil? && chunk["id"].present?
        if stream_response_type == :text
          delta = chunk.dig("choices", 0, "delta", "content")
          next if delta.nil?
          response[:usage][:output_tokens] += 1
          incremental_response += delta
          stream_proc.call(incremental_response, delta)
        elsif stream_response_type == :json
          json_stack.concat(chunk.dig("choices", 0, "delta", "content"))
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
    }

    parameters[:messages] << { role: "system", content: params[:system] } if params[:system]
    parameters[:messages] << { role: "user", content: params[:user] } if params[:user]

    parameters[:messages] = params[:messages] if params[:messages]

    @client.chat(parameters: parameters)

    # Fake it for now
    response[:choices] = [ { index: 0, message: {
                                            role: "assistant",
                                            content: incremental_response
                                          },
                              finish_reason: "stop"} ]

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
