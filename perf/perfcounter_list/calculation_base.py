
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
    return self.calculation_list.keys()

  def get_calculate_func(self):
    return self.calculation_list.values()