from distutils.extension import Extension
from Cython.Distutils import build_ext
import sdss3tools
import os.path
import numpy

xiQ_module = Extension(
    "xiQ_device",
    ["cython/xiQ_device.pyx"],
    library_dirs = ["/opt/XIMEA/include"],
    libraries = ["m3api"],
    include_dirs = ["cython",
                    numpy.get_include()],
)

xiQ_module.cython_directives = {'language_level': "3"}

sdss3tools.setup(
    name = "FVC",
    description = "Fiber viewing camera actor.",
    cmdclass = {"build_ext": build_ext},
    ext_modules = [xiQ_module]
)