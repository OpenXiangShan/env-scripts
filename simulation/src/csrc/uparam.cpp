#include "uparam.h"

uparam_t uparam;
uint64_t max_epoch;

extern "C" void uparam_read(uint64_t addr, uint64_t *data) {
    uparam.robsize = 256;
    uparam.lqsize = 64;
    uparam.sqsize = 64;
    uparam.ftqsize = 16;
    uparam.ibufsize = 32;
    uparam.intdqsize = 12;
    uparam.fpdqsize = 12;
    uparam.lsdqsize = 12;
    uparam.l2mshrs = 14;
    uparam.l3mshrs = 14;
    uparam.l2sets = 64;
    uparam.l3sets = 512;
    uparam.intphyregs = 64;
    uparam.fpphyregs = 64;
    uparam.rasssize = 16;
    max_epoch = 1;

    switch (addr) {
        case ROBSIZE_ADDR:
            *data = uparam.robsize;
            break;
        case LQSIZE_ADDR:
            *data = uparam.lqsize;
            break;
        case SQSIZE_ADDR:
            *data = uparam.sqsize;
            break;
        case FTQSIZE_ADDR:
            *data = uparam.ftqsize;
            break;
        case IBUFSIZE_ADDR:
            *data = uparam.ibufsize;
            break;
        case INTDQSIZE_ADDR:
            *data = uparam.intdqsize;
            break;
        case FPDQSIZE_ADDR:
            *data = uparam.fpdqsize;
            break;
        case LSDQSIZE_ADDR:
            *data = uparam.lsdqsize;
            break;
        case L2MSHRS_ADDR:
            *data = uparam.l2mshrs;
            break;
        case L3MSHRS_ADDR:
            *data = uparam.l3mshrs;
            break;
        case L2SETS_ADDR:
            *data = uparam.l2sets;
            break;
        case L3SETS_ADDR:
            *data = uparam.l3sets;
            break;
        case MAX_EPOCH_ADDR:
            *data = max_epoch;
            break;
        case INTPHYREGS_ADDR:
            *data = uparam.intphyregs;
            break;
        case FPPHYREGS_ADDR:
            *data = uparam.fpphyregs;
            break;
        case RASSIZE_ADDR:
            *data = uparam.rasssize;
            break;
        default:
            assert("uparam_read: invalid address");
            break;
    }

    // log
    switch (addr) {
        case ROBSIZE_ADDR:
            printf("uparam_read: ROBSIZE = %d\n", *data);
            break;
        case LQSIZE_ADDR:
            printf("uparam_read: LQSIZE = %d\n", *data);
            break;
        case SQSIZE_ADDR:
            printf("uparam_read: SQSIZE = %d\n", *data);
            break;
        case FTQSIZE_ADDR:
            printf("uparam_read: FTQSIZE = %d\n", *data);
            break;
        case IBUFSIZE_ADDR:
            printf("uparam_read: IBUFSIZE = %d\n", *data);
            break;
        case INTDQSIZE_ADDR:
            printf("uparam_read: INTDQSIZE = %d\n", *data);
            break;
        case FPDQSIZE_ADDR:
            printf("uparam_read: FPDQSIZE = %d\n", *data);
            break;
        case LSDQSIZE_ADDR:
            printf("uparam_read: LSDQSIZE = %d\n", *data);
            break;
        case L2MSHRS_ADDR:
            printf("uparam_read: L2MSHRS = %d\n", *data);
            break;
        case L3MSHRS_ADDR:
            printf("uparam_read: L3MSHRS = %d\n", *data);
            break;
        case L2SETS_ADDR:
            printf("uparam_read: L2SETS = %d\n", *data);
            break;
        case L3SETS_ADDR:
            printf("uparam_read: L3SETS = %d\n", *data);
            break;
        case MAX_EPOCH_ADDR:
            printf("uparam_read: MAX_EPOCH = %d\n", *data);
            break;
        case INTPHYREGS_ADDR:
            printf("uparam_read: INTPHYREGS = %d\n", *data);
            break;
        case FPPHYREGS_ADDR:
            printf("uparam_read: FPPHYREGS = %d\n", *data);
            break;
        case RASSIZE_ADDR:
            printf("uparam_read: RASSSIZE = %d\n", *data);
            break;
        default:
            break;
    }
}