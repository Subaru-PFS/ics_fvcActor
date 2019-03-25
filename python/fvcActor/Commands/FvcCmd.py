#!/usr/bin/env python

from builtins import object
import os
import astropy.io.fits as pyfits

import opscore.protocols.keys as keys
import opscore.protocols.types as types
from opscore.utility.qstr import qstr

class FvcCmd(object):

    def __init__(self, actor):
        # This lets us access the rest of the actor.
        self.actor = actor

        # Declare the commands we implement. When the actor is started
        # these are registered with the parser, which will call the
        # associated methods when matched. The callbacks will be
        # passed a single argument, the parsed and typed command.
        #
        self.vocab = [
            ('ping', '', self.ping),
            ('status', '', self.status),
            ('reconnect', '', self.reconnect),
            ('expose', '@(bias|test|object) [<nframe>]', self.expose),
            ('setexptime', '<exptime>', self.setExpTime),
            ('setgain', '<gain>', self.setGain),
        ]

        # Define typed command arguments for the above commands.
        self.keys = keys.KeysDictionary("fvc_fvc", (1, 1),
                                        keys.Key("nframe", types.Int(), help="The number of frames for exposure"),
                                        keys.Key("exptime", types.Int(), help="Exposure time(us) for one frame"),
                                        keys.Key("gain", types.Float(), help="Gain in db"),
                                       )

    def ping(self, cmd):
        """Query the actor for liveness/happiness."""

        cmd.finish("text='I am fiber viewing actor'")

    def status(self, cmd):
        """Report camera status and actor version. """

        self.actor.sendVersionKey(cmd)
        
        self.actor.camera.sendStatusKeys(cmd)
        cmd.inform('text="Present!"')
        cmd.finish()

    def reconnect(self, cmd):
        """ reconnect camera device """

        self.actor.connectCamera(cmd)
        cmd.finish('text="camera connected!"')

    def getNextFilename(self, cmd, expType):
        """ Fetch next image filename. 

        In real life, we will instantiate a Subaru-compliant image pathname generating object.  

        """
        
        self.actor.exposureID += 1
        path = os.path.join("$ICS_MHS_DATA_ROOT", 'fvc')
        path = os.path.expandvars(os.path.expanduser(path))

        if not os.path.isdir(path):
            os.makedirs(path, 0o755)
            
        return os.path.join(path, 'FVC_%s_%06d.fits' % (expType, self.actor.exposureID))

    def _doExpose(self, cmd, expType, nframe):
        """ Take an exposure and save it to disk. """
        
        image = self.actor.camera.expose(cmd, expType, nframe)
        filename = self.getNextFilename(cmd, expType)
        self.actor.camera._wfits(filename)
        cmd.inform("filename=%s" % (filename))
        
        return filename, image
            
    def expose(self, cmd):
        """ Take an exposure with multiple frames. """

        cmdKeys = cmd.cmd.keywords
        expType = cmdKeys[0].name
        if expType in ('bias', 'test'):
            nframe = 0
        else:
            nframe = cmdKeys['nframe'].values[0] if 'nframe' in cmdKeys else 1

        filename, image = self._doExpose(cmd, expType, nframe)
        cmd.finish('exposureState="done"')

    def setExpTime(self, cmd):
        """ Set exposure time(us) for one frame """

        exptime = cmd.cmd.keywords['exptime'].values[0]
        self.actor.camera.setExpTime(cmd, exptime)
        cmd.finish()

    def setGain(self, cmd):
        """ Set gain in db """

        gain = cmd.cmd.keywords['gain'].values[0]
        self.actor.camera.setGain(cmd, gain)
        cmd.finish()

