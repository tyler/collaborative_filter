# A correlator helps us find users who are similar to each other.  There are
# a crapton of ways to accomplish this.  In this case we're using a 
# singular-value-decomposition algorithm.  In essence, we decompose the matrix
# of user-item nodes (where nodes are rating, purchases, etc) into two matrices
# U and V, and their singular values S.  We take the first two columns of
# V-transpose and plot them in 2-dimensional space as if the corresponding
# entries in the columns were X and Y coordinates.  This will clump the users
# into groups.  A simple, and moderately accurate, way to find those groups
# is to find the cosine similarities of the different users.
#
# So the correlator takes a sparse matrix, a users array, an items array, and
# options.  It outputs a hash that looks like...
#
# { user_id => [[cos_sim, sim_user_1], [cos_sim, sim_user_2], ...] }
class CollaborativeFilter
  class SimpleSvd
    def run(matrix,users,items,options)
      qty = 0

      u,v,s = matrix.svd

      # we use the transpose of the V matrix
      xs,ys = [v.transpose.col(0).to_a, v.transpose.col(1).to_a]

      # precompute some of the terms from the cos. sim function. thanks pete!
      precomputes = []
      xs.each_index { |i| precomputes << Math.sqrt((xs[i] * xs[i]) + (ys[i] * ys[i])) }

      similar_users = {}
      # compute the similarities between each user and each other user currently this is O(n^2)... 
      # there is one major improvement that could be made to it... which is to cache the results
      xs.each_index do |user_idx|
        x1, y1 = xs[user_idx], ys[user_idx]
        sims = []
        xs.each_index do |target_idx|
          next if user_idx == target_idx
          x2, y2 = xs[target_idx], ys[target_idx]

          # compute the cosine similarity between user and target
          sim = ((x1 * x2) + (y1 * y2)) / (precomputes[user_idx] * precomputes[target_idx])

          sims << [target_idx, sim] if sim >= options[:cosine_similarity] 
        end

        x = sims.sort_by(&:last).reverse[0, (options[:max_similar_users] || sims.size)]
        qty += x.size
        similar_users[user_idx] = x
      end

      CollaborativeFilter.log "    Average sims per user: #{qty.to_f / similar_users.size}"
      similar_users
    end
  end
end

