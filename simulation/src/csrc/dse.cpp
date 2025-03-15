#ifndef __DSE_H
#define __DSE_H

#include "common.h"
#include "perfprocess.h"
#include "uparam.h"
#include "ArchExplorerEngine.h"

#define RECORD_NUM 200

Perfprocess* perfprocess = nullptr;
ArchExplorerEngine* engine = nullptr;
std::vector<int> embedding;
long int deg_record_num = RECORD_NUM;

extern "C" char dse_init(char dse_reset_valid) {
    perfprocess = new Perfprocess(6);
    engine = new ArchExplorerEngine();
    embedding = engine->design_space.get_init_embedding();
    init_uparam(embedding, engine->max_epoch);
    engine->initial_embedding = embedding;
    engine->visualize = true;
    engine->start_epoch(1);
    return 0;
}

extern "C" void do_dse_reset(long int dse_epoch) {
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
            return 0;
        }
    }
    if (deg_record && deg_record_num <= 0) {
        engine->finalize_deg();
        std::vector<int> embedding_new;
        printf("[Do bottleneck_analysis]\n");
        embedding_new = engine->bottleneck_analysis(embedding, "output_" + std::to_string(dse_epoch));
        printf("[Finish bottleneck_analysis]\n");
        engine->design_space.compare_embeddings(embedding, embedding_new);
        embedding = embedding_new;
        embedding_to_uparam(embedding);
        return 0;
    }
    
    return deg_record;
}

#endif