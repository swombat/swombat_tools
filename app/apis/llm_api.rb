class LlmApi < GenericApi
  # Expected API:

  # Interface with whatever gem is required to get a response
  # @param params [Hash] Whatever is meant to be sent out to the API
  # @param stream_proc [Proc] A proc that will receive either an event stream or a preprocessed streaming response
  #     Leave nil if you don't want to stream
  # @param response_type [Symbol] Enables relevant preprocessing of the event stream. +:text+ for receiving
  #     +incremental_response+ and +delta+, +:json+ for receiving JSON objects one by one as they come in,
  #     and nil for no preprocessing.
  def get_response(params:, stream_proc:, stream_response_type:)
    raise NameError, "Forgot to implement the 'get_response' method in #{self.class.name}"
  end

  # Return all the models available to this API.
  def models
    raise NameError, "Forgot to implement the 'models' method in #{self.class.name}"
  end
end
