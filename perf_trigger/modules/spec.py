from enum import Enum
import logging
from pathlib import Path


class Spec:
    class Version(Enum):
        SPEC06 = "06"
        SPECRATE17 = "17"
        SPECRATE26 = "26"

    def __init__(
        self,
        version: Version,
        benchspec_dir: Path,
    ):
        self.version = version
        self.benchspec_dir = benchspec_dir

    def __get_name(self, sub: str) -> str:
        match self.version:
            case Spec.Version.SPEC06:
                return f"SPEC{sub}2006"
            case Spec.Version.SPECRATE17:
                return f"SPEC{sub}rate2017"
            case Spec.Version.SPECRATE26:
                return f"SPEC{sub}rate2026"

    def get_name(self) -> str:
        return self.__get_name("")

    def get_int_name(self) -> str:
        return self.__get_name("int")

    def get_fp_name(self) -> str:
        return self.__get_name("fp")

    def get_int_benchmarks(self, with_id: bool | None = None) -> list[str]:
        b = SPEC_INT_BENCHMARKS[self.version].copy()
        if with_id is None:
            with_id = self.version != Spec.Version.SPEC06
        return [bench.split(".")[1] for bench in b] if not with_id else b

    def get_fp_benchmarks(self, with_id: bool | None = None) -> list[str]:
        b = SPEC_FP_BENCHMARKS[self.version].copy()
        if with_id is None:
            with_id = self.version != Spec.Version.SPEC06
        return [bench.split(".")[1] for bench in b] if not with_id else b

    def get_benchmarks(self, with_id: bool | None = None) -> list[str]:
        return self.get_int_benchmarks(with_id) + self.get_fp_benchmarks(with_id)

    def parse_ref_time(self, path: Path) -> int:
        with path.open("r", encoding="utf-8") as f:
            match self.version:
                case Spec.Version.SPEC06:
                    return int(f.readlines()[-1].strip())
                case _:
                    return int(f.readlines()[0].strip().split()[-1])

    def get_benchmark_fullname(self, bench: str) -> str:
        for b in self.get_benchmarks(with_id=True):
            if bench in b:
                return b
        logging.warning("Benchmark %s not found in SPEC %s", bench, self.version.value)
        return bench

    def get_ref_time(self, bench: str) -> int | None:
        reftime_path = (
            self.benchspec_dir
            / self.get_benchmark_fullname(bench)
            / "data"
            / (
                "refrate"
                if self.version == Spec.Version.SPECRATE17
                or self.version == Spec.Version.SPECRATE26
                else "ref"
            )
            / "reftime"
        )
        if not reftime_path.exists():
            logging.warning("Reftime file not found for %s at %s", bench, reftime_path)
            return None
        return self.parse_ref_time(reftime_path)


# const
SPEC_INT_BENCHMARKS = {
    Spec.Version.SPEC06: [
        "400.perlbench",
        "401.bzip2",
        "403.gcc",
        "429.mcf",
        "445.gobmk",
        "456.hmmer",
        "458.sjeng",
        "462.libquantum",
        "464.h264ref",
        "471.omnetpp",
        "473.astar",
        "483.xalancbmk",
    ],
    Spec.Version.SPECRATE17: [
        "500.perlbench_r",
        "502.gcc_r",
        "505.mcf_r",
        "520.omnetpp_r",
        "523.xalancbmk_r",
        "525.x264_r",
        "531.deepsjeng_r",
        "541.leela_r",
        "548.exchange2_r",
        "557.xz_r",
    ],
    Spec.Version.SPECRATE26: [
        "706.stockfish_r",
        "707.ntest_r",
        "708.sqlite_r",
        "710.omnetpp_r",
        "714.cpython_r",
        "721.gcc_r",
        "723.llvm_r",
        "727.cppcheck_r",
        "729.abc_r",
        "734.vpr_r",
        "735.gem5_r",
        "750.sealcrypto_r",
        "753.ns3_r",
        "777.zstd_r",
    ],
}

SPEC_FP_BENCHMARKS = {
    Spec.Version.SPEC06: [
        "410.bwaves",
        "416.gamess",
        "433.milc",
        "434.zeusmp",
        "435.gromacs",
        "436.cactusADM",
        "437.leslie3d",
        "444.namd",
        "447.dealII",
        "450.soplex",
        "453.povray",
        "454.calculix",
        "459.GemsFDTD",
        "465.tonto",
        "470.lbm",
        "481.wrf",
        "482.sphinx3",
    ],
    Spec.Version.SPECRATE17: [
        "503.bwaves_r",
        "507.cactuBSSN_r",
        "508.namd_r",
        "510.parest_r",
        "511.povray_r",
        "519.lbm_r",
        "521.wrf_r",
        "526.blender_r",
        "527.cam4_r",
        "538.imagick_r",
        "544.nab_r",
        "549.fotonik3d_r",
        "554.roms_r",
    ],
    Spec.Version.SPECRATE26: [
        "709.cactus_r",
        "722.palm_r",
        "731.astcenc_r",
        "736.ocio_r",
        "737.gmsh_r",
        "748.flightdm_r",
        "749.fotonik3d_r",
        "765.roms_r",
        "766.femflow_r",
        "767.nest_r",
        "772.marian_r",
        "782.lbm_r",
    ],
}


# global method for easier use
def get_int_benchmarks(version: Spec.Version, with_id: bool | None = None) -> list[str]:
    return Spec(version, Path()).get_int_benchmarks(with_id)


def get_fp_benchmarks(version: Spec.Version, with_id: bool | None = None) -> list[str]:
    return Spec(version, Path()).get_fp_benchmarks(with_id)


def get_benchmarks(version: Spec.Version, with_id: bool | None = None) -> list[str]:
    return Spec(version, Path()).get_benchmarks(with_id)
