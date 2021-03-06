//=- SystemZScheduleZEC12.td - SystemZ Scheduling Definitions --*- tblgen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the machine model for ZEC12 to support instruction
// scheduling and other instruction cost heuristics.
//
//===----------------------------------------------------------------------===//

def ZEC12Model : SchedMachineModel {

    let UnsupportedFeatures = Arch10UnsupportedFeatures.List;
    
    let IssueWidth = 3;             // 3 instructions decoded per cycle.
    let MicroOpBufferSize = 40;     // Issue queues
    let LoadLatency = 1;            // Optimistic load latency.

    let PostRAScheduler = 1;

    // Extra cycles for a mispredicted branch.
    let MispredictPenalty  = 8;
}

let SchedModel = ZEC12Model in  {

// These definitions could be put in a subtarget common include file,
// but it seems the include system in Tablegen currently rejects
// multiple includes of same file.
def : WriteRes<GroupAlone, []> {
  let NumMicroOps = 0;
  let BeginGroup  = 1;
  let EndGroup    = 1;
}
def : WriteRes<EndGroup, []> {
  let NumMicroOps = 0;
  let EndGroup    = 1;
}
def : WriteRes<Lat2, []> { let Latency = 2; let NumMicroOps = 0;}
def : WriteRes<Lat3, []> { let Latency = 3; let NumMicroOps = 0;}
def : WriteRes<Lat4, []> { let Latency = 4; let NumMicroOps = 0;}
def : WriteRes<Lat5, []> { let Latency = 5; let NumMicroOps = 0;}
def : WriteRes<Lat6, []> { let Latency = 6; let NumMicroOps = 0;}
def : WriteRes<Lat7, []> { let Latency = 7; let NumMicroOps = 0;}
def : WriteRes<Lat8, []> { let Latency = 8; let NumMicroOps = 0;}
def : WriteRes<Lat9, []> { let Latency = 9; let NumMicroOps = 0;}
def : WriteRes<Lat10, []> { let Latency = 10; let NumMicroOps = 0;}
def : WriteRes<Lat11, []> { let Latency = 11; let NumMicroOps = 0;}
def : WriteRes<Lat12, []> { let Latency = 12; let NumMicroOps = 0;}
def : WriteRes<Lat15, []> { let Latency = 15; let NumMicroOps = 0;}
def : WriteRes<Lat20, []> { let Latency = 20; let NumMicroOps = 0;}
def : WriteRes<Lat30, []> { let Latency = 30; let NumMicroOps = 0;}

// Execution units.
def ZEC12_VBUnit : ProcResource<1>;
def ZEC12_FXUnit : ProcResource<1>;
def ZEC12_LSUnit : ProcResource<1>;
def ZEC12_FPUnit : ProcResource<1>;

// Subtarget specific definitions of scheduling resources.
def : WriteRes<FXU,      [ZEC12_FXUnit]> { let Latency = 1; }
def : WriteRes<LSU,      [ZEC12_LSUnit]> { let Latency = 4; }
def : WriteRes<LSU_lat1, [ZEC12_LSUnit]> { let Latency = 1; }
def : WriteRes<FPU,  [ZEC12_FPUnit]> { let Latency = 8; }
def : WriteRes<VBU,  [ZEC12_VBUnit]>; // Virtual Branching Unit

// -------------------------- INSTRUCTIONS ---------------------------------- //

// InstRW constructs have been used in order to preserve the
// readability of the InstrInfo files.

// For each instruction, as matched by a regexp, provide a list of
// resources that it needs. These will be combined into a SchedClass.

//===----------------------------------------------------------------------===//
// Stack allocation
//===----------------------------------------------------------------------===//

def : InstRW<[FXU], (instregex "ADJDYNALLOC$")>; // Pseudo -> LA / LAY

//===----------------------------------------------------------------------===//
// Control flow instructions
//===----------------------------------------------------------------------===//

// Return
def : InstRW<[LSU_lat1, EndGroup], (instregex "Return$")>;
def : InstRW<[LSU_lat1], (instregex "CondReturn$")>;

// Compare and branch
def : InstRW<[FXU], (instregex "(Asm.*)?C(I|R)J$")>;
def : InstRW<[FXU], (instregex "(Asm.*)?CG(I|R)J$")>;
def : InstRW<[FXU], (instregex "(Asm.*)?CL(I|R)J$")>;
def : InstRW<[FXU], (instregex "(Asm.*)?CLG(I|R)J$")>;
def : InstRW<[FXU], (instregex "(Asm.*)?CG(R|I)J$")>;
def : InstRW<[FXU], (instregex "CLR$")>;
def : InstRW<[FXU, LSU, Lat5, GroupAlone], (instregex "(Asm.*)?CIB(Call|Return)?$")>;
def : InstRW<[FXU, LSU, Lat5, GroupAlone], (instregex "(Asm.*)?CLIB(Call|Return)?$")>;
def : InstRW<[FXU, LSU, Lat5, GroupAlone], (instregex "(Asm.*)?CLGIB(Call|Return)?$")>;
def : InstRW<[FXU, LSU, Lat5, GroupAlone], (instregex "(Asm.*)?CGIB(Call|Return)?$")>;
def : InstRW<[FXU, LSU, Lat5, GroupAlone], (instregex "(Asm.*)?CGRB(Call|Return)?$")>;
def : InstRW<[FXU, LSU, Lat5, GroupAlone], (instregex "(Asm.*)?CLGRB(Call|Return)?$")>;
def : InstRW<[FXU, LSU, Lat5, GroupAlone], (instregex "CLR(Call|Return)?$")>;
def : InstRW<[FXU, LSU, Lat5, GroupAlone], (instregex "(Asm.*)?CLRB(Call|Return)?$")>;
def : InstRW<[FXU, LSU, Lat5, GroupAlone], (instregex "(Asm.*)?CRB(Call|Return)?$")>;

// Branch
def : InstRW<[LSU, Lat4], (instregex "(Asm.*)?BR$")>;
def : InstRW<[LSU, Lat4], (instregex "(Asm)?BC(R)?$")>;
def : InstRW<[VBU], (instregex "(Asm)?BRC(L)?$")>;
def : InstRW<[FXU, EndGroup], (instregex "BRCT(G)?$")>;
def : InstRW<[VBU], (instregex "(Asm.*)?JG$")>;
def : InstRW<[VBU], (instregex "J$")>;
// (Need to avoid conflict with "(Asm.*)?CG(I|R)J$")
def : InstRW<[VBU], (instregex "Asm(EAlt|E|HAlt|HE|H|LAlt|LE|LH|L|NEAlt|NE)J$")>;
def : InstRW<[VBU], (instregex "Asm(NHAlt|NHE|NH|NLAlt|NLE|NLH|NL|NO|O)J$")>;
def : InstRW<[FXU, FXU, FXU, LSU, Lat7, GroupAlone], (instregex "BRX(H|LE)$")>;

// Trap
def : InstRW<[VBU], (instregex "(Cond)?Trap$")>;

// Compare and trap
def : InstRW<[FXU], (instregex "(Asm.*)?C(G)?IT$")>;
def : InstRW<[FXU], (instregex "(Asm.*)?C(G)?RT$")>;
def : InstRW<[FXU], (instregex "(Asm.*)?CLG(I|R)T$")>;
def : InstRW<[FXU], (instregex "(Asm.*)?CLFIT$")>;
def : InstRW<[FXU], (instregex "(Asm.*)?CLRT$")>;

//===----------------------------------------------------------------------===//
// Select instructions
//===----------------------------------------------------------------------===//

// Select pseudo 
def : InstRW<[FXU], (instregex "Select(32|64|32Mux)$")>;

// CondStore pseudos
def : InstRW<[FXU], (instregex "CondStore16(Inv)?$")>;
def : InstRW<[FXU], (instregex "CondStore16Mux(Inv)?$")>;
def : InstRW<[FXU], (instregex "CondStore32(Inv)?$")>;
def : InstRW<[FXU], (instregex "CondStore64(Inv)?$")>;
def : InstRW<[FXU], (instregex "CondStore8(Inv)?$")>;
def : InstRW<[FXU], (instregex "CondStore8Mux(Inv)?$")>;

//===----------------------------------------------------------------------===//
// Call instructions
//===----------------------------------------------------------------------===//

def : InstRW<[VBU, FXU, FXU, Lat3, GroupAlone], (instregex "BRAS$")>;
def : InstRW<[FXU, FXU, LSU, Lat6, GroupAlone], (instregex "(Call)?BASR$")>;
def : InstRW<[LSU, Lat4], (instregex "CallB(C)?R$")>;
def : InstRW<[FXU, FXU, LSU, Lat6, GroupAlone], (instregex "(Call)?BRASL$")>;
def : InstRW<[FXU, FXU, LSU, Lat6, GroupAlone], (instregex "TLS_(G|L)DCALL$")>;
def : InstRW<[VBU], (instregex "CallBRCL$")>;
def : InstRW<[VBU], (instregex "CallJG$")>;

//===----------------------------------------------------------------------===//
// Move instructions
//===----------------------------------------------------------------------===//

// Moves
def : InstRW<[FXU, LSU, Lat5], (instregex "MV(G|H)?HI$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "MVI(Y)?$")>;

// Move character
def : InstRW<[LSU, LSU, LSU, FXU, Lat8, GroupAlone], (instregex "MVC$")>;

// Pseudo -> reg move
def : InstRW<[FXU], (instregex "COPY(_TO_REGCLASS)?$")>;
def : InstRW<[FXU], (instregex "EXTRACT_SUBREG$")>;
def : InstRW<[FXU], (instregex "INSERT_SUBREG$")>;
def : InstRW<[FXU], (instregex "REG_SEQUENCE$")>;
def : InstRW<[FXU], (instregex "SUBREG_TO_REG$")>;

// Loads
def : InstRW<[LSU], (instregex "L(Y|FH|RL|Mux)?$")>;
def : InstRW<[LSU], (instregex "LG(RL)?$")>;
def : InstRW<[LSU], (instregex "L128$")>;

def : InstRW<[FXU], (instregex "LLIH(F|H|L)$")>;
def : InstRW<[FXU], (instregex "LLIL(F|H|L)$")>;

def : InstRW<[FXU], (instregex "LG(F|H)I$")>;
def : InstRW<[FXU], (instregex "LHI(Mux)?$")>;
def : InstRW<[FXU], (instregex "LR(Mux)?$")>;

// Load and test
def : InstRW<[FXU, LSU, Lat5], (instregex "LT(G)?$")>;
def : InstRW<[FXU], (instregex "LT(G)?R$")>;

// Load on condition
def : InstRW<[FXU, LSU, Lat6], (instregex "(Asm.*)?LOC(G)?$")>;
def : InstRW<[FXU, Lat2], (instregex "(Asm.*)?LOC(G)?R$")>;

// Stores
def : InstRW<[FXU, LSU, Lat5], (instregex "STG(RL)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "ST128$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "ST(Y|FH|RL|Mux)?$")>;

// Store on condition
def : InstRW<[FXU, LSU, Lat5], (instregex "(Asm.*)?STOC(G)?$")>;

// String moves.
def : InstRW<[LSU, Lat30, GroupAlone], (instregex "MVST$")>;

//===----------------------------------------------------------------------===//
// Sign extensions
//===----------------------------------------------------------------------===//

def : InstRW<[FXU], (instregex "L(B|H|G)R$")>;
def : InstRW<[FXU], (instregex "LG(B|H|F)R$")>;

def : InstRW<[FXU, LSU, Lat5], (instregex "LTGF$")>;
def : InstRW<[FXU], (instregex "LTGFR$")>;

def : InstRW<[FXU, LSU, Lat5], (instregex "LB(H|Mux)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LH(Y)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LH(H|Mux|RL)$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LG(B|H|F)$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LG(H|F)RL$")>;

//===----------------------------------------------------------------------===//
// Zero extensions
//===----------------------------------------------------------------------===//

def : InstRW<[FXU], (instregex "LLCR(Mux)?$")>;
def : InstRW<[FXU], (instregex "LLHR(Mux)?$")>;
def : InstRW<[FXU], (instregex "LLG(C|H|F)R$")>;
def : InstRW<[LSU], (instregex "LLC(Mux)?$")>;
def : InstRW<[LSU], (instregex "LLH(Mux)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LL(C|H)H$")>;
def : InstRW<[LSU], (instregex "LLHRL$")>;
def : InstRW<[LSU], (instregex "LLG(C|H|F|HRL|FRL)$")>;

//===----------------------------------------------------------------------===//
// Truncations
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat5], (instregex "STC(H|Y|Mux)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "STH(H|Y|RL|Mux)?$")>;

//===----------------------------------------------------------------------===//
// Multi-register moves
//===----------------------------------------------------------------------===//

// Load multiple (estimated average of 5 ops)
def : InstRW<[LSU, LSU, LSU, LSU, LSU, Lat10, GroupAlone],
             (instregex "LM(H|Y|G)?$")>;

// Store multiple (estimated average of 3 ops)
def : InstRW<[LSU, LSU, FXU, FXU, FXU, Lat10, GroupAlone],
             (instregex "STM(H|Y|G)?$")>;

//===----------------------------------------------------------------------===//
// Byte swaps
//===----------------------------------------------------------------------===//

def : InstRW<[FXU], (instregex "LRV(G)?R$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LRV(G|H)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "STRV(G|H)?$")>;

//===----------------------------------------------------------------------===//
// Load address instructions
//===----------------------------------------------------------------------===//

def : InstRW<[FXU], (instregex "LA(Y|RL)?$")>;

// Load the Global Offset Table address
def : InstRW<[FXU], (instregex "GOT$")>;

//===----------------------------------------------------------------------===//
// Absolute and Negation
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, Lat2], (instregex "LP(G)?R$")>;
def : InstRW<[FXU, FXU, Lat3, GroupAlone], (instregex "L(N|P)GFR$")>;
def : InstRW<[FXU, Lat2], (instregex "LN(R|GR)$")>;
def : InstRW<[FXU], (instregex "LC(R|GR)$")>;
def : InstRW<[FXU, FXU, Lat2, GroupAlone], (instregex "LCGFR$")>;

//===----------------------------------------------------------------------===//
// Insertion
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat5], (instregex "IC(Y)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "IC32(Y)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "ICM(H|Y)?$")>;
def : InstRW<[FXU], (instregex "II(F|H|L)Mux$")>;
def : InstRW<[FXU], (instregex "IIHF(64)?$")>;
def : InstRW<[FXU], (instregex "IIHH(64)?$")>;
def : InstRW<[FXU], (instregex "IIHL(64)?$")>;
def : InstRW<[FXU], (instregex "IILF(64)?$")>;
def : InstRW<[FXU], (instregex "IILH(64)?$")>;
def : InstRW<[FXU], (instregex "IILL(64)?$")>;

//===----------------------------------------------------------------------===//
// Addition
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat5], (instregex "A(Y|SI)?$")>;
def : InstRW<[FXU, LSU, Lat6], (instregex "AH(Y)?$")>;
def : InstRW<[FXU], (instregex "AIH$")>;
def : InstRW<[FXU], (instregex "AFI(Mux)?$")>;
def : InstRW<[FXU], (instregex "AGFI$")>;
def : InstRW<[FXU], (instregex "AGHI(K)?$")>;
def : InstRW<[FXU], (instregex "AGR(K)?$")>;
def : InstRW<[FXU], (instregex "AHI(K)?$")>;
def : InstRW<[FXU], (instregex "AHIMux(K)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "AL(Y)?$")>;
def : InstRW<[FXU], (instregex "AL(FI|HSIK)$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "ALG(F)?$")>;
def : InstRW<[FXU], (instregex "ALGHSIK$")>;
def : InstRW<[FXU], (instregex "ALGF(I|R)$")>;
def : InstRW<[FXU], (instregex "ALGR(K)?$")>;
def : InstRW<[FXU], (instregex "ALR(K)?$")>;
def : InstRW<[FXU], (instregex "AR(K)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "AG(SI)?$")>;

// Logical addition with carry
def : InstRW<[FXU, LSU, Lat7, GroupAlone], (instregex "ALC(G)?$")>;
def : InstRW<[FXU, Lat3, GroupAlone], (instregex "ALC(G)?R$")>;

// Add with sign extension (32 -> 64)
def : InstRW<[FXU, LSU, Lat6], (instregex "AGF$")>;
def : InstRW<[FXU, Lat2], (instregex "AGFR$")>;

//===----------------------------------------------------------------------===//
// Subtraction
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat5], (instregex "S(G|Y)?$")>;
def : InstRW<[FXU, LSU, Lat6], (instregex "SH(Y)?$")>;
def : InstRW<[FXU], (instregex "SGR(K)?$")>;
def : InstRW<[FXU], (instregex "SLFI$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "SL(G|GF|Y)?$")>;
def : InstRW<[FXU], (instregex "SLGF(I|R)$")>;
def : InstRW<[FXU], (instregex "SLGR(K)?$")>;
def : InstRW<[FXU], (instregex "SLR(K)?$")>;
def : InstRW<[FXU], (instregex "SR(K)?$")>;

// Subtraction with borrow
def : InstRW<[FXU, LSU, Lat7, GroupAlone], (instregex "SLB(G)?$")>;
def : InstRW<[FXU, Lat3, GroupAlone], (instregex "SLB(G)?R$")>;

// Subtraction with sign extension (32 -> 64)
def : InstRW<[FXU, LSU, Lat6], (instregex "SGF$")>;
def : InstRW<[FXU, Lat2], (instregex "SGFR$")>;

//===----------------------------------------------------------------------===//
// AND
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat5], (instregex "N(G|Y)?$")>;
def : InstRW<[FXU], (instregex "NGR(K)?$")>;
def : InstRW<[FXU], (instregex "NI(FMux|HMux|LMux)$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "NI(Y)?$")>;
def : InstRW<[FXU], (instregex "NIHF(64)?$")>;
def : InstRW<[FXU], (instregex "NIHH(64)?$")>;
def : InstRW<[FXU], (instregex "NIHL(64)?$")>;
def : InstRW<[FXU], (instregex "NILF(64)?$")>;
def : InstRW<[FXU], (instregex "NILH(64)?$")>;
def : InstRW<[FXU], (instregex "NILL(64)?$")>;
def : InstRW<[FXU], (instregex "NR(K)?$")>;
def : InstRW<[LSU, LSU, FXU, Lat9, GroupAlone], (instregex "NC$")>;

//===----------------------------------------------------------------------===//
// OR
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat5], (instregex "O(G|Y)?$")>;
def : InstRW<[FXU], (instregex "OGR(K)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "OI(Y)?$")>;
def : InstRW<[FXU], (instregex "OI(FMux|HMux|LMux)$")>;
def : InstRW<[FXU], (instregex "OIHF(64)?$")>;
def : InstRW<[FXU], (instregex "OIHH(64)?$")>;
def : InstRW<[FXU], (instregex "OIHL(64)?$")>;
def : InstRW<[FXU], (instregex "OILF(64)?$")>;
def : InstRW<[FXU], (instregex "OILH(64)?$")>;
def : InstRW<[FXU], (instregex "OILL(64)?$")>;
def : InstRW<[FXU], (instregex "OR(K)?$")>;
def : InstRW<[LSU, LSU, FXU, Lat9, GroupAlone], (instregex "OC$")>;

//===----------------------------------------------------------------------===//
// XOR
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat5], (instregex "X(G|Y)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "XI(Y)?$")>;
def : InstRW<[FXU], (instregex "XIFMux$")>;
def : InstRW<[FXU], (instregex "XGR(K)?$")>;
def : InstRW<[FXU], (instregex "XIHF(64)?$")>;
def : InstRW<[FXU], (instregex "XILF(64)?$")>;
def : InstRW<[FXU], (instregex "XR(K)?$")>;
def : InstRW<[LSU, LSU, FXU, Lat9, GroupAlone], (instregex "XC$")>;

//===----------------------------------------------------------------------===//
// Multiplication
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat10], (instregex "MS(GF|Y)?$")>;
def : InstRW<[FXU, Lat6], (instregex "MS(R|FI)$")>;
def : InstRW<[FXU, LSU, Lat12], (instregex "MSG$")>;
def : InstRW<[FXU, Lat8], (instregex "MSGR$")>;
def : InstRW<[FXU, Lat6], (instregex "MSGF(I|R)$")>;
def : InstRW<[FXU, LSU, Lat15, GroupAlone], (instregex "MLG$")>;
def : InstRW<[FXU, Lat9, GroupAlone], (instregex "MLGR$")>;
def : InstRW<[FXU, Lat5], (instregex "MGHI$")>;
def : InstRW<[FXU, Lat5], (instregex "MHI$")>;
def : InstRW<[FXU, LSU, Lat9], (instregex "MH(Y)?$")>;

//===----------------------------------------------------------------------===//
// Division and remainder
//===----------------------------------------------------------------------===//

def : InstRW<[FPU, FPU, FXU, FXU, FXU, FXU, Lat30, GroupAlone],
              (instregex "DSG(F)?R$")>;
def : InstRW<[FPU, FPU, LSU, FXU, FXU, FXU, Lat30, GroupAlone],
              (instregex "DSG(F)?$")>;
def : InstRW<[FPU, FPU, FXU, FXU, FXU, FXU, FXU, Lat30, GroupAlone],
              (instregex "DL(G)?R$")>;
def : InstRW<[FPU, FPU, LSU, FXU, FXU, FXU, FXU, Lat30, GroupAlone],
              (instregex "DL(G)?$")>;

//===----------------------------------------------------------------------===//
// Shifts
//===----------------------------------------------------------------------===//

def : InstRW<[FXU], (instregex "SLL(G|K)?$")>;
def : InstRW<[FXU], (instregex "SRL(G|K)?$")>;
def : InstRW<[FXU], (instregex "SRA(G|K)?$")>;
def : InstRW<[FXU], (instregex "SLA(K)?$")>;

// Rotate
def : InstRW<[FXU, LSU, Lat6], (instregex "RLL(G)?$")>;

// Rotate and insert
def : InstRW<[FXU], (instregex "RISBG(N|32)?$")>;
def : InstRW<[FXU], (instregex "RISBH(G|H|L)$")>;
def : InstRW<[FXU], (instregex "RISBL(G|H|L)$")>;
def : InstRW<[FXU], (instregex "RISBMux$")>;

// Rotate and Select
def : InstRW<[FXU, FXU, Lat3, GroupAlone], (instregex "R(N|O|X)SBG$")>;

//===----------------------------------------------------------------------===//
// Comparison
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat5], (instregex "C(G|Y|Mux|RL)?$")>;
def : InstRW<[FXU], (instregex "CFI(Mux)?$")>;
def : InstRW<[FXU], (instregex "CG(F|H)I$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "CG(HSI|RL)$")>;
def : InstRW<[FXU], (instregex "C(G)?R$")>;
def : InstRW<[FXU], (instregex "C(HI|IH)$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "CH(F|SI)$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "CL(Y|Mux|FHSI)?$")>;
def : InstRW<[FXU], (instregex "CLFI(Mux)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "CLG(HRL|HSI)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "CLGF(RL)?$")>;
def : InstRW<[FXU], (instregex "CLGF(I|R)$")>;
def : InstRW<[FXU], (instregex "CLGR$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "CLGRL$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "CLH(F|RL|HSI)$")>;
def : InstRW<[FXU], (instregex "CLIH$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "CLI(Y)?$")>;
def : InstRW<[FXU], (instregex "CLR$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "CLRL$")>;

// Compare halfword
def : InstRW<[FXU, LSU, Lat6], (instregex "CH(Y|RL)?$")>;
def : InstRW<[FXU, LSU, Lat6], (instregex "CGH(RL)?$")>;
def : InstRW<[FXU, FXU, LSU, Lat6, GroupAlone], (instregex "CHHSI$")>;

// Compare with sign extension (32 -> 64)
def : InstRW<[FXU, LSU, Lat6], (instregex "CGF(RL)?$")>;
def : InstRW<[FXU, Lat2], (instregex "CGFR$")>;

// Compare logical character
def : InstRW<[FXU, LSU, LSU, Lat9, GroupAlone], (instregex "CLC$")>;

def : InstRW<[LSU, Lat30, GroupAlone], (instregex "CLST$")>;

// Test under mask
def : InstRW<[FXU, LSU, Lat5], (instregex "TM(Y)?$")>;
def : InstRW<[FXU], (instregex "TM(H|L)Mux$")>;
def : InstRW<[FXU], (instregex "TMHH(64)?$")>;
def : InstRW<[FXU], (instregex "TMHL(64)?$")>;
def : InstRW<[FXU], (instregex "TMLH(64)?$")>;
def : InstRW<[FXU], (instregex "TMLL(64)?$")>;

//===----------------------------------------------------------------------===//
// Prefetch
//===----------------------------------------------------------------------===//

def : InstRW<[LSU], (instregex "PFD(RL)?$")>;

//===----------------------------------------------------------------------===//
// Atomic operations
//===----------------------------------------------------------------------===//

def : InstRW<[LSU, EndGroup], (instregex "Serialize$")>;

def : InstRW<[FXU, LSU, Lat5], (instregex "LAA(G)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LAAL(G)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LAN(G)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LAO(G)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "LAX(G)?$")>;

// Compare and swap
def : InstRW<[FXU, FXU, LSU, Lat6, GroupAlone], (instregex "CS(G|Y)?$")>;

//===----------------------------------------------------------------------===//
// Transactional execution
//===----------------------------------------------------------------------===//

// Transaction begin
def : InstRW<[LSU, LSU, FXU, FXU, FXU, FXU, FXU, Lat15, GroupAlone],
              (instregex "TBEGIN(C|_nofloat)?$")>;

// Transaction end
def : InstRW<[LSU, GroupAlone], (instregex "TEND$")>;

// Transaction abort
def : InstRW<[LSU, GroupAlone], (instregex "TABORT$")>;

// Extract Transaction Nesting Depth
def : InstRW<[FXU], (instregex "ETND$")>;

// Nontransactional store
def : InstRW<[FXU, LSU, Lat5], (instregex "NTSTG$")>;

//===----------------------------------------------------------------------===//
// Processor assist
//===----------------------------------------------------------------------===//

def : InstRW<[FXU], (instregex "PPA$")>;

//===----------------------------------------------------------------------===//
// Miscellaneous Instructions.
//===----------------------------------------------------------------------===//

// Insert Program Mask
def : InstRW<[FXU, Lat3, EndGroup], (instregex "IPM$")>;

// Extract access register
def : InstRW<[LSU], (instregex "EAR$")>;

// Find leftmost one
def : InstRW<[FXU, Lat7, GroupAlone], (instregex "FLOGR$")>;

// Population count
def : InstRW<[FXU, Lat3], (instregex "POPCNT$")>;

// Extend
def : InstRW<[FXU], (instregex "AEXT128_64$")>;
def : InstRW<[FXU], (instregex "ZEXT128_(32|64)$")>;

// String instructions
def : InstRW<[FXU, LSU, Lat30], (instregex "SRST$")>;

// Move with key
def : InstRW<[LSU, Lat8, GroupAlone], (instregex "MVCK$")>;

// Extract CPU Time
def : InstRW<[FXU, Lat5, LSU], (instregex "ECTG$")>;

// Execute
def : InstRW<[LSU, GroupAlone], (instregex "EX(RL)?$")>;

// Program return
def : InstRW<[FXU, Lat30], (instregex "PR$")>;

// Inline assembly
def : InstRW<[FXU, LSU, LSU, Lat9, GroupAlone], (instregex "STCK(F)?$")>;
def : InstRW<[LSU, LSU, LSU, LSU, FXU, FXU, Lat20, GroupAlone],
             (instregex "STCKE$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "STFLE$")>;
def : InstRW<[FXU, Lat30], (instregex "SVC$")>;

// Store real address
def : InstRW<[FXU, LSU, Lat5], (instregex "STRAG$")>;

//===----------------------------------------------------------------------===//
// .insn directive instructions
//===----------------------------------------------------------------------===//

// An "empty" sched-class will be assigned instead of the "invalid sched-class".
// getNumDecoderSlots() will then return 1 instead of 0.
def : InstRW<[], (instregex "Insn.*")>;


// ----------------------------- Floating point ----------------------------- //

//===----------------------------------------------------------------------===//
// FP: Select instructions
//===----------------------------------------------------------------------===//

def : InstRW<[FXU], (instregex "SelectF(32|64|128)$")>;
def : InstRW<[FXU], (instregex "CondStoreF32(Inv)?$")>;
def : InstRW<[FXU], (instregex "CondStoreF64(Inv)?$")>;

//===----------------------------------------------------------------------===//
// FP: Move instructions
//===----------------------------------------------------------------------===//

// Load zero
def : InstRW<[FXU], (instregex "LZ(DR|ER)$")>;
def : InstRW<[FXU, FXU, Lat2, GroupAlone], (instregex "LZXR$")>;

// Load
def : InstRW<[FXU], (instregex "LER$")>;
def : InstRW<[FXU], (instregex "LD(R|R32|GR)$")>;
def : InstRW<[FXU, Lat3], (instregex "LGDR$")>;
def : InstRW<[FXU, FXU, Lat2, GroupAlone], (instregex "LXR$")>;

// Load and Test
def : InstRW<[FPU], (instregex "LT(D|E)BR$")>;
def : InstRW<[FPU], (instregex "LTEBRCompare(_VecPseudo)?$")>;
def : InstRW<[FPU], (instregex "LTDBRCompare(_VecPseudo)?$")>;
def : InstRW<[FPU, FPU, Lat9, GroupAlone], (instregex "LTXBR$")>;
def : InstRW<[FPU, FPU, Lat9, GroupAlone],
             (instregex "LTXBRCompare(_VecPseudo)?$")>;

// Copy sign
def : InstRW<[FXU, FXU, Lat5, GroupAlone], (instregex "CPSDRd(d|s)$")>;
def : InstRW<[FXU, FXU, Lat5, GroupAlone], (instregex "CPSDRs(d|s)$")>;

//===----------------------------------------------------------------------===//
// FP: Load instructions
//===----------------------------------------------------------------------===//

def : InstRW<[LSU], (instregex "LE(Y)?$")>;
def : InstRW<[LSU], (instregex "LD(Y|E32)?$")>;
def : InstRW<[LSU], (instregex "LX$")>;

//===----------------------------------------------------------------------===//
// FP: Store instructions
//===----------------------------------------------------------------------===//

def : InstRW<[FXU, LSU, Lat7], (instregex "STD(Y)?$")>;
def : InstRW<[FXU, LSU, Lat7], (instregex "STE(Y)?$")>;
def : InstRW<[FXU, LSU, Lat5], (instregex "STX$")>;

//===----------------------------------------------------------------------===//
// FP: Conversion instructions
//===----------------------------------------------------------------------===//

// Load rounded
def : InstRW<[FPU], (instregex "LEDBR(A)?$")>;
def : InstRW<[FPU, FPU, Lat20], (instregex "LEXBR(A)?$")>;
def : InstRW<[FPU, FPU, Lat20], (instregex "LDXBR(A)?$")>;

// Load lengthened
def : InstRW<[FPU, LSU, Lat12], (instregex "LDEB$")>;
def : InstRW<[FPU], (instregex "LDEBR$")>;
def : InstRW<[FPU, FPU, LSU, Lat15, GroupAlone], (instregex "LX(D|E)B$")>;
def : InstRW<[FPU, FPU, Lat10, GroupAlone], (instregex "LX(D|E)BR$")>;

// Convert from fixed / logical
def : InstRW<[FXU, FPU, Lat9, GroupAlone], (instregex "CE(F|G)BR$")>;
def : InstRW<[FXU, FPU, Lat9, GroupAlone], (instregex "CD(F|G)BR$")>;
def : InstRW<[FXU, FPU, FPU, Lat11, GroupAlone], (instregex "CX(F|G)BR$")>;
def : InstRW<[FXU, FPU, Lat9, GroupAlone], (instregex "CEL(F|G)BR$")>;
def : InstRW<[FXU, FPU, Lat9, GroupAlone], (instregex "CDL(F|G)BR$")>;
def : InstRW<[FXU, FPU, FPU, Lat11, GroupAlone], (instregex "CXL(F|G)BR$")>;

// Convert to fixed / logical
def : InstRW<[FXU, FPU, Lat12, GroupAlone], (instregex "CF(E|D)BR$")>;
def : InstRW<[FXU, FPU, Lat12, GroupAlone], (instregex "CG(E|D)BR$")>;
def : InstRW<[FXU, FPU, FPU, Lat20, GroupAlone], (instregex "C(F|G)XBR$")>;
def : InstRW<[FXU, FPU, Lat11, GroupAlone], (instregex "CLF(E|D)BR$")>;
def : InstRW<[FXU, FPU, Lat11, GroupAlone], (instregex "CLG(E|D)BR$")>;
def : InstRW<[FXU, FPU, FPU, Lat20, GroupAlone], (instregex "CL(F|G)XBR$")>;

//===----------------------------------------------------------------------===//
// FP: Unary arithmetic
//===----------------------------------------------------------------------===//

// Load Complement / Negative / Positive
def : InstRW<[FPU], (instregex "L(C|N|P)DBR$")>;
def : InstRW<[FPU], (instregex "L(C|N|P)EBR$")>;
def : InstRW<[FXU], (instregex "LCDFR(_32)?$")>;
def : InstRW<[FXU], (instregex "LNDFR(_32)?$")>;
def : InstRW<[FXU], (instregex "LPDFR(_32)?$")>;
def : InstRW<[FPU, FPU, Lat9, GroupAlone], (instregex "L(C|N|P)XBR$")>;

// Square root
def : InstRW<[FPU, LSU, Lat30], (instregex "SQ(E|D)B$")>;
def : InstRW<[FPU, Lat30], (instregex "SQ(E|D)BR$")>;
def : InstRW<[FPU, FPU, Lat30, GroupAlone], (instregex "SQXBR$")>;

// Load FP integer
def : InstRW<[FPU], (instregex "FIEBR(A)?$")>;
def : InstRW<[FPU], (instregex "FIDBR(A)?$")>;
def : InstRW<[FPU, FPU, Lat15, GroupAlone], (instregex "FIXBR(A)?$")>;

//===----------------------------------------------------------------------===//
// FP: Binary arithmetic
//===----------------------------------------------------------------------===//

// Addition
def : InstRW<[FPU, LSU, Lat12], (instregex "A(E|D)B$")>;
def : InstRW<[FPU], (instregex "A(E|D)BR$")>;
def : InstRW<[FPU, FPU, Lat20, GroupAlone], (instregex "AXBR$")>;

// Subtraction
def : InstRW<[FPU, LSU, Lat12], (instregex "S(E|D)B$")>;
def : InstRW<[FPU], (instregex "S(E|D)BR$")>;
def : InstRW<[FPU, FPU, Lat20, GroupAlone], (instregex "SXBR$")>;

// Multiply
def : InstRW<[FPU, LSU, Lat12], (instregex "M(D|DE|EE)B$")>;
def : InstRW<[FPU], (instregex "M(D|DE|EE)BR$")>;
def : InstRW<[FPU, FPU, LSU, Lat15, GroupAlone], (instregex "MXDB$")>;
def : InstRW<[FPU, FPU, Lat10, GroupAlone], (instregex "MXDBR$")>;
def : InstRW<[FPU, FPU, Lat30, GroupAlone], (instregex "MXBR$")>;

// Multiply and add / subtract
def : InstRW<[FPU, LSU, Lat12, GroupAlone], (instregex "M(A|S)EB$")>;
def : InstRW<[FPU, GroupAlone], (instregex "M(A|S)EBR$")>;
def : InstRW<[FPU, LSU, Lat12, GroupAlone], (instregex "M(A|S)DB$")>;
def : InstRW<[FPU, GroupAlone], (instregex "M(A|S)DBR$")>;

// Division
def : InstRW<[FPU, LSU, Lat30], (instregex "D(E|D)B$")>;
def : InstRW<[FPU, Lat30], (instregex "D(E|D)BR$")>;
def : InstRW<[FPU, FPU, Lat30, GroupAlone], (instregex "DXBR$")>;

//===----------------------------------------------------------------------===//
// FP: Comparisons
//===----------------------------------------------------------------------===//

// Compare
def : InstRW<[FPU, LSU, Lat12], (instregex "C(E|D)B$")>;
def : InstRW<[FPU], (instregex "C(E|D)BR$")>;
def : InstRW<[FPU, FPU, Lat30], (instregex "CXBR$")>;

// Test Data Class
def : InstRW<[FPU, LSU, Lat15], (instregex "TC(E|D)B$")>;
def : InstRW<[FPU, FPU, LSU, Lat15, GroupAlone], (instregex "TCXB$")>;

}

