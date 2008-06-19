require 'gsl'
require 'collaborative_filter/data_set'
require 'collaborative_filter/config'
require 'collaborative_filter/content_booster'
require 'collaborative_filter/output'
require 'collaborative_filter/output/mysql_adapter'
require 'collaborative_filter/output/yaml_adapter'
require 'correlators/simple_svd'
require 'recommenders/simplest_recommender'
require 'boosters/simple_booster'

class CollaborativeFilter
  def self.filter(options={})
    @@logger = options[:logger]

    log "Starting configuration: #{Time.now}"
    raise '#setup must be sent a block' unless block_given?

    yield config

    log "Starting correlations: #{Time.now}"
    config.datasets.each do |name,ds|
      log "  Correlating '#{name}': #{Time.now}"
      ds.run
    end
    log "Starting recommender: #{Time.now}"
    recommendations = config.recommender.new.run(config.datasets, config.recommender_options)

    log "Starting booster: #{Time.now}"
    recommendations = config.content_booster.run(recommendations, config.datasets)

    log "Output: #{Time.now}"
    Output.store config.output, recommendations

    log "Done: #{Time.now}"
  end

  def self.log(msg)
    @@logger.info msg
  end
end


