# SimpleBooster - a content booster for CollaborativeFiltration
#
# The purpose of a content booster is to improve the purely collaborative output
# from a recommender. Collaborative filtration relies on the idea that if you
# have similar ratings/purchases as someone else in the past, you are likely to
# continue to in the future.  
#
# The fallacy of this is obvious when you consider that Bob may really enjoy 
# Superhero comics and Horror comics.  Joe really enjoys Superhero comics and 
# Humor comics.  Depending on how many things they rate and other factors, Joe 
# and Bob may still have a high correlation. However, Bob's love of Horror 
# comics may infiltrate Joe's ratings despite the fact that Joe really dislikes 
# them.
#
# So, a content booster allows us to nudge the value of your recommendations up
# or down. One strategy for using a content booster is to set the threshold on
# your recommender low (say... 2.5 or 3), but the threshold on the content
# booster high.
class CollaborativeFilter
  class SimpleBooster
    def run(recs,datasets,genes,options)
      @recs, @datasets, @genes, @options = recs, datasets, genes, options
      generate_profiles
    end

    def generate_profiles
      all_items = @datasets.inject([]) { |o,(dn,ds)| o.concat ds.items; o }.uniq
      gene_lists = @genes.map { |gn,gene| gene.all(all_items) }

      # Generating a profile for each user.
      # In essence ...
      # user_id => [ {'superhero' => -1, 'horror' => +2 },
      #              {'spiderman' => 2, 'atomic robo' => 1 } ]
      #
      # Iterate through each dataset, as we take all of them into account.
      CollaborativeFilter.log "  Generating user_profs: #{Time.now}"
      user_profs = @datasets.inject({}) { |profiles,(ds_name,ds)|
        CollaborativeFilter.log "   Starting new dataset: #{Time.now}"

        ds.users.each_with_index do |user_id,user_idx|
          profiles[user_id] ||= []

          # Grab the User's ratings from their column in the input matrix
          user_ratings = ds.m.col(user_idx).to_a
          user_ratings.each_index do |item_idx|

            # user_ratings is an array with an entry for each item for the user
            score = user_ratings[item_idx]

            next if score == 0

            # we have a master list of all items in all datasets which we need
            # for the profiles to span datasets.  Find this item's index in there.
            all_items_idx = all_items.index(ds.items[item_idx])

            # iterate through each gene type (genres, franchises, etc)
            gene_lists.each_index do |gene_type_idx|

              # find the value of the gene for this particular item (e.g. this item's genre is horror)
              # this value is always an array and can contain more than one value
              gis = gene_lists[gene_type_idx][all_items_idx]

              profiles[user_id][gene_type_idx] ||= {}

              adj = (score - @options[:crossover]) / gis.size

              gis.each do |gi|
                # we keep a tuple for each gene value (genre => horror) the first element
                # is the count of how many items we've noted and last is the total adjustment
                # they are later used to make an average
                profiles[user_id][gene_type_idx][gi] ||= [0,0]
                profiles[user_id][gene_type_idx][gi][0] += 1
                profiles[user_id][gene_type_idx][gi][1] += adj
              end
            end
          end
        end
        profiles
      }.to_a.map { |user_id,genes| 
        # Grab each of those tuples we made above ([count, total]) and turn each one into an
        # average multiplied by the 'factor' option.  Meaning...  If you rated Superman 2 points
        # above the crossover, and Spiderman 1 point above the threshold, we have a tuple that
        # looks like [2,3].  3 / 2 = 1.5.  Then we multiply by the factor (say 0.5) meaning we
        # only want to half weight on the factors.  So, on average you've rated Superheros 1.5
        # above the crossover, however, since our factor is 0.5, we're going to record 0.75 as
        # the modifier.  This limits the power of the content booster.
        #
        # The more genes you have the lower you'll want to set the factor, as each of them modify
        # the recommendations in turn.  I should probably change the factor to be configurable
        # per gene.
        [user_id, genes.map { |m| m.to_a.map { |gi,(qty,tot)| [gi, (tot/qty) * @options[:factor] ] } } ]
      }

      CollaborativeFilter.log "  Boosting recommendations: #{Time.now}"

      new_recs = []
      @recs.each_index do |user_idx|
        # Grab a user's raw recs and their profile which we generated above
        user_id, user_recs = @recs[user_idx]
        user_id, user_profile = user_profs[user_idx]

        # Iterate through each of the individual items in the recommendations
        new_user_recs = user_recs.map { |item_id, score| 


          user_profile.each_index do |gene_type_idx|
            # Grab this item's genes for this particular gene type from the master list
            item_gene = gene_lists[gene_type_idx][all_items.index(item_id)]

            # item_gene will always be an array, if it's empty we can move on
            next if item_gene.empty?

            # an item can have multiple genes for a gene type, we just use the average
            item_mod = item_gene.inject([0,0]) { |o,g| 

              # find the user's modifier for this gene
              mod = user_profile[gene_type_idx].detect { |ig| ig.first == g }
              next o unless mod
              [o[0] + mod.last, o[1] + 1]
            }
            # move on unless we have at least modifier
            next unless item_mod[1] > 0
            score += item_mod[0] / item_mod[1]
          end

          # if the score is at or above the threshold, add it to our new recs list
          next if score < @options[:threshold]
          [item_id, score > 5 ? 5 : score]
        }.compact
        new_recs << [user_id, new_user_recs]
      end

      new_recs
    end
  end
end

