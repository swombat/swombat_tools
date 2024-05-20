
  def valid_class_names
    LlmApi.registered_subclasses
  end

  def models
    class_name.constantize.new(access_token: api_key).models
  end
