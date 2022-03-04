# -*- coding: utf-8 -*-
"""
Created on Fri Oct  8 22:00:02 2021

@author: Emmett
"""
from typing import Union

import os
from pprint import pprint
import pandas as pd

def file_size(path: str) -> Union[int, None]:
    if os.path.isfile(path):
        return os.path.getsize(path)
    else:
        return None

def directory_size(path: str) -> pd.DataFrame:
    file_sizes = pd.DataFrame(columns=['Filename', 'Size'])
    for root, dirs, files in os.walk(path):
        for file in files:
            path = os.path.abspath(os.path.join(root, file))
            file_sizes = file_sizes.append({'Filename': path, 'Size': file_size(path)}, ignore_index=True)
    return file_sizes

# for subdir, dirs, files in os.walk(sys.argv[1]):
#     paths = (os.path.join(subdir, f) for f in files)
#     space = sum(os.stat(path).st_size for path in paths if os.path.isfile(path))


if __name__ == "__main__":
    dir = 'test'
    print(file_size("test/test_objects/2KB"))
    pprint(directory_size(dir))
    pprint(list(os.walk(dir)))
