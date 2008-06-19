class CollaborativeFilter
  class Output
    class SqlAdapter
      CollaborativeFilter::Output.register :sql, self

      def initialize(options, recommendations)
        setup_mapping options[:mapping] || {}
        recommendations.each do |user_id, recs|
          next if recs.empty?
          ActiveRecord::Base.connection.execute \
            "INSERT INTO #{options[:table_name]} (#{@mapping_values.join(',')}) VALUES #{records_to_sql(user_id, recs)}"
        end
      end

      def setup_mapping(config_mapping)
        @mapping = { :user_id => :user_id, 
          :user_type => nil,
          :item_id => :item_id,
          :item_type => :item_type,
          :score => :score }
        @mapping.merge!(config_mapping)
        @mapping.each { |k,v| @mapping.delete(k) unless v }
        ma = @mapping.to_a
        @mapping_keys = ma.map(&:first)
        @mapping_values = ma.map(&:last)
      end

      def records_to_sql(user_id, recs)
        recs.map { |item_id, score|
          data = {}
          data[:user_id] = user_id
          data[:user_id], data[:user_type] = data[:user_id] if data[:user_id].is_a?(Array)
          data[:item_id] = item_id
          data[:item_id], data[:item_type] = data[:item_id] if data[:item_id].is_a?(Array)
          data[:score] = score

         '(' + @mapping_keys.map { |key| "'#{data[key]}'" }.join(',') + ')'
        }.join(',')
      end
    end
  end
end
