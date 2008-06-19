class CollaborativeFilter
  class ContentBooster
    attr_reader :genes
    attr_reader :booster
    
    def initialize
      @genes = {}
    end

    def booster(booster_class=nil)
      return @booster unless booster_class
      @booster = booster_class
    end

    def gene(name, &block)
      gene = Gene.new
      gene.finder = block
      @genes[name] = gene
    end

    def crossover(point=nil)
      return @crossover unless point
      @crossover = point
    end

    def threshold(input=nil)
      return @threshold unless input
      @threshold = input
    end

    def factor(input=nil)
      return @factor unless input
      @factor = input
    end


    def run(recommendations,datasets)
      options = { :crossover => @crossover, :threshold => @threshold, :factor => @factor }
      @booster.new.run(recommendations,datasets,@genes,options)
    end


    class Gene
      attr_accessor :finder
      def all(items)
        @finder[items]
      end
    end
  end
end

