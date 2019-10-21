// Implementation of a scheduler class to simplify the CTA scheduling logic in
// the simulator
// By: Nick from CoffeeBeforeArch

#include "scheduler.h"

void CTAScheduler::set_cluster(simt_core_cluster *c[], int n_clusters){
  // Load the pointers into our vector
  clusters.reserve(n_clusters);
  for(int i = 0; i < n_clusters; i++){
    clusters.push_back(c[i]);
  }
}

// Constructor for RRScheduler
RRScheduler::RRScheduler(gpgpu_sim *gpu){
  // Set the cluster pointers
  set_cluster(gpu->getSIMTCluster(), gpu->getNClusters());

  // Init remaining vars to 0
  last_cluster = 0;
  ctas_scheduled = 0;
}

// Go to all SIMT Clusters and calls issue_block2core()
void RRScheduler::issue_block2core() {
  // Go over all clusters
  for (auto i = 0u; i < clusters.size(); i++ ) {
    // Wrapping increment
    auto idx = (i + last_cluster + 1) % clusters.size();
    auto scheduled = clusters[idx]->issue_block2core();
    
    // If we scheduled to this cluster, update our last issue var
    if (scheduled) {
      last_cluster = idx;
      ctas_scheduled += scheduled;
    }
  }
}
