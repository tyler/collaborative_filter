Gem::Specification.new do |s|
  s.name = "collaborative_filter"
  s.version = '0.5.0'
  s.platform = Gem::Platform::RUBY
  s.author = "Tyler McMullen"
  s.email = "tbmcmullen@gmail.com"
  s.homepage = "http://github.com/tyler/collaborative_filter"
  s.summary = "A Collaborative Filtering framework in Ruby."
  s.description = s.summary
  s.require_path = "lib"
  
  s.files = %W(README.textile
               LICENSE
               Rakefile
               lib/boosters/simple_booster.rb
               lib/collaborative_filter/config.rb
               lib/collaborative_filter/content_booster.rb
               lib/collaborative_filter/data_set.rb
               lib/collaborative_filter/output
               lib/collaborative_filter/output/mysql_adapter.rb
               lib/collaborative_filter/output/yaml_adapter.rb
               lib/collaborative_filter/output.rb
               lib/collaborative_filter.rb
               lib/correlators/simple_svd.rb
               lib/recommenders/simplest_recommender.rb)
end
