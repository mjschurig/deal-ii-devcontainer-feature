cmake_minimum_required(VERSION 3.10)
project(deal_ii_test)

# Find deal.II
find_package(deal.II REQUIRED HINTS ${DEAL_II_DIR})
deal_ii_initialize_cached_variables()

# Create executable
add_executable(deal_ii_test main.cpp)

# Setup deal.II for the target
deal_ii_setup_target(deal_ii_test) 