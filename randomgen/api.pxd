"""
Needed to allow NumPy API 1.7 with Cython < 0.29
Can be removed once minimum Cython is 0.29
"""

cdef extern from "numpy/arrayobject.h":
    enum:
        NPY_ARRAY_C_CONTIGUOUS
        NPY_ARRAY_F_CONTIGUOUS
        NPY_ARRAY_OWNDATA
        NPY_ARRAY_FORCECAST
        NPY_ARRAY_ENSURECOPY
        NPY_ARRAY_ENSUREARRAY
        NPY_ARRAY_ELEMENTSTRIDES
        NPY_ARRAY_ALIGNED
        NPY_ARRAY_NOTSWAPPED
        NPY_ARRAY_WRITEABLE
        NPY_ARRAY_UPDATEIFCOPY

        NPY_ARRAY_BEHAVED
        NPY_ARRAY_BEHAVED_NS
        NPY_ARRAY_CARRAY
        NPY_ARRAY_CARRAY_RO
        NPY_ARRAY_FARRAY
        NPY_ARRAY_FARRAY_RO
        NPY_ARRAY_DEFAULT

        NPY_ARRAY_IN_ARRAY
        NPY_ARRAY_OUT_ARRAY
        NPY_ARRAY_INOUT_ARRAY
        NPY_ARRAY_IN_FARRAY
        NPY_ARRAY_OUT_FARRAY
        NPY_ARRAY_INOUT_FARRAY

        NPY_ARRAY_UPDATE_ALL
