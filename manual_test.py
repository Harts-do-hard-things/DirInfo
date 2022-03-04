# -*- coding: utf-8 -*-
"""
Created on Thu Mar  3 17:12:02 2022

@author: Emmett
"""

import pyximport
pyximport.install(language_level=3)
import csquarify
import numpy as np


csquarify.squarify(np.random.random(20), 0, 0, 150, 150)
