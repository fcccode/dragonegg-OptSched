
add_llvm_library(LLVMOptSched
  OptScheduler.cpp
  aco.cpp
  bb_spill.cpp
  OptSchedMachineWrapper.cpp
  buffers.cpp
  config.cpp
  data_dep.cpp
  enumerator.cpp
  gen_sched.cpp
  graph.cpp
  graph_trans.cpp
  hist_table.cpp
  list_sched.cpp
  logger.cpp
  reg_alloc.cpp
  utilities.cpp
  machine_model.cpp
  OptSchedDagWrapper.cpp
  random.cpp
  ready_list.cpp
  register.cpp
  relaxed_sched.cpp
  sched_basic_data.cpp
  sched_region.cpp
  stats.cpp
  )

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -DIS_DEBUG")

add_dependencies(LLVMOptSched intrinsics_gen)
