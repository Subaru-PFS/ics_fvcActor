import numpy
from time import localtime, strftime
import time
import pyfits
import xiQ_device as xiQ

def numberOfCamera():
    """Get the number of available cameras"""
    return xiQ.numberOfCamera()

class Camera(object):
    """XIMEA xiQ USB camera"""

    def __init__(self, id=0, exptime=-1, gain=-1.0):
        """(id) : index of the camera device"""

        self.id = id
        self.nframe = 1
        self.timestamp = ''
        self.data = numpy.array([], dtype = numpy.uint16)
        self.imageSize = (1024, 1280)
        self.imtype = ''
        self._open()
        self.devname = xiQ.getDevName(self.id)
        self.devsn = hex(xiQ.getDevSN(self.id))[2:]
        self._getGain()
        self._getExpTime()
        if exptime > 0:
            self._setExpTime(exptime)
        if gain > 0:
            self._setGain(gain)

    def _open(self):
        """Open camera device"""

        xiQ.open(self.id)

    def _close(self):
        """Close camera device"""

        xiQ.close(self.id)

    def _setExpTime(self, exptime):
        """Set exposure time in us"""

        xiQ.setExposure(self.id, exptime)
        self.exptime = exptime

    def _getExpTime(self):
        """Get exposure time(current, min, max) in us"""

        (self.exptime, self.minexptime, self.maxexptime) = xiQ.getExposure(self.id)
        return self.exptime

    def _setGain(self, gain):
        """Set gain in db"""

        xiQ.setGain(self.id, gain)
        self.gain = gain

    def _getGain(self):
        """Get gain(current, min, max) in db"""

        (self.gain, self.mingain, self.maxgain) = xiQ.getGain(self.id)
        return self.gain

    def _expose(self, nframe=1):
        """Take (nframe) exposures and return the summed image"""

        self.nframe = nframe
        self.timestamp = strftime("%Y-%m-%dT%H:%M:%S", localtime())
        self.data = xiQ.expose(self.id, nframe)
        return self.data

    def _wfits(self, filename):
        """Write image to a FITS file"""

        if(self.data.size == 0):
            print "No image available"
            return
        hdu = pyfits.PrimaryHDU(self.data)
        hdr = hdu.header
        hdr.update('DATE', self.timestamp, 'file creation date (local)')
        hdr.update('INSTRUME', 'XIMEA %s SN%s' % (self.devname, self.devsn),
                                  'instrument used to acquire image')
        if self.imtype == 'object':
            hdr.update('EXPTIME', self.exptime, 'exposure time (us)')
        elif self.imtype == 'bias':
            hdr.update('EXPTIME', self.minexptime, 'exposure time (us)')
        else:
            hdr.update('EXPTIME', 0, 'exposure time (us)')
        hdr.update('NFRAME', self.nframe, 'number of frames')
        hdr.update('GAIN', self.gain, 'gain in db')
        hdr.update('IMTYPE', self.imtype, 'exposure type')
        hdu.writeto(filename, checksum=True, clobber=True)

    def sendStatusKeys(self, cmd):
        """ Send our status keys to the given command. """ 

        cmd.inform('model="XIMEA %s"  SN="%s"' % (self.devname, self.devsn))
        cmd.inform('exptime=%dus  gain=%.2fdb' % (self.exptime, self.gain))

    def expose(self, cmd, expType, nframe = 1):
        """ Generate an 'exposure' image.

        Args:
           cmd     - a Command object to report to. Ignored if None.
           expType - ("bias", "object", "test")
           nframe  - number of frames for exposure
           
        Returns:
           - the image.

        Keys:
           exposureState
        """

        if not expType:
            expType = 'test'
        self.imtype = expType
        if cmd:
            cmd.inform('exposureState="exposing"')
        if expType == 'object':
            self._expose(nframe)
            cmd.inform('exptime=%dus nframe=%d gain=%.2fdb' % (self.exptime, nframe, self.gain))
        elif expType == 'bias':
            oexptime = self.exptime
            self._setExpTime(self.minexptime)
            self._expose(1)
            self._setExpTime(oexptime)
            cmd.inform('exptime=%dus gain=%.2fdb' % (self.minexptime, self.gain))
        else:
            self.data = numpy.ones(shape=self.imageSize).astype('u2')

        return self.data

    def setExpTime(self, cmd, exptime):
        """Set exposure time in us"""

        if exptime < self.minexptime:
            """ Exposure time is too small """
            cmd.fail('text="exosure time too small %d < %d"' %
                     (exptime, self.minexptime))
        elif exptime > self.maxexptime:
            """ Exposure time is too large """
            cmd.fail('text="exosure time too large %d > %d"' %
                     (exptime, self.maxexptime))
        else:
            self._setExpTime(exptime)
            cmd.inform('exptime=%dus' % exptime)

    def setGain(self, cmd, gain):
        """Set gain in db"""

        if gain < self.mingain:
            """ Exposure time is too small """
            cmd.fail('text="gain too small %.2f < %.2f"' %
                     (gain, self.mingain))
        elif gain > self.maxgain:
            """ Exposure time is too large """
            cmd.fail('text="gain too large %.2f > %.2f"' %
                     (gain, self.maxgain))
        else:
            self._setGain(gain)
            cmd.inform('gain=%.2fdb"' % self.gain)

