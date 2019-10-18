// Interface of a scheduler class to simplify the CTA scheduling logic in the
// simulator
// By: Nick from CoffeeBeforeArch

#include "../abstract_hardware_model.h"
#include "gpgpu-sim.h"
#include "shader.h"

// Base CTA scheduler class
class CTAScheduler {
 private:
  kernel_info_t *kernel;
  unsigned last_sm;
};

// Implementation of Round-Robin scheduler class (default)
class RRScheduler : private CTAScheduler {

};
