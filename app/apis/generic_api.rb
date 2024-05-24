class GenericApi

  @subclasses = []

  class << self
    attr_accessor :subclasses

    def register(*subclasses)
      @subclasses ||= []
      subclasses.each { |subclass| @subclasses << subclass.to_s }
    end

    # Register in `config/initializers/llm_api.rb`
    def registered_subclasses
      @subclasses || []
    end
  end

end
