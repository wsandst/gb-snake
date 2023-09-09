# Convert a formula to a value table between the specified range
import sys
from math import *

def main():
    if len(sys.argv) < 4:
        print("Usage: python3 tablerize_formula.py <FORMULA> <MIN_X> <MAX_X>")
        exit()
    function = lambda x: eval(sys.argv[1])
    max_x = int(sys.argv[2])
    min_x = int(sys.argv[3])
    table = tablerize(function, max_x, min_x)
    print(table)

def tablerize(function, x_min, x_max):
    result = f"; Function table for '{sys.argv[1]}'\n"
    comment = ";x:"
    values = "db "
    for x in range(x_min, x_max + 1):
        if (x % 16 == 0 and x != 0):
            result += comment[:-2] + "\n" + values[:-2] + "\n"
            comment = ";x:"
            values = "db "
        comment += f"{x:4}, "
        values += f"{round(function(x)):4}, "
    if values != "db ":
        result += comment[:-2] + "\n" + values[:-2] + "\n"
    return result

if __name__ == "__main__":
    main()



