// Implementation of a scheduler class to simplify the CTA scheduling logic in
// the simulator
// By: Nick from CoffeeBeforeArch

#include "scheduler.h"

RRScheduler::RRScheduler() { 
  kernel = nullptr;
  last_sm = 0;
}
