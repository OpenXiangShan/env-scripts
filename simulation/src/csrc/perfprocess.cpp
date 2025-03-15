#include "perfprocess.h"

Perfprocess::Perfprocess(int commit_width) :
  isa_parser(DEFAULT_ISA, DEFAULT_PRIV)
{
  this->commit_width = commit_width;
  this->disassembler = new disassembler_t(&isa_parser, false);
}

Perfprocess::~Perfprocess() {
  delete disassembler;
}

uint64_t Perfprocess::find_perfCnt(std::string perfName) {
  int id = get_perfCnt_id(perfName);
  return perfCnts[id];
}

double Perfprocess::get_ipc() {
  auto clockCnt = find_perfCnt("clock_cycle");
  auto instrCnt = find_perfCnt("commitInstr");
  return (double)instrCnt / (double)clockCnt;
}

double Perfprocess::get_cpi() {
  auto clockCnt = find_perfCnt("clock_cycle");
  auto instrCnt = find_perfCnt("commitInstr");
  return (double)clockCnt / (double)instrCnt;
}

std::string exec(const char* cmd) {
  std::array<char, 128> buffer;
  std::string result;

  // 使用 popen 执行 shell 命令
  FILE* proc_pipe = popen(cmd, "r");
  if (!proc_pipe) {
      throw std::runtime_error("popen() failed!");
  }
  
  // 读取子进程输出
  while (fgets(buffer.data(), buffer.size(), proc_pipe) != nullptr) {
      result += buffer.data();
  }

  // 关闭进程
  pclose(proc_pipe);
  return result;
}

int Perfprocess::update_deg_v2() {
  int commit_count = 0;
  clear_traces();
  for (int i = 0; i < commit_width; i++) {
    auto do_update = find_perfCnt("isCommit_" + std::to_string(i));
    if (do_update != 0) {
      commit_count++;
      uint64_t cycle = find_perfCnt("cf_" + std::to_string(i));
      uint64_t pc = find_perfCnt("pc_" + std::to_string(i));
      uint64_t instr = find_perfCnt("instr_" + std::to_string(i));
      uint64_t fuType = find_perfCnt("fuType_" + std::to_string(i));
      uint64_t fuOpType = find_perfCnt("fuOpType_" + std::to_string(i));
      uint64_t fpu = find_perfCnt("fpu_" + std::to_string(i));
      uint64_t decode = find_perfCnt("Decode_" + std::to_string(i));
      uint64_t rename = find_perfCnt("Rename_" + std::to_string(i));
      uint64_t issue = find_perfCnt("Issue_" + std::to_string(i));
      uint64_t complete = find_perfCnt("Complete_" + std::to_string(i));
      uint64_t commit = find_perfCnt("Commit_" + std::to_string(i));
      uint64_t src_0 = find_perfCnt("SRC0_" + std::to_string(i));
      uint64_t src_1 = find_perfCnt("SRC1_" + std::to_string(i));
      uint64_t src_2 = find_perfCnt("SRC2_" + std::to_string(i));
      int src_valid_0 = find_perfCnt("SRCTYPE0_" + std::to_string(i));
      int src_valid_1 = find_perfCnt("SRCTYPE1_" + std::to_string(i));
      int src_valid_2 = find_perfCnt("SRCTYPE2_" + std::to_string(i));
      uint64_t dest = find_perfCnt("DST_" + std::to_string(i));

      // 调用 spike-dasm 解析指令
      std::string insn_decoded = disassembler->disassemble(instr);
      
      // 解析指令类型
      std::string type_str = "unknown";
      if (fuType < 8) {
          type_str = (fuOpType == 4) ? "IntMult" : (fuOpType == 5) ? "IntDiv" : "IntAlu";
      } else if (fuType < 12) {
          type_str = "Fp";
      } else {
          type_str = (fuType == 12 || fuType == 15) ? "MemRead" : (fuType == 13) ? "MemWrite" : "unknown";
      }

      // 生成 SRC 字符串
      std::string src_str = "";
      if (src_valid_0 && src_0 != 0) src_str += std::to_string(src_0);
      if (src_valid_1 && src_1 != 0) {
        if (!src_str.empty()) src_str += ",";
        src_str += std::to_string(src_1);
      }
      if (src_valid_2 && src_2 != 0) {
        if (!src_str.empty()) src_str += ",";
        src_str += std::to_string(src_2);
      }

      // 生成 trace 记录
      std::ostringstream trace;
      trace << cycle * 1000 << " : system.cpu : T0 : "
            << std::hex << "0x" << pc << " : " << insn_decoded << " : " << std::dec << type_str
            << " : _ : FetchCacheLine=" << find_perfCnt("FetchCacheLine_" + std::to_string(i)) * 1000
            << " : ProcessCacheCompletion=" << find_perfCnt("ProcessCacheCompletion_" + std::to_string(i)) * 1000
            << " : Fetch=" << find_perfCnt("Fetch_" + std::to_string(i)) * 1000
            << " : DecodeSortInsts=" << decode * 1000
            << " : Decode=" << decode * 1000
            << " : RenameSortInsts=" << rename * 1000
            << " : BlockFromROB=" << find_perfCnt("BlockFromROB_" + std::to_string(i))
            << " : BlockFromRF=" << find_perfCnt("BlockFromRF_" + std::to_string(i))
            << " : BlockFromIQ=" << (find_perfCnt("BlockFromDPQ_" + std::to_string(i)) | find_perfCnt("BlockFromSerial_" + std::to_string(i)))
            << " : BlockFromLQ=" << find_perfCnt("BlockFromLQ_" + std::to_string(i))
            << " : BlockFromSQ=" << find_perfCnt("BlockFromSQ_" + std::to_string(i))
            << " : Rename=" << rename * 1000
            << " : Dispatch=" << find_perfCnt("Dispatch_" + std::to_string(i)) * 1000
            << " : InsertReadyList=" << find_perfCnt("InsertReadyList_" + std::to_string(i)) * 1000
            << " : Issue=" << find_perfCnt("Issue_" + std::to_string(i)) * 1000
            << " : Memory=" << (issue == 0 ? 0 : (issue + 1) * 1000)
            << " : Complete=" << complete * 1000
            << " : CompleteMemory=" << complete * 1000
            << " : CommitHead=" << (commit - 1) * 1000
            << " : Commit=" << commit * 1000
            << " : ROB=" << find_perfCnt("ROB_" + std::to_string(i))
            << " : LQ=" << find_perfCnt("LQ_" + std::to_string(i))
            << " : SQ=" << find_perfCnt("SQ_" + std::to_string(i))
            << " : IQ=" << find_perfCnt("RS_" + std::to_string(i))
            << " : FU=" << find_perfCnt("FU_" + std::to_string(i))
            << " : SRC=" << src_str
            << " : DST=" << (dest == 0 ? "" : std::to_string(dest))
            << " : BlockFromDPQ=" << find_perfCnt("BlockFromDPQ_" + std::to_string(i))
            << " : BlockFromSerial=" << find_perfCnt("BlockFromSerial_" + std::to_string(i));
        
        traces.push_back(trace.str());
        std::ofstream trace_file("traces.txt", std::ios::app);
        if (trace_file.is_open()) {
            trace_file << trace.str() << std::endl;
            trace_file.close();
        } else {
            std::cerr << "Failed to open trace file for writing." << std::endl;
        }

        if (false) {
            std::cout << trace.str() << std::endl;
        }
    }
  }
  return commit_count;
}