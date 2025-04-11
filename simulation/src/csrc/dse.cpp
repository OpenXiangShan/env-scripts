#ifndef __DSE_H
#define __DSE_H

#include "svdpi.h"
#include "common.h"
#include "perfprocess.h"
#include "uparam.h"
#include "ArchExplorerEngine.h"

#define RECORD_NUM 200

Perfprocess* perfprocess = nullptr;
ArchExplorerEngine* engine = nullptr;
std::vector<int> embedding;
long int deg_record_num = RECORD_NUM;
int epoch = 1;
bool verbose = false;

void parse_deg_package(const uint8_t* data, long int deg_data_byte, long int magic_num_byte);
void parse_perf_package(const uint8_t* data, long int deg_data_byte, long int magic_num_byte);

void deg_finalize();

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
}

void parse_perf_package(const uint8_t* data, long int deg_data_byte, long int magic_num_byte) {
    printf("[parse_perf_package]\n");
}

#endif