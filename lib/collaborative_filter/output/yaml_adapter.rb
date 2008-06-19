class CollaborativeFilter
  class Output
    class YamlAdapter
      CollaborativeFilter::Output.register :yaml, self

      def initialize(options, recommendations)
        require 'yaml'
        filename = options[:filename] || 'recommendations.yml'
        File.open(filename,'w') { |f| f << recommendations.to_yaml }
      end
    end
  end
end
