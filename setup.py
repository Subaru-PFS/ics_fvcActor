import distutils
from distutils.core import setup, Extension

import sdss3tools
import os, numpy

xiQ_module = Extension('xiQ_device',
    libraries = ['m3api'],
    sources = ['c/xiQ_device.c'],
    include_dirs = [numpy.get_include()],
    )

sdss3tools.setup(
    name = "FVC",
    description = "Fiber viewing camera actor.",
    ext_modules = [xiQ_module],
    )

