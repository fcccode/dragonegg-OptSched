/*******************************************************************************
Description:  Defines a machine model class that abstracts machine description
              information to be used by an instruction scheduler. All properties
              of the machine model are read-only.
Author:       Ghassan Shobaki
Created:      Jun. 2002
Last Update:  Mar. 2011
*******************************************************************************/

#ifndef OPTSCHED_BASIC_MACHINE_MODEL_H
#define OPTSCHED_BASIC_MACHINE_MODEL_H

// For class ostream.
#include <iostream>
// For class string.
#include <string>
// For class vector.
#include <vector>
#include "llvm/CodeGen/OptSched/generic/defines.h"

namespace opt_sched {

using std::string;
using std::vector;

// The possible types of dependence between two machine instructions.
enum DependenceType {
  // A true data dependence (read after write).
  DEP_DATA,
  // A register anti-dependence (write after read).
  DEP_ANTI,
  // A register output-dependence (write after write).
  DEP_OUTPUT,
  // Any other ordering dependence.
  DEP_OTHER
};

// Instruction type. An index into the machine's instructions list.
typedef int16_t InstType;
// Machine issue type. An index into the machine's issue type list. All
// instructions of the same issue type use the same pipeline.
typedef int16_t IssueType;

// The code returned when the user tries to parse an unknown instruction type.
const InstType INVALID_INST_TYPE = -1;
// The code returned when the user tries to parse an unknown issue type.
const IssueType INVALID_ISSUE_TYPE = -1;
// The issue type for NOP instructions inserted by the scheduler.
const IssueType ISSU_STALL = -2;
// The maximum allowed number of issue types. Not used by the machine model
// code itself, but some of the legacy users of this class use it.
const int MAX_ISSUTYPE_CNT = 20;

// A read-only description of a machine.
class MachineModel {
  public:
    // Loads a machine model description from a file.
    MachineModel(const string& modelFile);
    // A no-op virtual destructor to allow proper subclassing.
    virtual ~MachineModel() {}

    // Returns the name of the machine model.
    const string& GetModelName() const;
    // Returns the number of instruction types.
    int GetInstTypeCnt() const;
    // Returns the number of issue types (pipelines).
    int GetIssueTypeCnt() const;
    // Returns the machine's issue rate. I.e. the total number of issue slots
    // for all issue types.
    // TODO(ghassan): Eliminate.
    int GetIssueRate() const;
    // Returns the maximum number of total issue slots per cycle, for all issue
    // types.
    int GetIssueSlotCnt() const;
    // Returns the number of register types.
    int16_t GetRegTypeCnt() const;
    // Returns the number of registers of a given type.
    int GetPhysRegCnt(int16_t regType) const;
    // Returns the name of a given register type.
    const string& GetRegTypeName(int16_t regType) const;
    // Returns the register type given its name.
    int16_t GetRegTypeByName(char const * const regTypeName) const;
    // Returns the number of issue slots for a given issue type.
    int GetSlotsPerCycle(IssueType type) const;
    // Returns the total number of issue slots and fills the passed array with
    // the number of issue slots for each issue type.
    int GetSlotsPerCycle(int slotsPerCycle[]) const;
    // Returns the latency of an instruction, given that the dependence on it is
    // of the specified type.
    int16_t GetLatency(InstType instTypeCode, DependenceType type) const;
    // Returns the name of a given instruction type.
    char const * GetInstTypeNameByCode(InstType instTypeCode) const;
    // Returns the name of a given issue type.
    char const * GetIssueTypeNameByCode(IssueType issueTypeCode) const;
    // Returns the issue type given its name.
    IssueType GetIssueTypeByName(char const * const issuTypeName) const;
    // Returns the issue type of a given instruction type.
    IssueType GetIssueType(InstType instTypeCode) const;
    // Returns the instruction type given the name of the instruction as well
    // as the name of the previous instruction (used for context-dependent
    // instructions).
    InstType GetInstTypeByName(const string& typeName,
                               const string& prevName = "") const;

    // Returns whether the given instruction is a branch.
    bool IsBranch(InstType instTypeCode) const;
    // Returns whether the given instruction is a call.
    bool IsCall(InstType instTypeCode) const;
    // Returns whether the given instruction is artifical. These are non-real
    // instructions that actually get scheduled, like "entry" and "exit".
    bool IsArtificial(InstType instTypeCode) const;
    // Returns whether an instruction type uses a float register.
    // TODO(max): Eliminate. This is a hack to generate virtual register
    // information for Sun compiler DAGs which do not have it.
    bool IsFloat(InstType instTypeCode) const;
    // Returns whether the given instruction is pipelined.
    bool IsPipelined(InstType instTypeCode) const;
    // Returns whether the given instruction blocks the cycle, such that no
    // other instructions can be scheduled in the same cycle.
    bool BlocksCycle(InstType instTypeCode) const;
    // Returns whether the given instruction is supported.
    bool IsSupported(InstType instTypeCode) const;
    // Returns whether the given instruction is real. Non-real instructions,
    // like entry, exit and JOIN on the Sun SPARC compiler, are used as markers
    // and are not actually issued by the CPU.
    bool IsRealInst(InstType instTypeCode) const;

  protected:
    // Creates an uninitialized machine model. For use by subclasses.
    MachineModel() {}

    // A description of an instruction type.
    struct InstTypeInfo {
      // The name of the instruction type.
      string name;
      // Whether instructions of this type can be scheduled only in a particular
      // context.
      bool isCntxtDep;
      // The issue type used by instructions of this type.
      IssueType issuType;
      // The latency of this instructions, i.e. the number of cycles this
      // instruction takes before instructions that depend on it (true
      // dependence) can be scheduled.
      int16_t ltncy;
      // Whether instructions of this type are pipelined.
      bool pipelined;
      // Whether instructions of this type are supported.
      bool sprtd;
      // Whether instructions of this type block the cycle, such that no other
      // instructions can be scheduled in the same cycle.
      bool blksCycle;
    };

    // A description of a register type.
    struct RegTypeInfo {
      // The name of the register.
      string name;
      // How many register of this type the machine has.
      int count;
    };

    // A description of a register type.
    struct IssueTypeInfo {
      // The name of the issue type.
      string name;
      // How many slots of this issue type the machine has per cycle.
      int slotsCount;
    };

    // The name of the machine model.
    string mdlName_;
    // The machine's issue rate. I.e. the total number of issue slots for all
    // issue types.
    // TODO(ghassan): Eliminate.
    int issueRate_;
    // The maximum number of total issue slots per cycle, for all issue types.
    int issueSlotCnt_;
    // The latencies for different dependence types.
    int16_t dependenceLatencies_[4];

    // A vector of instruction type descriptions.
    vector<InstTypeInfo> instTypes_;
    // A vector of register types with their names and counts.
    vector<RegTypeInfo> registerTypes_;
    // A vector of issue types with their names and slot counts.
    vector<IssueTypeInfo> issueTypes_;
};

} // end namespace opt_sched

#endif