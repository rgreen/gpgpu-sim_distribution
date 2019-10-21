// Interface of a scheduler class to simplify the CTA scheduling logic in the
// simulator
// By: Nick from CoffeeBeforeArch

#include <vector>
#include "../abstract_hardware_model.h"
#include "gpu-sim.h"
#include "shader.h"

// Base CTA scheduler class
class CTAScheduler {
 protected:
  std::vector<simt_core_cluster *> clusters;
  kernel_info_t *kernel;
  unsigned last_cluster;
  unsigned ctas_scheduled;

 public:
  // Issues one CTA to an SM
  // Must be implemented by each scheduler
  virtual void issue_block2core() = 0;

  // Initialize the cluster array
  void set_cluster(simt_core_cluster *c[], int n_clusters);
};

// Implementation of Round-Robin scheduler class (default)
class RRScheduler : private CTAScheduler {
 private:
  // Friend classes
  friend class gpgpu_sim;

 public:
  // Constructor
  RRScheduler(gpgpu_sim *gpu);

  // Issue
  void issue_block2core();
};
