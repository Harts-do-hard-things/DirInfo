    # -*- coding: utf-8 -*-

import pytest
from .. import dirinfo
import os

class TestFileInfo:
    def test_file_2kb(self):
        assert os.path.isfile("test/test_objects/2KB")

    def test_size_2kb(self):
        assert dirinfo.file_size("test/test_objects/2KB") == 2048

    def test_size_1mb(self):
        assert dirinfo.file_size("test/test_objects/1MB") == 1048576
