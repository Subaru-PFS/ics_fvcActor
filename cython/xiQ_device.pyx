"""XIMEA USB camera module"""

from libc.stdlib cimport malloc, free
from libc.string cimport strcpy, strcat
from cython.view cimport array
import numpy as np

def HandleResult(res, msg):
    if res != XI_OK:
        raise RuntimeError(msg)

def numberOfCamera():
    cdef DWORD n_devices
    cdef XI_RETURN res

    with nogil:
        res = xiGetNumberDevices(&n_devices)
    HandleResult(res, "xiGetNumberDevices failed");
    return n_devices

def open(id):
    cdef int n_dev, res, width, height

    n_dev = id
    if xiH[n_dev] != NULL:
        return

    # Open camera device
    with nogil:
        res = xiOpenDevice(n_dev, &xiH[n_dev])
    HandleResult(res, "xiOpenDevice failed")

    # Check image width
    with nogil:
        res = xiGetParamInt(xiH[n_dev], XI_PRM_WIDTH, &width)
    HandleResult(res, "xiGetParamInt failed: XI_PRM_WIDTH")
    if width != IMG_WIDTH:
        raise RuntimeError("image width mismatched")

    # Check image height
    with nogil:
        res = xiGetParamInt(xiH[n_dev], XI_PRM_HEIGHT, &height)
    HandleResult(res, "xiGetParamInt failed: XI_PRM_HEIGHT")
    if height != IMG_HEIGHT:
        raise RuntimeError("image height mismatched")

    # Setting output data format
    with nogil:
        res = xiSetParamInt(xiH[n_dev], XI_PRM_IMAGE_DATA_FORMAT, IMG_MODE)
    HandleResult(res, "xiSetParamInt failed: XI_PRM_IMAGE_DATA_FORMAT")

def close(id):
    cdef int n_dev

    n_dev = id
    if xiH[n_dev] != NULL:
        with nogil:
            xiCloseDevice(xiH[n_dev])
        xiH[n_dev] = NULL

def expose(id, repeat=1):
    cdef int n_dev, res, i, j
    cdef XI_IMG img
    cdef void *data
    cdef img_data *sptr
    cdef img_data *dptr
    cdef img_data[:, ::1] mv

    img.size = sizeof(XI_IMG)
    img.bp = NULL
    img.bp_size = 0

    n_dev = id
    if xiH[n_dev] == NULL:
        raise RuntimeError("camera not found or not opened")

    # allocate memory buffer
    data = malloc(IMG_SIZE * IMG_DATA_BYTES)
    if data == NULL:
        raise RuntimeError("malloc failed")
    bzero(data, IMG_SIZE * IMG_DATA_BYTES)

    # Start acquisition
    with nogil:
        res = xiStartAcquisition(xiH[n_dev])
    HandleResult(res, "xiStartAcquisition failed")

    dptr = <img_data *>data
    for i in range(repeat):
        # Fetch image
        with nogil:
            res = xiGetImage(xiH[n_dev], CAMERA_TIMEOUT, &img)
        HandleResult(res, "xiGetImage failed")

        # Stack image
        sptr = <img_data *>img.bp
        for j in range(IMG_SIZE):
            dptr[j] += sptr[j]

    # Stop acquisition
    with nogil:
        res = xiStopAcquisition(xiH[n_dev])
    HandleResult(res, "xiStopAcquisition failed")

    mv = <img_data[:IMG_HEIGHT, :IMG_WIDTH]> data
    return np.asarray(mv)

def setExposure(id, exptime):
    cdef int res, n_dev, _exptime

    n_dev = id
    _exptime = exptime
    if xiH[n_dev] == NULL:
        raise RuntimeError("camera not found or not opened")

    # Setting "exposure" parameter
    with nogil:
        res = xiSetParamInt(xiH[n_dev], XI_PRM_EXPOSURE, _exptime)
    HandleResult(res, "xiSetParamInt(XI_PRM_EXPOSURE) failed")

def setGain(id, gain):
    cdef int res, n_dev
    cdef float _gain

    n_dev = id
    _gain = gain
    if xiH[n_dev] == NULL:
        raise RuntimeError("camera not found or not opened")

    # Setting "gain" parameter
    with nogil:
        res = xiSetParamFloat(xiH[n_dev], XI_PRM_GAIN, _gain)
    HandleResult(res, "xiSetParam(XI_PRM_GAIN)")

def getExposure(id):
    cdef int n_dev, exptime, res
    cdef int exp_min, exp_max
    cdef char buffer[MAX_STRLEN + 1]

    n_dev = id
    if xiH[n_dev] == NULL:
        raise RuntimeError("camera not found or not opened")

    # Getting "exposure" parameter
    with nogil:
        res = xiGetParamInt(xiH[n_dev], XI_PRM_EXPOSURE, &exptime)
    HandleResult(res, "xiGetParamInt(XI_PRM_EXPOSURE) failed")

    with nogil:
        strcpy(buffer, XI_PRM_EXPOSURE)
        strcat(buffer, XI_PRM_INFO_MIN)
        res = xiGetParamInt(xiH[n_dev], buffer, &exp_min)
    HandleResult(res, "xiGetParamInt(XI_PRM_EXPOSURE XI_PRM_INFO_MIN) failed")

    with nogil:
        strcpy(buffer, XI_PRM_EXPOSURE)
        strcat(buffer, XI_PRM_INFO_MAX)
        res = xiGetParamInt(xiH[n_dev], buffer, &exp_max)
    HandleResult(res, "xiGetParamInt(XI_PRM_EXPOSURE XI_PRM_INFO_MAX) failed")

    return exptime, exp_min, exp_max

def getGain(id):
    cdef int n_dev, res
    cdef float gain, gain_min, gain_max
    cdef char buffer[MAX_STRLEN + 1]

    n_dev = id
    if xiH[n_dev] == NULL:
        raise RuntimeError("camera not found or not opened")

    # Getting "gain" parameter
    with nogil:
        res = xiGetParamFloat(xiH[n_dev], XI_PRM_GAIN, &gain);
    HandleResult(res, "xiGetParam(XI_PRM_GAIN)");

    with nogil:
        strcpy(buffer, XI_PRM_GAIN)
        strcat(buffer, XI_PRM_INFO_MIN)
        res = xiGetParamFloat(xiH[n_dev], buffer, &gain_min)
    HandleResult(res, "xiGetParam(XI_PRM_GAIN XI_PRM_INFO_MIN)")

    with nogil:
        strcpy(buffer, XI_PRM_GAIN)
        strcat(buffer, XI_PRM_INFO_MAX)
        res = xiGetParamFloat(xiH[n_dev], buffer, &gain_max)
    HandleResult(res, "xiGetParam(XI_PRM_GAIN XI_PRM_INFO_MAX)")

    return gain, gain_min, gain_max

def getDevName(id):
    cdef int n_dev, res
    cdef char devname[MAX_STRLEN + 1]

    n_dev = id
    if xiH[n_dev] == NULL:
        raise RuntimeError("camera not found or not opened")

    # Get device name
    with nogil:
        res = xiGetParamString(xiH[n_dev], XI_PRM_DEVICE_NAME, devname, MAX_STRLEN)
    HandleResult(res, "xiGetParam(XI_PRM_DEVICE_NAME)")

    return devname

def getDevSN(id):
    cdef int n_dev, res, sn

    n_dev = id
    if xiH[n_dev] == NULL:
        raise RuntimeError("camera not found or not opened")

    # Get device name
    with nogil:
        res = xiGetParamInt(xiH[n_dev], XI_PRM_DEVICE_SN, &sn)
    HandleResult(res, "xiGetParam(XI_PRM_DEVICE_SN)")

    return sn


for n_dev in range(MAX_CAMERA_NUMBER):
    xiH[n_dev] = NULL
