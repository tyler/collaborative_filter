class CollaborativeFilter
  class Output
    def self.store(options, recommendations)
      @@adapters[options[:type]].new(options[:options], recommendations)
    end

    def self.register(name, class_name)
      @@adapters ||= {}
      @@adapters[name] = class_name
    end
  end
end

