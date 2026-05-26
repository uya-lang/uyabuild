#include <cstdio>

#include "lib.h"

int main() {
  if (answer() != 42) {
    std::fprintf(stderr, "smoke test failed\n");
    return 1;
  }
  std::printf("smoke test passed\n");
  return 0;
}
