"""XIMEA USB camera library"""

ctypedef unsigned int uint32_t
ctypedef unsigned short uint16_t
ctypedef unsigned char uint8_t
ctypedef uint32_t DWORD
ctypedef DWORD* PDWORD
ctypedef void* LPVOID

cdef extern from "<strings.h>" nogil:
    void bzero(void *, size_t)

cdef extern from "<m3api/xiApi.h>" nogil:
    ctypedef enum XI_PRM_TYPE:
        xiTypeInteger = 0
        xiTypeFloat = 1
        xiTypeString = 2
        xiTypeEnum = 3
        xiTypeBoolean = 4
        xiTypeCommand = 5
        xiTypeInteger64 = 6

    ctypedef enum XI_COLOR_FILTER_ARRAY:
        XI_CFA_NONE = 0
        XI_CFA_BAYER_RGGB = 1
        XI_CFA_CMYG = 2
        XI_CFA_RGR = 3
        XI_CFA_BAYER_BGGR = 4
        XI_CFA_BAYER_GRBG = 5
        XI_CFA_BAYER_GBRG = 6
        XI_CFA_POLAR_A_BAYER_BGGR = 7
        XI_CFA_POLAR_A = 8

    ctypedef enum XI_IMG_FORMAT:
        XI_MONO8 = 0
        XI_MONO16 = 1
        XI_RGB24 = 2
        XI_RGB32 = 3
        XI_RGB_PLANAR = 4
        XI_RAW8 = 5
        XI_RAW16 = 6
        XI_FRM_TRANSPORT_DATA = 7
        XI_RGB48 = 8
        XI_RGB64 = 9
        XI_RGB16_PLANAR = 10
        XI_RAW8X2 = 11
        XI_RAW8X4 = 12
        XI_RAW16X2 = 13
        XI_RAW16X4 = 14
        XI_RAW32 = 15
        XI_RAW32FLOAT = 16

    ctypedef struct XI_IMG_DESC:
        DWORD Area0Left
        DWORD Area1Left
        DWORD Area2Left
        DWORD Area3Left
        DWORD Area4Left
        DWORD Area5Left
        DWORD ActiveAreaWidth
        DWORD Area5Right
        DWORD Area4Right
        DWORD Area3Right
        DWORD Area2Right
        DWORD Area1Right
        DWORD Area0Right
        DWORD Area0Top
        DWORD Area1Top
        DWORD Area2Top
        DWORD Area3Top
        DWORD Area4Top
        DWORD Area5Top
        DWORD ActiveAreaHeight
        DWORD Area5Bottom
        DWORD Area4Bottom
        DWORD Area3Bottom
        DWORD Area2Bottom
        DWORD Area1Bottom
        DWORD Area0Bottom
        DWORD format
        DWORD flags

    ctypedef struct XI_IMG:
        DWORD size
        LPVOID bp
        DWORD bp_size
        XI_IMG_FORMAT frm
        DWORD width
        DWORD height
        DWORD nframe
        DWORD tsSec
        DWORD tsUSec
        DWORD GPI_level
        DWORD black_level
        DWORD padding_x
        DWORD AbsoluteOffsetX
        DWORD AbsoluteOffsetY
        DWORD transport_frm
        XI_IMG_DESC img_desc
        DWORD DownsamplingX
        DWORD DownsamplingY
        DWORD flags
        DWORD exposure_time_us
        float gain_db
        DWORD acq_nframe
        DWORD image_user_data
        DWORD exposure_sub_times_us[5]
        double data_saturation
        float wb_red
        float wb_green
        float wb_blue
        DWORD lg_black_level
        DWORD hg_black_level
        DWORD lg_range
        DWORD hg_range
        float gain_ratio
        float fDownsamplingX
        float fDownsamplingY
        XI_COLOR_FILTER_ARRAY color_filter_array

    ctypedef XI_IMG* LPXI_IMG
    ctypedef int XI_RETURN
    ctypedef void* HANDLE
    ctypedef HANDLE* PHANDLE

    cdef enum:
        XI_OK = 0

    cdef:
        const char* XI_PRM_HEIGHT = "height"
        const char* XI_PRM_WIDTH = "width"
        const char* XI_PRM_EXPOSURE = "exposure"
        const char* XI_PRM_GAIN = "gain"
        const char* XI_PRM_INFO_MIN = ":min"
        const char* XI_PRM_INFO_MAX = ":max"
        const char* XI_PRM_DEVICE_NAME = "device_name"
        const char* XI_PRM_DEVICE_SN = "device_sn"
        const char* XI_PRM_IMAGE_DATA_FORMAT = "imgdataformat"

    XI_RETURN xiGetNumberDevices(DWORD *pNumberDevices)
    XI_RETURN xiOpenDevice(DWORD DevId, PHANDLE hDevice)
    XI_RETURN xiCloseDevice(HANDLE hDevice)
    XI_RETURN xiGetParamInt(HANDLE hDevice, const char* prm, int* val)
    XI_RETURN xiGetParamFloat(HANDLE hDevice, const char* prm, float* val)
    XI_RETURN xiGetParamString(HANDLE hDevice, const char* prm, void* val, DWORD size)
    XI_RETURN xiSetParamInt(HANDLE hDevice, const char* prm, const int val)
    XI_RETURN xiSetParamFloat(HANDLE hDevice, const char* prm, const float val)
    XI_RETURN xiStartAcquisition(HANDLE hDevice)
    XI_RETURN xiGetImage(HANDLE hDevice, DWORD timeout, LPXI_IMG img)
    XI_RETURN xiStopAcquisition(HANDLE hDevice)

cdef enum:
    MAX_CAMERA_NUMBER = 16
    CAMERA_TIMEOUT = 5000
    IMG_WIDTH = 1280
    IMG_HEIGHT = 1024
    IMG_SIZE = IMG_WIDTH * IMG_HEIGHT
    MAX_ERRSTR_LEN = 1024
    XI_CUSTOM_ERROR = 999
    MAX_STRLEN = 255

cdef:
    HANDLE xiH[MAX_CAMERA_NUMBER]


# XI_RAW8
ctypedef uint8_t img_data
cdef enum:
    IMG_DATA_BYTES = 1
    IMG_MODE = XI_RAW8

# XI_RAW16
#ctypedef uint16_t img_data
#cdef enum:
#    IMG_DATA_BYTES = 2
#    IMG_MODE = XI_RAW16
