class CollaborativeFilter

  def self.config
    @@config ||= Config.new
  end

  class Config
    def self.config_option(option, default=nil)
      @@config_defaults ||= {}
      @@config_defaults[option] = default

      define_method(:setup_defaults) {
        @@config_defaults.each { |k,v| instance_variable_set("@#{k}".to_sym, v) }
      } unless instance_methods.include?('setup_defaults')

      class_eval <<-END
        def #{option}(input=nil)
          return @#{option} unless input
          @#{option} = input
        end
      END
    end

    config_option :item_genes, []
    config_option :output, { :type => :yaml }
    attr_reader :datasets, :recommender_options

    def dataset(name)
      raise Error.new('#dataset requires a block') unless block_given?

      ds = CollaborativeFilter::DataSet.new
      yield ds
      @datasets[name] = ds
    end

    def content_booster
      return @content_booster unless block_given?

      cb = CollaborativeFilter::ContentBooster.new
      yield cb
      @content_booster = cb
    end

    def recommender(input=nil, options={})
      return @recommender unless input
      @recommender = input
      @recommender_options = options
    end

    def initialize
      setup_defaults
      @datasets = {}
    end

    class Error < StandardError; end
  end
end

