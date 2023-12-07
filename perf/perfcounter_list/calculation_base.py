
class Calculator():
  def __init__(self):
    return

  parse_map = [
    ["From", "To"]
  ]

  calculation_list = {}

  def get_perf_counter_to_parse(self):
    return self.parse_map

  def get_perf_counter_to_show(self):
    l = list(self.calculation_list.keys())
    for pm in self.parse_map:
      if len(pm) == 3 and pm[2] == True:
        l.append(pm[1])

    return l

  def get_calculate_func(self):
    return self.calculation_list.values()