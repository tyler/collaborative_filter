class CollaborativeFilter
  # Given any number of similarity hashes of a particular form recommend Items
  # for Users. Weights according to cosine similarity of the recommendation and
  # the cosine similarity threshold. 
  #
  # Example:
  #   Threshold is set to 0.9.  This particular recommendation is 0.95.
  #   1.0 - 0.9 = 0.1
  #   0.95 - 0.9 = 0.5
  #   0.5 / 0.1 = 0.5 = 50%
  #   So the 0.95 rec would be worth 50%.
  #
  # The purpose of this of course, is for the case when you are similar to multiple
  # users who have rated a certain item differently.  If you are highly correlated to
  # Bob, and slightly correlated to Joe... and Bob rated X as 5 stars, and Joe rated 
  # X as 2 stars... Bob's rating should carry more weight in determining your
  # recommendation.
  #
  # Sim hashes look like: { (user_identifier) => [[(closeness),(user_identifier)], ...] }
  #
  # Input:
  #   Array of DataSet objects, with #similarities populated
  #
  # Output:
  #   Array in the form:
  #     [ [ (user id), [ [ (item id), (score) ], ... ] ], ... ]
  class SimplestRecommender
    def run(datasets, options)
      options[:threshold] ||= 4.2

      datasets.inject({}) { |ratings,(name,ds)| 
        mult = 1.0 - ds.options[:cosine_similarity]
        ds.similarities.each do |user_idx,sim_list|
          ratings[ds.users[user_idx]] ||= {}
          blacklist = generate_blacklist(user_idx,ds)
          sim_list.each do |sim_idx,similarity|
            # grab the list of the similar users' item ratings
            ds.m.col(sim_idx).to_a.each_with_index do |score,item_idx|
              next if score == 0 || blacklist.include?(item_idx)

              # need to use the item_id instead of idx so the content booster can find
              # its own index of it.
              item_id = ds.items[item_idx]

              ratings[ds.users[user_idx]][item_id] ||= []
              ratings[ds.users[user_idx]][item_id] << [score, (similarity - ds.options[:cosine_similarity]) * mult]
            end
          end
        end
        ratings
      }.map { |c,rlists|
        averaged_ratings = rlists.map { |i,rs| 
          score_sum, sim_sum = rs.inject([0,0]) { |sums,(score,similarity)| [sums.first + score, sums.last + similarity] }
          [i, score_sum / sim_sum] 
        }.select { |k,v| 
          v >= options[:threshold]
        }.sort { |(k1,v1),(k2,v2)| v2 <=> v1 }[0,options[:max_per_user]]
        [c, averaged_ratings]
      }
    end

    def generate_blacklist(user_idx,ds)
      blacklist = []
      ratings = ds.m.col(user_idx).to_a
      ds.items.each_index { |idx| blacklist << idx if ratings[idx] != 0 }
      blacklist
    end

    # We don't want to recommend things that people have already rated, purchased, or subscribed to.
    # Not used at the moment
    def generate_blacklists(ds)
      blacklists = []
      ds.users.each_with_index do |user_id, user_idx|
        blacklist = []
        ds.m.col(user_idx).to_a.each_with_index { |r,i| blacklist << ds.items[i] if r == 0 }

        #user = Customer.find(user_id)

        #user.subscription_list && 
        #  user.subscription_list.subscriptions.each { |sub| blacklist << [sub.subscribable_id, sub.subscribable_type] }

        #user.orders.map(&:line_items).flatten.each do |li|
        #  blacklist << [li.product_id, li.product_type]
        #  blacklist << [li.product.title_id, 'Title'] if li.product.respond_to?(:title)
        #end
        blacklists << blacklist
      end
      blacklists
    end
  end
end

