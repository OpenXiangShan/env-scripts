import argparse
import csv
import re
from multiprocessing import Process, Queue


def replace_digits(s):
  re_digits = re.compile(r"(\d+)")
  pieces = re_digits.split(s)
  return "".join(map(lambda x: "*" if x.isdecimal() else x, pieces))

def get_line_count(filename):
  return sum(1 for _ in open(filename))

# startline <= line_number < endline
def extract_from_file(infile, startline, endline):
  re_report = re.compile(r"^([0-9a-zA-Z_\/]+) *([0-9a-zA-Z_\/]+) *([0-9e\-\.]+) *(\d+)\s*$")
  all_path = dict()
  with open(infile, "r") as f:
    line_number = -1
    for line in f:
      line_number += 1
      if line_number < startline:
        continue
      if endline > 0 and line_number >= endline:
        break
      report_match = re_report.match(line)
      if report_match:
        startpoint = replace_digits(str(report_match.group(1)))
        endpoint = replace_digits(str(report_match.group(2)))
        slack = float(report_match.group(3))
        logic_depth = int(report_match.group(4))
        path_key = (startpoint, endpoint)
        path_value = (slack, logic_depth)
        all_path[path_key] = all_path.get(path_key, []) + [path_value]
  return all_path

def extract_path_worker(infile, batch_size, worker_queue, result_queue):
  while not worker_queue.empty():
    batch_index = worker_queue.get()
    startline = batch_size * batch_index
    endline = startline + batch_size
    result = extract_from_file(infile, startline, endline)
    result_queue.put(result)

def extract_path(infile, outfile, n_threads=1):
  batch_size = 10000
  worker_queue = Queue()
  batch_number = (get_line_count(infile) + batch_size - 1) // batch_size
  for i in range(0, batch_number):
    worker_queue.put(i)
  result_queue = Queue()
  process_list = []
  for i in range(0, n_threads):
    proc = Process(target=extract_path_worker, args=(infile, batch_size, worker_queue, result_queue))
    process_list.append(proc)
    proc.start()
  result_list = []
  while len(result_list) != batch_number:
    result_list.append(result_queue.get())
    print(f"Finished {len(result_list)} of {batch_number}")
  all_keys = set()
  for result in result_list:
    all_keys.update(result.keys())
  with open(outfile, 'w') as csvfile:
    csvwriter = csv.writer(csvfile)
    all_info = [
      "startpoint", "endpoint",
      "max_slack", "max_logic_depth",
      "min_slack", "min_logic_depth",
      "average_slack", "average_logic_depth"
    ]
    csvwriter.writerow(all_info)
    for (startpoint, endpoint) in sorted(all_keys):
      all_values = []
      for result in result_list:
        all_values += result.get((startpoint, endpoint), [])
      all_values = list(set(all_values))
      slack, logic_depth = list(zip(*all_values))
      max_slack = max(slack)
      min_slack = min(slack)
      average_slack = sum(slack) / len(slack)
      max_logic_depth = max(logic_depth)
      min_logic_depth = min(logic_depth)
      average_logic_depth = sum(logic_depth) / len(logic_depth)
      all_info = [
        startpoint, endpoint,
        max_slack, max_logic_depth,
        min_slack, min_logic_depth,
        average_slack, average_logic_depth
      ]
      csvwriter.writerow(all_info)

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="extract paths from timing report")
  parser.add_argument('filename', type=str, help='path to timinig report')
  parser.add_argument('--output', '-o', default="timing.csv", help='output file')
  parser.add_argument('--jobs', '-j', default=1, type=int, help="processing files with 'j' threads")

  args = parser.parse_args()

  extract_path(args.filename, args.output, args.jobs)
