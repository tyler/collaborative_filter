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
  
  s.files = %W(README.textile LICENSE Rakefile) +
            Dir['{docs,bin,lib,spec,examples}/**/*']
end