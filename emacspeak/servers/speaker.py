#!/usr/bin/env python
"""Python wrapper for Emacspeak speech servers.

The emacspeak TTS server provides a simple but powerful and
well-tested speech-server abstraction. That server is implemented
as an external program (typically in TCL).  This wrapper class
provides Python access to available Emacspeak speech servers.

Initially, this class will provide Python access to the TTS
server commands.  Over time, this module may also implement
functionality present in Emacspeak's Lisp layer ---specifically,
higher level TTS functionality provided by the following
emacspeak modules:

0)  dtk-speak.el

1)  emacspeak-pronounce.el

2)  accs-structure.el

"""

__id__ = "$Id$"
__author__ = "$Author$"
__version__ = "$Revision$"
__date__ = "$Date$"
__copyright__ = "Copyright (c) 2005 T. V. Raman"
__license__ = "GPL"

import os, sys

class Speaker:
    
    """Provides speech servre abstraction.

    Class variable location specifies directory where Emacspeak
    speech servers are installed.

    Class variable config is a dictionary of default settings.
    
    Speaker objects can be initialized with the following
    parameters:

    engine -- TTS server to instantiate. Default: outloud
    host -- Host that runs   server. Default: localhost
    settings -- Dictionary of default settings.
    
    """

    location="/usr/share/emacs/site-lisp/emacspeak/servers"

    config = {'splitcaps' : 1,
              'rate' : 100,
    'capitalize' : 0,
    'allcaps' : 0,
    'punctuations' : 'all'
    }
    
    def __init__ (self,
                  engine='outloud',
                  host='localhost',
                  initial=config):
        """Launches speech engine."""
        self.__engine =engine
        if host == 'localhost':
            self.__server = os.path.join(Speaker.location, self.__engine)
        else:
            self.__server = os.path.join(Speaker.location,
                                         "ssh-%s" % self.__engine)
        self.__handle = os.popen(self.__server,"w")
        self.__handle.flush()
        self.__settings ={}
        if initial is not None:
            self.__settings.update(initial)
            self.configure(self.__settings)

    def configure(self, settings):
        """Configure engine with settings."""
        for k in settings.keys():
            if hasattr(self, k) and callable(getattr(self,k)):
                getattr(self,k)(settings[k])

    def settings(self): return self.__settings
    
    def say(self, text=""):
        """Speaks specified text. All queued text is spoken immediately."""
        self.__handle.write("q {%s}\nd\n" %text)
        self.__handle.flush()

    def speak(self):
        """Forces queued text to be spoken."""
        self.__handle.write("d\n")
        self.__handle.flush()

    def sayUtterances(self, list):
        """Speak list of utterances."""
        for t in list: self.__handle.write("q { %s }\n" %str(t))
        self.__handle.write("d\n")
        self.__handle.flush()
    
    def letter (self, l):
        """Speak single character."""
        self.__handle.write("l {%s}\n" %l)
        self.__handle.flush()

    def tone(self, pitch=440, duration=50):
        """Queue specified tone."""
        self.__handle.write("t %s %s\n " % (pitch, duration))
        self.__handle.flush()

    def silence( self, duration=50):
        """Queue specified silence."""
        self.__handle.write("sh  %s" %  duration)
        self.__handle.flush()
    
    def addText(self, text=""):
        """Queue text to be spoken.
        Output is produced by next call to say() or speak()."""
        self.__handle.write("q {%s}\n" %text)

    def stop(self):
        """Silence ongoing speech."""
        self.__handle.write("s\n")
        self.__handle.flush()

    def shutdown(self):
        """Shutdown speech engine."""
        self.__handle.close()
        sys.stderr.write("shut down TTS\n")
    
    def reset(self):
        """Reset TTS engine."""
        self.__handle.write("tts_reset\n")
        self.__handle.flush()
    
    def version(self):
        """Speak TTS version info."""
        self.__handle.write("version\n")
        self.__handle.flush()

    def punctuations(self, mode):
        """Set punctuation mode."""
        if mode in ['all', 'some', 'none']:
            self.__settings['punctuations'] = mode
            self.__handle.write("tts_set_punctuations %s\n" % mode)
            self.__handle.flush()

    def rate(self, r):
        """Set speech rate."""
        self.__settings['rate'] = r
        self.__handle.write("tts_set_speech_rate %s\n" % r)
        self.__handle.flush()

    def splitcaps(self, flag):
        """Set splitcaps mode. 1  turns on, 0 turns off"""
        flag = bool(flag) and 1 or 0
        self.__settings['splitcaps'] = flag
        self.__handle.write("tts_split_caps %s\n" % flag)
        self.__handle.flush()

    def capitalize(self, flag):
        """Set capitalization  mode. 1  turns on, 0 turns off"""
        flag = bool(flag) and 1 or 0
        self.__settings['capitalize'] = flag
        self.__handle.write("tts_capitalize %s\n" % flag)
        self.__handle.flush()

    def allcaps(self, flag):
        """Set allcaps  mode. 1  turns on, 0 turns off"""
        flag = bool(flag) and 1 or 0
        self.__settings['allcaps'] = flag
        self.__handle.write("tts_allcaps_beep %s\n" % flag)
        self.__handle.flush()
    
if __name__=="__main__":
    import time
    s=Speaker()
    s.addText(range(10))
    s.speak()
    print "sleeping  while waiting for speech to complete."
    time.sleep(7)
    s.shutdown()
