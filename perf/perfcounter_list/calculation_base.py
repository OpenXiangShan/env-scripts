import sys
import re

class Calculator():
  def __init__(self):
    return

  parse_map = [
    ["From", "To"]
  ]
  """
  A example for re:
    1. the re str, should have fullMatch to generate the "From" str
    2. when use re, the second element should be a func, which can generate the "To" str, func's param is the re result
    3. the third element is optional, if it is True, the "To" str will be shown in the final result

  parse_map = [
    ["backend.dataPath: IntRegFileWrite_hist_sampled, ", "IRFW_sampled", True],
    [r'^.+(?P<fullMatch>backend.dataPath: IntRegFileRead_hist_(?P<indexNum>\d+)_\d+, )\s+\d+$',
     lambda x:f'W_{x.group("indexNum")}', True],
  ]
  """

  calculation_list = {}

  def get_perf_counter_to_parse(self, eg_file = None):
    if eg_file == None:
      for pm in self.parse_map:
        if not isinstance(pm[1], str):
          print(f"error: {pm[1]} is not str, should be a func, check re")
          sys.exit()
      return self.parse_map
    else:
      res = []
      re_tmp = []
      with open(eg_file, "r") as file:
        res_from_set = set()
        res_to_set = set()
        for pm in self.parse_map:
          if isinstance(pm[1], str):
            # normal patten
            res.append(pm)
          elif callable(pm[1]):
            pm_tmp = pm.copy()
            pm_tmp[0] = re.compile(pm_tmp[0])
            re_tmp.append(pm_tmp)
          else:
            print(f"{__file__} {__name__} parse_map error. Second variable should be string or function")
            sys.exit(1)

        if len(re_tmp) == 0:
          return res

        for line in file:
          for pm in re_tmp:
            res_re = pm[0].match(line)
            if res_re != None:
              from_str = res_re.group("fullMatch")
              to_str = pm[1](res_re)
              to_show = False if len(pm) < 3 else pm[2]
              if not (from_str in res_from_set) and not (to_str in res_to_set):
                res_from_set.add(from_str)
                res_to_set.add(to_str)
                res.append([from_str, to_str, to_show])
        return res

  def get_perf_counter_to_show(self, eg_file = None):
    l = list(self.calculation_list.keys())
    final_paser_map = self.get_perf_counter_to_parse(eg_file)
    for pm in final_paser_map:
      if len(pm) == 3 and pm[2] == True:
        l.append(pm[1])
    return l

  def get_calculate_func(self):
    return self.calculation_list.values()