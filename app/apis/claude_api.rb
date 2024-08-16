require 'anthropic'
require 'json'

class ClaudeApi < LlmApi
  def initialize(access_token:)
    super()
    @access_token = access_token
    @client = Anthropic::Client.new(access_token: @access_token)
  end

  def models
    %w(claude-3-opus-20240229 claude-3-sonnet-20240229 claude-3-haiku-20240307 claude-3-5-sonnet-20240620)
  end

  # Expected in +params+:
  # - :user - user prompt
  # - :model
  # - :system (optional)
  # - :format (optional)
  # - :max_tokens (optional)
  def get_response(params:, stream_proc: nil, stream_response_type: nil)
    params = params.transform_keys(&:to_sym)
    parameters = {
      model: params[:model],
      temperature: 0.9,
      max_tokens: params[:max_tokens] || 4096,
      messages: []
    }

    params[:format] = params[:format].to_json if params[:format].present? && !params[:format].is_a?(String)

    parameters[:stream] = stream_proc if stream_proc.present?
    parameters[:preprocess_stream] = stream_response_type if stream_response_type.present?

    parameters[:messages] << { 'role': 'user', 'content': params[:user] } if params[:user]
    parameters[:messages] << { 'role': 'assistant', 'content': params[:format] } if params[:format].present?
    parameters[:system] = params[:system] if params[:system].present?

    response = @client.messages(parameters: parameters)

    # Adjust to match OpenAI response format
    response[:choices] = [ { index: 0, message: {
                                            role: "assistant",
                                            content: response[:content]
                                          } } ]
    response
  end
end

LlmApi.register(ClaudeApi)
