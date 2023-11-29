import sys
import os
import json

l = [
"                    bzip2_html_29080000000_0.238028",
"                 bzip2_program_87900000000_0.086835",
"                         milc_103620000000_0.223319",
"                 bzip2_liberty_92240000000_0.330567",
"                       gcc_s04_28940000000_0.236735",
"                       gcc_g23_79200000000_0.154596",
"                     gcc_expr2_49720000000_0.155197",
"                       gcc_166_50840000000_0.172923",
"                      dealII_1011220000000_0.163493",
"                  hmmer_retro_918840000000_0.198075",
"                  hmmer_retro_316480000000_0.247079",
"                      gcc_expr_18200000000_0.147923",
"                    hmmer_nph3_30220000000_0.344659",
"                 h264ref_sss_2327920000000_0.052949",
"                 h264ref_sss_4089780000000_0.118153",
"         h264ref_foreman.main_422660000000_0.143514",
"                   bzip2_html_281880000000_0.197028",
"                     GemsFDTD_141980000000_0.245507",
"                 h264ref_sss_2685480000000_0.053290",
"           h264ref_foreman.main_9540000000_0.073487",
"          perlbench_checkspam_160620000000_0.096371",
"     h264ref_foreman.baseline_527100000000_0.072662",
"                gobmk_trevord_169440000000_0.105252",
"                  bzip2_source_98660000000_0.096497",
"                bzip2_chicken_146020000000_0.196816",
"                     calculix_685020000000_0.287028",
"                    calculix_5730920000000_0.134714",
"                      gcc_g23_157240000000_0.121889",
"          perlbench_splitmail_572540000000_0.551801",
"                       gcc_s04_93540000000_0.140664",
"                       zeusmp_463080000000_0.104185",
]

json_name = sys.argv[1]

dic = {}
for i in l:
  weight = i.strip().split("_")[-1]
  interval = i.strip().split("_")[-2]
  name = i.strip()[0:-len(weight)-len(interval)-2]
  if (name in dic):
    dic[name][interval] = weight
  else:
    dic[name] = {interval: weight}

with open(json_name, "w") as f:
  f.write(json.dumps(dic, indent=2, sort_keys=False))
