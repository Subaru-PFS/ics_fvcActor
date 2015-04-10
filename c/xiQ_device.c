//
// xiQ camera library
//

#include <Python.h>
#include "structmember.h"
#include <numpy/arrayobject.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <m3api/xiApi.h>
#include <m3api/xiExt.h>

#define SetError(msg) {                         \
      PyErr_SetString(PyExc_RuntimeError, msg); \
      return NULL;                              \
   }
#define HandleResult(res,msg) if(res!=XI_OK) SetError(msg)

#define MAX_CAMERA_NUMBER 16
#define CAMERA_TIMEOUT 5000
#define IMG_WIDTH 1280
#define IMG_HEIGHT 1024
#define IMG_SIZE IMG_WIDTH * IMG_HEIGHT
#define MAX_ERRSTR_LEN 1024
#define XI_CUSTOM_ERROR 999
#define MAX_STRLEN 255

// xiQ Camera Handler
static HANDLE xiH[MAX_CAMERA_NUMBER];

// Get number of camera devices

static PyObject *xiQ_numberOfCamera(PyObject * self)
{
   uint n_devices;
   int res;

   res = xiGetNumberDevices(&n_devices);
   HandleResult(res, "xiGetNumberDevices failed");
   return Py_BuildValue("i", n_devices);
}

// Open camera device

static PyObject *xiQ_open(PyObject * self, PyObject * args)
{
   int n_dev, res, width, height;

   if(!PyArg_ParseTuple(args, "i", &n_dev))
      return NULL;

   // Open camera device
   if(xiH[n_dev] == NULL) {
      res = xiOpenDevice(n_dev, &xiH[n_dev]);
      HandleResult(res, "xiOpenDevice failed");
   }
   // Check image width
   res = xiGetParamInt(xiH[n_dev], XI_PRM_WIDTH, &width);
   HandleResult(res, "xiGetParamInt failed: XI_PRM_WIDTH");
   if(width != IMG_WIDTH)
      SetError("image width mismatched");

   // Check image height
   res = xiGetParamInt(xiH[n_dev], XI_PRM_HEIGHT, &height);
   HandleResult(res, "xiGetParamInt failed: XI_PRM_HEIGHT");
   if(height != IMG_HEIGHT)
      SetError("image height mismatched");

   // Setting output data format
   res = xiSetParamInt(xiH[n_dev], XI_PRM_IMAGE_DATA_FORMAT, XI_RAW16);
   HandleResult(res, "xiSetParamInt failed: XI_PRM_IMAGE_DATA_FORMAT");

   Py_RETURN_NONE;
}

// Close camera device

static PyObject *xiQ_close(PyObject * self, PyObject * args)
{
   int n_dev;

   if(!PyArg_ParseTuple(args, "i", &n_dev))
      return NULL;
   if(xiH[n_dev]) {
      xiCloseDevice(xiH[n_dev]);
      xiH[n_dev] = NULL;
   }
   Py_RETURN_NONE;
}

// Expose command

static PyObject *xiQ_expose(PyObject * self, PyObject * args)
{
   int n_dev, repeat, res, i, j;
   XI_IMG img;
   npy_intp dims[2] = { IMG_HEIGHT, IMG_WIDTH };
   void *data;
   uint16_t *sptr, *dptr;

   img.size = sizeof(XI_IMG);
   img.bp = NULL;
   img.bp_size = 0;
   repeat = 1;

   if(!PyArg_ParseTuple(args, "i|i", &n_dev, &repeat))
      return NULL;
   if(!xiH[n_dev])
      SetError("camera not found or not opened");

   // allocate memory buffer
   data = malloc(IMG_SIZE * 2);
   if(data == NULL)
      SetError("malloc failed");
   bzero(data, IMG_SIZE * 2);

   // Start acquisition
   res = xiStartAcquisition(xiH[n_dev]);
   HandleResult(res, "xiStartAcquisition failed");

   dptr = data;
   for(i = 0; i < repeat; i++) {
      // Fetch image
      res = xiGetImage(xiH[n_dev], CAMERA_TIMEOUT, &img);
      HandleResult(res, "xiGetImage failed");

      // Stack image
      sptr = img.bp;
      for(j = 0; j < IMG_SIZE; j++)
         dptr[j] += sptr[j];
   }

   // Stop acquisition
   res = xiStopAcquisition(xiH[n_dev]);
   HandleResult(res, "xiStopAcquisition failed");

   return PyArray_SimpleNewFromData(2, dims, PyArray_UINT16, data);
}

// Set exposure parameter

static PyObject *xiQ_setExposure(PyObject * self, PyObject * args)
{
   int n_dev, exptime, res;

   if(!PyArg_ParseTuple(args, "ii", &n_dev, &exptime))
      return NULL;
   if(!xiH[n_dev])
      SetError("camera not found or not opened");

   // Setting "exposure" parameter
   res = xiSetParamInt(xiH[n_dev], XI_PRM_EXPOSURE, exptime);
   HandleResult(res, "xiSetParamInt(XI_PRM_EXPOSURE) failed");

   Py_RETURN_NONE;
}

// Set gain parameter

static PyObject *xiQ_setGain(PyObject * self, PyObject * args)
{
   int n_dev, res;
   float gain;

   if(!PyArg_ParseTuple(args, "if", &n_dev, &gain))
      return NULL;
   if(!xiH[n_dev])
      SetError("camera not found or not opened");

   // Setting "gain" parameter
   res = xiSetParamFloat(xiH[n_dev], XI_PRM_GAIN, gain);
   HandleResult(res, "xiSetParam(XI_PRM_GAIN)");

   Py_RETURN_NONE;
}

// Get exposure parameter

static PyObject *xiQ_getExposure(PyObject * self, PyObject * args)
{
   int n_dev, exptime, res;
   int exp_min, exp_max;

   if(!PyArg_ParseTuple(args, "i", &n_dev))
      return NULL;
   if(!xiH[n_dev])
      SetError("camera not found or not opened");

   // Getting "exposure" parameter
   res = xiGetParamInt(xiH[n_dev], XI_PRM_EXPOSURE, &exptime);
   HandleResult(res, "xiGetParamInt(XI_PRM_EXPOSURE) failed");
   res = xiGetParamInt(xiH[n_dev], XI_PRM_EXPOSURE XI_PRM_INFO_MIN, &exp_min);
   HandleResult(res, "xiGetParamInt(XI_PRM_EXPOSURE XI_PRM_INFO_MIN) failed");
   res = xiGetParamInt(xiH[n_dev], XI_PRM_EXPOSURE XI_PRM_INFO_MAX, &exp_max);
   HandleResult(res, "xiGetParamInt(XI_PRM_EXPOSURE XI_PRM_INFO_MAX) failed");

   return Py_BuildValue("(iii)", exptime, exp_min, exp_max);
}

// Get gain parameter

static PyObject *xiQ_getGain(PyObject * self, PyObject * args)
{
   int n_dev, res;
   float gain, gain_min, gain_max;

   if(!PyArg_ParseTuple(args, "i", &n_dev))
      return NULL;
   if(!xiH[n_dev])
      SetError("camera not found or not opened");

   // Getting "gain" parameter
   res = xiGetParamFloat(xiH[n_dev], XI_PRM_GAIN, &gain);
   HandleResult(res, "xiGetParam(XI_PRM_GAIN)");
   res = xiGetParamFloat(xiH[n_dev], XI_PRM_GAIN XI_PRM_INFO_MIN, &gain_min);
   HandleResult(res, "xiGetParam(XI_PRM_GAIN XI_PRM_INFO_MIN)");
   res = xiGetParamFloat(xiH[n_dev], XI_PRM_GAIN XI_PRM_INFO_MAX, &gain_max);
   HandleResult(res, "xiGetParam(XI_PRM_GAIN XI_PRM_INFO_MAX)");

   return Py_BuildValue("(fff)", gain, gain_min, gain_max);;
}

// Get device name

static PyObject *xiQ_getDevName(PyObject * self, PyObject * args)
{
   int n_dev, res;
   char devname[MAX_STRLEN + 1];

   if(!PyArg_ParseTuple(args, "i", &n_dev))
      return NULL;
   if(!xiH[n_dev])
      SetError("camera not found or not opened");

   // Get device name
   res = xiGetParamString(xiH[n_dev], XI_PRM_DEVICE_NAME, devname, MAX_STRLEN);
   HandleResult(res, "xiGetParam(XI_PRM_DEVICE_NAME)");

   return Py_BuildValue("s", devname);;
}

// Get device serial number

static PyObject *xiQ_getDevSN(PyObject * self, PyObject * args)
{
   int n_dev, res, sn;

   if(!PyArg_ParseTuple(args, "i", &n_dev))
      return NULL;
   if(!xiH[n_dev])
      SetError("camera not found or not opened");

   // Get device name
   res = xiGetParamInt(xiH[n_dev], XI_PRM_DEVICE_SN, &sn);
   HandleResult(res, "xiGetParam(XI_PRM_DEVICE_SN)");

   return Py_BuildValue("i", sn);;
}

// Python module method

static PyMethodDef xiQ_methods[] = {
   {"numberOfCamera", (PyCFunction) xiQ_numberOfCamera, METH_NOARGS,
    "Get the number of available cameras"},
   {"open", (PyCFunction) xiQ_open, METH_VARARGS, "Open camera device"},
   {"close", (PyCFunction) xiQ_close, METH_VARARGS, "Close camera device"},
   {"expose", (PyCFunction) xiQ_expose, METH_VARARGS, "Exposure"},
   {"setExposure", (PyCFunction) xiQ_setExposure, METH_VARARGS,
    "Set expose time in us"},
   {"setGain", (PyCFunction) xiQ_setGain, METH_VARARGS, "Set gain in db"},
   {"getExposure", (PyCFunction) xiQ_getExposure, METH_VARARGS,
    "Get expose time in us"},
   {"getGain", (PyCFunction) xiQ_getGain, METH_VARARGS, "Get gain in db"},
   {"getDevName", (PyCFunction) xiQ_getDevName, METH_VARARGS, "Get device name"},
   {"getDevSN", (PyCFunction) xiQ_getDevSN, METH_VARARGS, "Get device serial number"},
   {NULL, NULL, 0, NULL}
};

#ifndef PyMODINIT_FUNC          /* declarations for DLL import/export */
#define PyMODINIT void
#endif

PyMODINIT_FUNC initxiQ_device(void)
{
   PyObject *m;
   int i;

   for(i = 0; i < MAX_CAMERA_NUMBER; i++)
      xiH[i] = NULL;
   m = Py_InitModule("xiQ_device", xiQ_methods);
   if(m == NULL)
      return;
   import_array();
}
