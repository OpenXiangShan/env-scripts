#ifndef __DSE_H
#define __DSE_H

#include "common.h"
#include "perfprocess.h"

Perfprocess* perfprocess = nullptr;

extern "C" char dse_init(char dse_reset_valid) {
    perfprocess = new Perfprocess(6);
    return 0;
}

extern "C" char update_deg() {
    return perfprocess->update_deg_v2();
}

#endif