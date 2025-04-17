#ifndef __DSE_H
#define __DSE_H

#include "svdpi.h"
#include "common.h"
#include "perfprocess.h"
#include "uparam.h"
#include "ArchExplorerEngine.h"
#include <iostream>
#include <fstream>
#include <vector>
#include <string>

#define RECORD_NUM 200
bool verbose = false;
int normal_perfcnt_byte = 4;
int deg_perfcnt_byte = 4;

Perfprocess* perfprocess = nullptr;
ArchExplorerEngine* engine = nullptr;
std::vector<int> embedding;
long int deg_record_num = RECORD_NUM;
int epoch = 1;

void parse_deg_package(const uint8_t* data, long int deg_data_byte, long int magic_num_byte);
void parse_perf_package(const uint8_t* data, long int deg_data_byte, long int magic_num_byte);
void deg_finalize();

struct PerfData {
    uint32_t pc;               // 程序计数器
    uint32_t instr;            // 指令

    struct {
        uint8_t fuType;        // 功能单元类型（8位）
        uint8_t fuOpType;      // 功能单元操作类型（8位）
        uint8_t blocks;        // 块信息（8位）
        uint8_t eliminatedMove;// 消除的移动（8位）
    } fuTypefuOpType;

    uint32_t FetchCacheLine;   // 取指缓存行时间

    struct {
        uint16_t cacheCompTime; // 缓存比较时间（16位）
        uint16_t fetchTime;     // 取指时间（16位）
    } ProCacheFetch;

    struct {
        uint16_t decodeTime;   // 解码时间（16位）
        uint16_t renameTime;   // 重命名时间（16位）
    } DecodeRename;

    struct {
        uint16_t dispatchTime; // 派发时间（16位）
        uint16_t enqRsTime;    // 入队RS时间（16位）
    } DispatchEnqRS;

    struct {
        uint16_t readyIssueTime; // 准备发射时间（16位）
        uint16_t selectTime;     // 选择时间（16位）
    } InsertReadyListSelect;

    struct {
        uint16_t issueTime;     // 发射时间（16位）
        uint16_t writebackTime; // 写回时间（16位）
    } IssueComplete;

    uint32_t Commit;           // 提交时间
    uint32_t ROB;              // ROB索引

    struct {
        uint16_t lqIdx;        // 加载队列索引（16位）
        uint16_t sqIdx;        // 存储队列索引（16位）
    } LQSQ;

    struct {
        uint16_t rsIdx;        // RS索引（16位）
        uint16_t fuIdx;        // 功能单元索引（16位）
    } RSFU;

    struct {
        uint8_t psrc0;         // 源操作数0（8位）
        uint8_t psrc1;         // 源操作数1（8位）
        uint8_t psrc2;         // 源操作数2（8位）
        uint8_t pdest;         // 目的操作数（8位）
    } SRC012DST;

    uint32_t SRCTypes;         // 源类型
};

inline uint32_t getU32LE(const uint8_t *data) {
    return data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24);
}

PerfData parsePerfData(const uint8_t *data) {
    PerfData perf;
    const uint8_t *ptr = data;

    // 解析每个字段
    perf.pc = getU32LE(ptr); ptr += 4;
    perf.instr = getU32LE(ptr); ptr += 4;

    uint32_t fuTypefuOpType_val = getU32LE(ptr); ptr += 4;
    perf.fuTypefuOpType.fuType = (fuTypefuOpType_val >> 24) & 0xFF;
    perf.fuTypefuOpType.fuOpType = (fuTypefuOpType_val >> 16) & 0xFF;
    uint16_t blocks_eliminated = fuTypefuOpType_val & 0xFFFF;
    perf.fuTypefuOpType.blocks = (blocks_eliminated >> 8) & 0xFF;
    perf.fuTypefuOpType.eliminatedMove = blocks_eliminated & 0xFF;

    perf.FetchCacheLine = getU32LE(ptr); ptr += 4;

    uint32_t proCache_val = getU32LE(ptr); ptr += 4;
    perf.ProCacheFetch.cacheCompTime = (proCache_val >> 16) & 0xFFFF;
    perf.ProCacheFetch.fetchTime = proCache_val & 0xFFFF;

    uint32_t decodeRename_val = getU32LE(ptr); ptr += 4;
    perf.DecodeRename.decodeTime = (decodeRename_val >> 16) & 0xFFFF;
    perf.DecodeRename.renameTime = decodeRename_val & 0xFFFF;

    uint32_t dispatchEnqRS_val = getU32LE(ptr); ptr += 4;
    perf.DispatchEnqRS.dispatchTime = (dispatchEnqRS_val >> 16) & 0xFFFF;
    perf.DispatchEnqRS.enqRsTime = dispatchEnqRS_val & 0xFFFF;

    uint32_t insertReady_val = getU32LE(ptr); ptr += 4;
    perf.InsertReadyListSelect.readyIssueTime = (insertReady_val >> 16) & 0xFFFF;
    perf.InsertReadyListSelect.selectTime = insertReady_val & 0xFFFF;

    uint32_t issueComplete_val = getU32LE(ptr); ptr += 4;
    perf.IssueComplete.issueTime = (issueComplete_val >> 16) & 0xFFFF;
    perf.IssueComplete.writebackTime = issueComplete_val & 0xFFFF;

    perf.Commit = getU32LE(ptr); ptr += 4;
    perf.ROB = getU32LE(ptr); ptr += 4;

    uint32_t lqsq_val = getU32LE(ptr); ptr += 4;
    perf.LQSQ.lqIdx = (lqsq_val >> 16) & 0xFFFF;
    perf.LQSQ.sqIdx = lqsq_val & 0xFFFF;

    uint32_t rsfu_val = getU32LE(ptr); ptr += 4;
    perf.RSFU.rsIdx = (rsfu_val >> 16) & 0xFFFF;
    perf.RSFU.fuIdx = rsfu_val & 0xFFFF;

    uint32_t src012dst_val = getU32LE(ptr); ptr += 4;
    perf.SRC012DST.psrc0 = (src012dst_val >> 24) & 0xFF;
    perf.SRC012DST.psrc1 = (src012dst_val >> 16) & 0xFF;
    perf.SRC012DST.psrc2 = (src012dst_val >> 8) & 0xFF;
    perf.SRC012DST.pdest = src012dst_val & 0xFF;

    perf.SRCTypes = getU32LE(ptr); ptr += 4;

    printf("====== Performance Data ======\n");
    
    // 基本指令信息
    printf("[PC] 0x%08X\n", perf.pc);
    printf("[Instr] 0x%08X\n", perf.instr);
    
    // 功能单元信息
    printf("[FuType] 0x%02X [FuOpType] 0x%02X\n", 
        perf.fuTypefuOpType.fuType,
        perf.fuTypefuOpType.fuOpType);
    printf("[Blocks] 0x%02X [ElimMove] 0x%02X\n",
        perf.fuTypefuOpType.blocks,
        perf.fuTypefuOpType.eliminatedMove);
    
    // 流水线阶段耗时
    printf("[FetchCache] %u cycles\n", perf.FetchCacheLine);
    printf("[CacheComp] %hu | [Fetch] %hu cycles\n",
        perf.ProCacheFetch.cacheCompTime,
        perf.ProCacheFetch.fetchTime);
    printf("[Decode] %hu | [Rename] %hu cycles\n",
        perf.DecodeRename.decodeTime,
        perf.DecodeRename.renameTime);
    
    // 调度信息
    printf("[Dispatch] %hu | [EnqRS] %hu cycles\n",
        perf.DispatchEnqRS.dispatchTime,
        perf.DispatchEnqRS.enqRsTime);
    printf("[ReadyIssue] %hu | [Select] %hu cycles\n",
        perf.InsertReadyListSelect.readyIssueTime,
        perf.InsertReadyListSelect.selectTime);
    printf("[Issue] %hu | [Complete] %hu cycles\n",
        perf.IssueComplete.issueTime,
        perf.IssueComplete.writebackTime);
    
    // 提交和队列状态
    printf("[Commit] Global Timer: %u\n", perf.Commit);
    printf("[ROB Index] %u\n", perf.ROB);
    printf("[LQ Index] %hu | [SQ Index] %hu\n",
        perf.LQSQ.lqIdx,
        perf.LQSQ.sqIdx);
    
    // 资源分配
    printf("[RS Index] %hu | [FU Index] %hu\n",
        perf.RSFU.rsIdx,
        perf.RSFU.fuIdx);
    
    // 寄存器操作数
    printf("[PSRC0] R%03u [PSRC1] R%03u\n",
        perf.SRC012DST.psrc0,
        perf.SRC012DST.psrc1);
    printf("[PSRC2] R%03u [PDEST] R%03u\n",
        perf.SRC012DST.psrc2,
        perf.SRC012DST.pdest);
    
    // 源类型掩码
    printf("[SrcTypes] 0x%08X\n", perf.SRCTypes);
    printf("==============================\n");

    return perf;
}

extern "C" char dse_init(char dse_reset_valid) {
    perfprocess = new Perfprocess(6);
    engine = new ArchExplorerEngine();
    embedding = engine->design_space.get_init_embedding();
    init_uparam(embedding, engine->max_epoch);
    engine->initial_embedding = embedding;
    engine->visualize = true;
    // engine->start_epoch(1);
    return 0;
}

extern "C" void do_dse_reset(long int dse_epoch) {
    printf("[do_dse_reset]\n");
    deg_record_num = RECORD_NUM;
    engine->start_epoch(dse_epoch);
}

extern "C" char update_deg() {
    int commit_count = perfprocess->update_deg_v2();
    deg_record_num -= commit_count;
    for (int i = 0; i < commit_count; i++) {
        engine->step(perfprocess->get_trace(i).c_str());
    }
    return commit_count;
}

extern "C" char update_deg_record(char doDSEReset, long int reset_vector, char deg_record, long int dse_epoch) {
    if (doDSEReset) {
        if (reset_vector == 0x80000000) {
            printf("[Do DEG Record]\n");
            return 1;
        } else if (reset_vector == 0x10000000) {
            printf("[End DEG Record by DSE Reset]\n");
            return 0;
        }
    }
    if (deg_record && deg_record_num <= 0) {
        deg_finalize();
        return 0;
    }
    
    return deg_record;
}

extern "C" void process_long_vector(const svBitVecVal* data, long int deg_data_width, long int magic_num_width) {
    if (verbose) {
        printf("Received data: ");
        int nrStructCnt = 37;
        int batch_slot_num = deg_data_width / 32 / nrStructCnt;
        for (int i = batch_slot_num - 1; i >= 0; i--) {
            for (int j = 0; j < nrStructCnt; j++) {
                printf("%08x ", data[i * nrStructCnt + j]);
            }
            printf("\n");
        }
        // assert(magic_num_width == 8);
        printf("magic num: %08x\n", data[deg_data_width / 32]);
        printf("=========================\n");
    }

    int total_bytes = deg_data_width / 8 + magic_num_width / 8;
    long int magic_num = data[deg_data_width / 32];
    uint8_t buffer[total_bytes];

    switch (magic_num) {
        case 1:
            /* DSE reset to workload */
            do_dse_reset(epoch);
            break;
        case 2:
            /* DEG package transfer */
            memcpy(buffer, data, total_bytes);
            parse_deg_package(buffer, deg_data_width / 8, magic_num_width / 8);
            break;
        case 3:
            /* DEG package done */
            deg_finalize();
            break;
        case 4:
            memcpy(buffer, data, total_bytes);
            parse_perf_package(buffer, deg_data_width / 8, magic_num_width / 8);
            /* simulation done, perfcnt transfer */
            break;
        default:
            printf("Unknown magic number: %ld\n", magic_num);
            break;
    }
    
}

void deg_finalize() {
    printf("[deg_finalize]\n");
    return;
    
    engine->finalize_deg();
    std::vector<int> embedding_new;
    embedding_new = engine->bottleneck_analysis(embedding, "output_" + std::to_string(epoch));
    printf("[Finish bottleneck_analysis]\n");
    engine->design_space.compare_embeddings(embedding, embedding_new);
    embedding = embedding_new;
    embedding_to_uparam(embedding);
    epoch++;
}

void parse_deg_package(const uint8_t* data, long int deg_data_byte, long int magic_num_byte) {
    printf("[parse_deg_package]\n");
    int total_bytes = deg_data_byte + magic_num_byte;
    
    if (verbose) {
        printf("Received data size: %ld\n", total_bytes);
        for (int i = 0; i < total_bytes; i++) {
            printf("%02x ", data[i]);
        }
        printf("----------------------\n");
    }
    std::vector<std::string> deg_cnts;
    int nr_deg_cnts;
    std::ifstream inputFile("./src/build/DEGPerfList.txt");
    if (!inputFile.is_open()) {
        std::cerr << "Error: Could not open file ./src/build/DEGPerfList.txt" << std::endl;
        return;
    }
    std::string line;
    while (std::getline(inputFile, line)) {
        if (!line.empty()) {
            deg_cnts.push_back(line);
        }
    }
    inputFile.close();
    nr_deg_cnts = deg_cnts.size();
    if (false) {
        std::cout << "Read " << nr_deg_cnts << " performance counters:" << std::endl;
        for (const auto& counter : deg_cnts) {
            std::cout << counter << std::endl;
        }
    }
    /* parse data for deg counters */
    assert(deg_perfcnt_byte * nr_deg_cnts <= deg_data_byte);
    assert(deg_perfcnt_byte == 4);
    int slot = deg_data_byte / (deg_perfcnt_byte * nr_deg_cnts);
    const uint32_t* ptr = (const uint32_t*)data;
    for (int i = slot - 1; i >= 0; i--) {
        // for (int j = 0; j < nr_deg_cnts; j++) {
        //     std::cout << deg_cnts[j];
        //     if (j == 1 || j == 2) {
        //         printf(": 0x%x  ", ptr[i * nr_deg_cnts + j]);
        //     } else {
        //         printf(": %d  ", ptr[i * nr_deg_cnts + j]);
        //     }
        // }
        // printf("\n");
        parsePerfData(data + i*nr_deg_cnts*4);
    }
    printf("--- \n");
}

void parse_perf_package(const uint8_t* data, long int deg_data_byte, long int magic_num_byte) {
    printf("[parse_perf_package]\n");

    /* get normal performance counter list */
    std::vector<std::string> perf_cnts;
    int nr_perf_cnts;
    std::ifstream inputFile("./src/build/NormalPerfList.txt");
    if (!inputFile.is_open()) {
        std::cerr << "Error: Could not open file ./src/build/NormalPerfList.txt" << std::endl;
        return;
    }
    std::string line;
    while (std::getline(inputFile, line)) {
        if (!line.empty()) {
            perf_cnts.push_back(line);
        }
    }
    inputFile.close();
    nr_perf_cnts = perf_cnts.size();
    if (false) {
        std::cout << "Read " << nr_perf_cnts << " performance counters:" << std::endl;
        for (const auto& counter : perf_cnts) {
            std::cout << counter << std::endl;
        }
    }

    /* parse data for performance counter */
    assert(normal_perfcnt_byte * nr_perf_cnts <= deg_data_byte);
    assert(normal_perfcnt_byte == 4);
    const uint32_t* ptr = (const uint32_t*)data;
    for (size_t i = 0; i < nr_perf_cnts; i++) {
        std::cout << perf_cnts[i];
        printf(": %u\n", ptr[i]);
    }

    printf("Received raw data: %ld\n", deg_data_byte);
    for (int i = 0; i < deg_data_byte; i++) {
        printf("%02x ", data[i]);
    }
    printf("----------------------\n");
}

#endif