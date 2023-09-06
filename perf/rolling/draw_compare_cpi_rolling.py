import sys
import argparse
import sqlite3
import matplotlib.pyplot as plt
import numpy as np
import os

# Table list:
#  SELECT name FROM sqlite_master

INSTR_KEY = "XAXISPT"
CPI_KEY = "YAXISPT"
TABLE_NAME = "cpi_rolling_0"

def read_db(db_path):
  if not os.path.exists(db_path):
    print(f"data base file {db_path} does not exist")
    sys.exit(0)

  db_con = sqlite3.connect(db_path)
  db_cur = db_con.cursor()
  db_table_list = db_cur.execute(f"SELECT name FROM sqlite_master")
  db_table_list = list(map(lambda x: x[0], db_table_list))
  # print(list(db_table_list))

  if TABLE_NAME not in db_table_list:
    print(f"table {TABLE_NAME} not in {db_path}")
    sys.exit(0)

  db_data = db_cur.execute(f"SELECT {INSTR_KEY} FROM {TABLE_NAME}")
  cycle_data = (list(map(lambda x: x[0], db_data.fetchall())))

  db_data = db_cur.execute(f"SELECT {CPI_KEY} FROM {TABLE_NAME}")
  cpi_data = (list(map(lambda x: x[0], db_data.fetchall())))

  db_con.close()
  return (cycle_data, cpi_data)

def draw_line_chart(xaxis_list, yaxis_list, name_list):

  plt.title("CPI Rolling")
  plt.xlabel("Instruction Count/1000")
  plt.ylabel("Cycle")

  for (pt_name, x_pt, y_pt) in zip(name_list, xaxis_list, yaxis_list):
    plt.plot(x_pt, y_pt, label=pt_name)

  plt.legend(name_list)
  plt.show()

cycle_data_list = []
cpi_data_list = []
db_list = sys.argv[1:]

for db_path in db_list:
  (cycle_data, cpi_data) = read_db(db_path)
  cycle_data_list.append(cycle_data)
  cpi_data_list.append(cpi_data)

draw_line_chart(cycle_data_list, cpi_data_list, db_list)