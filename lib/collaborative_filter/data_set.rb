class CollaborativeFilter
  class DataSet
    attr_accessor :users
    attr_accessor :items
    attr_accessor :m
    attr_accessor :similarities

    def users(input=nil)
      return @users unless input

      raise Error.new("all users must be unique") if input.size != input.uniq.size
      raise Error.new("must have at least two users") if input.size < 2

      if input.map(&:class).uniq.size == 1
        @users = input.map(&:id)
      else
        @users = input.map { |u| [u.id,u.class.to_s] }
      end
    end

    def items(input=nil)
      return @items unless input

      raise Error.new("all items must be unique") if input.size != input.uniq.size
      raise Error.new("must have at least two items") if input.size < 2

      if input.map(&:class).uniq.size == 1
        @items = input.map(&:id)
      else
        @items = input.map { |i| [i.id,i.class.to_s] }
      end
    end

    def nodes(input=nil)
      if block_given?
        @m = GSL::Matrix[@items.size,@users.size]
        yield @m
      else
        @m = input.is_a?(GSL::Matrix) ? input : GSL::Matrix[*input]
      end
    end

    def options(opts=nil)
      return @options unless opts
      @options = opts
    end

    def correlator(input=nil)
      return @correlator unless input
      @correlator = input
    end



    def item_index(id,type=nil)
      find_index(id,type,@items)
    end

    def user_index(id,type=nil)
      find_index(id,type,@users)
    end

    def run
      @similarities = @correlator.new.run(@m, @users, @items, @options)
    end
    
    private

    def find_index(id,type,collection)
      collection.index(type ? [id,type] : id)
    end

    class Error < StandardError; end
  end
end
