#! /usr/bin/env python3
import argparse
import os

def get_spec_reftime(benchspec, spec_version):
  if spec_version == 2006:
    base_path = "/nfs/home/share/cpu2006v99/benchspec/CPU2006"
    for dirname in os.listdir(base_path):
      if benchspec in dirname:
        reftime_path = os.path.join(base_path, dirname, "data/ref/reftime")
        f = open(reftime_path)
        reftime = int(f.readlines()[-1])
        f.close()
        return reftime
  elif spec_version == 2017:
    base_path = "/nfs/home/share/spec2017_slim/benchspec/CPU"
    for dirname in os.listdir(base_path):
      if benchspec in dirname and dirname.endswith("_r"):
        reftime_path = os.path.join(base_path, dirname, "data/refrate/reftime")
        f = open(reftime_path)
        reftime = int(f.readlines()[0].split()[-1])
        f.close()
        return reftime
  print(f"do not find reftime for {benchspec} {spec_version}")
  return None


def get_spec_int(spec_version):
  if spec_version == 2006:
    return [
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
      "483.xalancbmk"
    ]
  elif spec_version == 2017:
    return [
      "500.perlbench_r",
      "502.gcc_r",
      "505.mcf_r",
      "520.omnetpp_r",
      "523.xalancbmk_r",
      "525.x264_r",
      "531.deepsjeng_r",
      "541.leela_r",
      "548.exchange2_r",
      "557.xz_r"
    ]
  return None


def get_spec_fp(spec_version):
  if spec_version == 2006:
    return [
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
      "454.Calculix",
      "459.GemsFDTD",
      "465.tonto",
      "470.lbm",
      "481.wrf",
      "482.sphinx3",
    ]
  elif spec_version == 2017:
    return [
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
      "554.roms_r"
    ]
  return None


def get_spec_score(spec_time, spec_version, frequency):
  print("==================== Score ===================")
  total_count = 0
  total_score = 1
  spec_score = dict()
  for spec_name in spec_time:
    reftime = get_spec_reftime(spec_name, spec_version)
    if reftime is None:
      continue
    score = reftime / spec_time[spec_name]
    total_count += 1
    total_score *= score
    print(f"{spec_name:>15}: {score:6.3f}, {score / frequency:6.3f}")
    spec_score[spec_name] = score
  geomean_score = total_score ** (1 / total_count)
  print(f"SPEC{spec_version}@{frequency}GHz: {geomean_score:6.3f}")
  print(f"SPEC{spec_version}/GHz:  {geomean_score / frequency:6.3f}")
  print()
  print(f"********* SPECINT {spec_version} *********")
  specint_list = get_spec_int(spec_version)
  specint_score = 1
  for benchspec in specint_list:
    found = False
    for name in spec_score:
      if name.lower() in benchspec.lower():
        found = True
        score = spec_score[name]
        specint_score *= score
        print(f"{benchspec:>15}: {score:6.3f}, {score / frequency:6.3f}")
    if not found:
      print(f"{benchspec:>15}: N/A")
  geomean_specint_score = specint_score ** (1 / len(specint_list))
  print(f"SPECint{spec_version}@{frequency}GHz: {geomean_specint_score:6.3f}")
  print(f"SPECint{spec_version}/GHz:  {geomean_specint_score / frequency:6.3f}")
  print()
  print(f"********* SPECFP  {spec_version} *********")
  specfp_list = get_spec_fp(spec_version)
  specfp_score = 1
  for benchspec in specfp_list:
    found = False
    for name in spec_score:
      if name.lower() in benchspec.lower():
        found = True
        score = spec_score[name]
        specfp_score *= score
        print(f"{benchspec:>15}: {score:6.3f}, {score / frequency:6.3f}")
    if not found:
      print(f"{benchspec:>15}: N/A")
  geomean_specfp_score = specfp_score ** (1 / len(specfp_list))
  print(f"SPECfp{spec_version}@{frequency}GHz: {geomean_specfp_score:6.3f}")
  print(f"SPECfp{spec_version}/GHz: {geomean_specfp_score / frequency:6.3f}")
  print()


def get_spec_time(csv_path):
  def to_seconds(s):
    hours, minutes, seconds = s.split(":")
    return 3600 * int(hours) + 60 * int(minutes) + int(seconds)
  spec_time = {}
  with open(csv_path, "r") as f:
    for line in f:
      items = line.strip().split(",")
      if not items:
        continue
      elif len(items) == 3:
        name, start_time, finish_time = items
        spec_name = name.split("_")[0]
        num_seconds = to_seconds(finish_time) - to_seconds(start_time)
        spec_time[spec_name] = spec_time.get(spec_name, 0) + num_seconds
  return spec_time


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="spec score scripts")
  parser.add_argument('csv_path', metavar='csv_path', type=str,
                      help='path to spec time csv')
  parser.add_argument('--version', default=2006, type=int, help='SPEC version')
  parser.add_argument('--frequency', default=1, type=float, help='CPU frequency')

  args = parser.parse_args()

  spec_time = get_spec_time(args.csv_path)
  get_spec_score(spec_time, args.version, args.frequency)
