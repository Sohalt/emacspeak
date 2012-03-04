/*
 * $Id$
 */
//<copyright info

/*
 * Tcl ViaVoiceOutloud Interface program (c) Copyright 1999 by
 * Paige Phault
 *
 * The author hereby grants permission to use, copy, modify,
 * distribute, and license this software for any purpose,
 * provided that existing copyright notices are retained in all
 * copies and that this notice is included verbatim in any
 * distributions. No written agreement, license, or royalty fee
 * is required for any of the authorized uses.  Modifications to
 * this software may be copyrighted by their authors and need
 * not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each
 * file where they apply.
 *
 * IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
 * CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE,
 * ITS DOCUMENTATION, OR ANY DERIVATIVES THEREOF, EVEN IF THE
 * AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE IS PROVIDED ON
 * AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS.
 *
 * dynamic loading of eci library contributed by Jeffrey Sorensen
 * --this allows a compiled version of this speech server to be
 * distributed without violating the IBM Viavoice license. This
 * means that end-users only need install the Viavoice RTK
 * (Runtime toolkit) to use Emacspeak with the ViaVoice TTS
 * engine.
 *
 * February 2005 TVR: Updating to use alsalib output routines
 */

//>
//<Usage:

/*
 * TCL usage package require tts
 *
 * proc index x { puts "I just played index $x" }
 *
 * synth "Hello world" synth -index 0 "This is some" -index 1
 * "really wierd" say -index 2 "text" say -reset
 *
 * The only difference bewtween say and synth is that synth
 * calls eciSynthesize and say doesn't.  You can put as many
 * text blocks as you like after a command.
 */

//>
//<includes

#include <sys/time.h>
#include <dlfcn.h>

#include <alsa/asoundlib.h>
#include <tcl.h>
#include "langswitch.h"

#define PACKAGENAME "tts"
#define PACKAGEVERSION "1.0"
#define ECILIBRARYNAME "libibmeci.so"

//>
//< alsa: globals and defines

#define DEFAULT_FORMAT          SND_PCM_FORMAT_S16
#define DEFAULT_SPEED           11025

/*
 * globals
 */

static snd_pcm_t *AHandle = NULL;
static snd_output_t *Log = NULL;
static snd_pcm_hw_params_t *params;
static snd_pcm_uframes_t buffer_frames = 0;
static int test_position = 0;
static int test_coef = 8;
short          *waveBuffer = NULL;
static snd_pcm_uframes_t chunk_size = 0;
static snd_pcm_uframes_t buffer_size = 0;
static size_t          chunk_bytes = 0;
static size_t bits_per_sample = 0;
static size_t bits_per_frame = 0;

//>
//<decls and function prototypes

/*
 * The following declarations are derived from the publically
 * available documentation for ViaVoice TTS outloud. --they are
 * placed here to obviate the need for having the ViaVoice SDK
 * installed.
 */

typedef enum {
  eciDataNotProcessed, eciDataProcessed
} ECICallbackReturn;


typedef enum {
  eciWaveformBuffer,
  eciPhonemeBuffer,
  eciIndexReply,
  eciPhonemeIndexReply
} ECIMessage;

typedef enum {
  eciSynthMode,
  eciInputType,
  eciTextMode,
  eciDictionary,
  eciSampleRate = 5,
  eciWantPhonemeIndices = 7,
  eciRealWorldUnits,
  eciLanguageDialect,
  eciNumberMode,
  eciPhrasePrediction,
  eciNumParams
} ECIParam;

static void     (*_eciVersion) (char *);
static void    *(*_eciNewEx) (enum ECILanguageDialect);
static int      (*_eciGetAvailableLanguages) (enum
                                              ECILanguageDialect *, int *);
static void     (*_eciDelete) (void *);
static int      (*_eciReset) (void *);
static int      (*_eciStop) (void *);
static int      (*_eciClearInput) (void *);
static int      (*_eciPause) (void *, int);
static int      (*_eciSynthesize) (void *);
static int      (*_eciSynchronize) (void *);
static int      (*_eciSpeaking) (void *);
static int      (*_eciAddText) (void *, char *);
static int      (*_eciInsertIndex) (void *, int);
static int      (*_eciSetParam) (void *, int, int);
static int      (*_eciGetVoiceParam) (void *, int, int);
static int      (*_eciSetVoiceParam) (void *, int, int, int);
static int      (*_eciSetOutputBuffer) (void *, int, short *);
static int      (*_eciSetOutputDevice) (void *, int);
static void     (*_eciRegisterCallback) (void *,
                                         int (*)(void *, int,
                                                 long, void *), void *);
static int      alsa_init();
static size_t   alsa_configure(void);

extern          "C" int Atcleci_Init(Tcl_Interp * interp);

int             SetRate(ClientData, Tcl_Interp *, int, Tcl_Obj * CONST[]);
int             GetRate(ClientData, Tcl_Interp *, int, Tcl_Obj * CONST[]);
int             getTTSVersion(ClientData, Tcl_Interp *, int,
                              Tcl_Obj * CONST[]);
int             showAlsaState(ClientData, Tcl_Interp *, int,
                              Tcl_Obj * CONST[]);
int             Say(ClientData, Tcl_Interp *, int, Tcl_Obj * CONST[]);
int             Stop(ClientData, Tcl_Interp *, int, Tcl_Obj * CONST[]);
int             SpeakingP(ClientData, Tcl_Interp *, int,
                          Tcl_Obj * CONST[]);
int             Synchronize(ClientData, Tcl_Interp *, int,
                            Tcl_Obj * CONST[]);
int             Pause(ClientData, Tcl_Interp *, int, Tcl_Obj * CONST[]);
int             Resume(ClientData, Tcl_Interp *, int, Tcl_Obj * CONST[]);
int             SetLanguage(ClientData, Tcl_Interp *, int,
                            Tcl_Obj * CONST[]);
int             alsa_close();
int             eciCallback(void *, int, long, void *);

//>
//<alsa: set hw and sw params

static          size_t
alsa_configure(void)
{
  //<init:
  
  unsigned int    rate = DEFAULT_SPEED;
  int             err;
  snd_pcm_hw_params_alloca(&params);
  //>
  //<defaults:

  err = snd_pcm_hw_params_any(AHandle, params);
  if (err < 0) {
    fprintf(stderr,
            "PCM: Broken configuration: no configurations available");
    exit(EXIT_FAILURE);
  }
  //>
  //<Format:

  err = snd_pcm_hw_params_set_format(AHandle, params, DEFAULT_FORMAT);
  if (err < 0) {
    fprintf(stderr, "Sample format non available");
    exit(EXIT_FAILURE);
  }
  //>
  //<Channels:

  err = snd_pcm_hw_params_set_channels(AHandle, params, 1);
  if (err < 0) {
    fprintf(stderr, "Channels count non available");
    exit(EXIT_FAILURE);
  }
  //>
  //<Rate:

  err = snd_pcm_hw_params_set_rate_near(AHandle, params, &rate, 0);
  assert(err >= 0);

  //>
  //<Access Mode:
  err = snd_pcm_hw_params_set_access(AHandle, params,
                                     SND_PCM_ACCESS_RW_INTERLEAVED);
  if (err < 0) {
    fprintf(stderr, "Access type not available");
    exit(EXIT_FAILURE);
  }
  //>
  //< Set things explicitly if DEBUG
#ifdef DEBUG

  //<Compute buffer_time:
  unsigned int    period_time = 0;
  unsigned int    buffer_time = 0;
  snd_pcm_uframes_t period_frames = 0;
  // affected by defined buffer_size (e.g. via asoundrc)
  if (buffer_time == 0 && buffer_frames == 0) {
    err = snd_pcm_hw_params_get_buffer_time(params, &buffer_time, 0);
    assert(err >= 0);
    if (buffer_time > 500000)   // usecs
      buffer_time = 500000;
  }
  //>
  //<Compute period_time:

  if (period_time == 0 && period_frames == 0) {
    if (buffer_time > 0)
      period_time = buffer_time / 4;
    else
      period_frames = buffer_frames / 4;
  }
  if (period_time > 0)
    err =
      snd_pcm_hw_params_set_period_time_near(AHandle,
                                             params, &period_time, 0);
  else
    err =
      snd_pcm_hw_params_set_period_size_near(AHandle,
                                             params, &period_frames, 0);
  assert(err >= 0);
  if (buffer_time > 0) {
    err =
      snd_pcm_hw_params_set_buffer_time_near(AHandle,
                                             params, &buffer_time, 0);
  } else {
    err =
      snd_pcm_hw_params_set_buffer_size_near(AHandle,
                                             params, &buffer_frames);
  }
  assert(err >= 0);

  //>
#endif

  //>
  //<Commit hw params:
  err = snd_pcm_hw_params(AHandle, params);
  if (err < 0) {
    fprintf(stderr, "Unable to install hw params:");
    exit(EXIT_FAILURE);
  }
  //>
  //<finalize chunk_size and buffer_size:

  snd_pcm_hw_params_get_period_size(params, &chunk_size, 0);
  snd_pcm_hw_params_get_buffer_size(params, &buffer_size);
  if (chunk_size == buffer_size) {
    fprintf(stderr,
            "Can't use period equal to buffer size (%lu == %lu)",
            chunk_size, buffer_size);
    exit(EXIT_FAILURE);
  }
  //>
  //< If DEBUG: SW Params Configure transfer:

#ifdef DEBUG
  size_t          n;
  snd_pcm_uframes_t xfer_align;
  snd_pcm_uframes_t start_threshold,
    stop_threshold;
  int             start_delay = 5;
  int             stop_delay = 0;
  snd_pcm_sw_params_t *swParams;
  snd_pcm_sw_params_alloca(&swParams);
  snd_pcm_sw_params_current(AHandle, swParams);
  err = snd_pcm_sw_params_get_xfer_align(swParams, &xfer_align);
  if (err < 0) {
    fprintf(stderr, "Unable to obtain xfer align\n");
    exit(EXIT_FAILURE);
  }
  // round up to closest transfer boundary
  n = (buffer_size / xfer_align) * xfer_align;
  if (start_delay <= 0) {
    start_threshold =
      (snd_pcm_uframes_t) (n + (double) rate * start_delay / 1000000);
  } else
    start_threshold =
      (snd_pcm_uframes_t) ((double) rate * start_delay / 1000000);
  if (start_threshold < 1)
    start_threshold = 1;
  if (start_threshold > n)
    start_threshold = n;
  err =
    snd_pcm_sw_params_set_start_threshold(AHandle, swParams,
                                          start_threshold);
  assert(err >= 0);
  if (stop_delay <= 0)
    stop_threshold =
      (snd_pcm_uframes_t) (buffer_size +
                           (double) rate * stop_delay / 1000000);
  else
    stop_threshold =
      (snd_pcm_uframes_t) ((double) rate * stop_delay / 1000000);
  err =
    snd_pcm_sw_params_set_stop_threshold(AHandle, swParams,
                                         stop_threshold);
  assert(err >= 0);

  err = snd_pcm_sw_params_set_xfer_align(AHandle, swParams, xfer_align);
  assert(err >= 0);

  if (snd_pcm_sw_params(AHandle, swParams) < 0) {
    fprintf(stderr, "unable to install sw params:");
    exit(EXIT_FAILURE);
  }
#endif

  //>
  bits_per_sample = snd_pcm_format_physical_width(DEFAULT_FORMAT);
  bits_per_frame = bits_per_sample * 1; // mono
  chunk_bytes = chunk_size * bits_per_frame / 8;
  return chunk_bytes;
}

//>
//<do_test_position, xrun and suspend

static void do_test_position(void)
{
  static long counter = 0;
  static float availsum, delaysum, samples;
  static snd_pcm_sframes_t maxavail, maxdelay;
  static snd_pcm_sframes_t minavail, mindelay;
  static snd_pcm_sframes_t badavail = 0, baddelay = 0;
  snd_pcm_sframes_t outofrange;
  snd_pcm_sframes_t avail, delay;
  int err;

  err = snd_pcm_avail_delay(AHandle, &avail, &delay);
  if (err < 0)
    return;
  outofrange = (test_coef * (snd_pcm_sframes_t)buffer_frames) / 2;
  if (avail > outofrange || avail < -outofrange ||
      delay > outofrange || delay < -outofrange) {
    badavail = avail; baddelay = delay;
    availsum = delaysum = samples = 0;
    maxavail = maxdelay = 0;
    minavail = mindelay = buffer_frames * 16;
    fprintf(stderr, "Suspicious buffer position (%li total): "
            "avail = %li, delay = %li, buffer = %li\n",
            ++counter, (long)avail, (long)delay, (long)buffer_frames);
  } 
}




static void xrun(void)
{
  snd_pcm_status_t *status;
  int res;
	
  snd_pcm_status_alloca(&status);
  if ((res = snd_pcm_status(AHandle, status))<0) {
    fprintf(stderr, "status error: %s", snd_strerror(res));
    return;
  }
  if (snd_pcm_status_get_state(status) == SND_PCM_STATE_XRUN) {
    if ((res = snd_pcm_prepare(AHandle))<0) {
      fprintf(stderr, "xrun: prepare error: %s", snd_strerror(res));
    }
    return;		/* ok, data should be accepted again */
  }
  fprintf(stderr, "read/write error, state = %s", snd_pcm_state_name(snd_pcm_status_get_state(status)));
}


static void suspend(void)
{
  int res;

  fprintf(stderr, "Suspended. Trying resume. "); fflush(stderr);
  while ((res = snd_pcm_resume(AHandle)) == -EAGAIN)
    sleep(1);	/* wait until suspend flag is released */
  if (res < 0) {
    fprintf(stderr, "Failed. Restarting stream. "); fflush(stderr);
    if ((res = snd_pcm_prepare(AHandle)) < 0) {
      fprintf(stderr, "suspend: prepare error: %s", snd_strerror(res));
    }
  }
  fprintf(stderr, "Done.\n");
}



//>
//<alsa: pcm_write

static ssize_t pcm_write(short *data, size_t count)
{
  ssize_t r;
  ssize_t result = 0;

  if (count < chunk_size) {
    snd_pcm_format_set_silence(DEFAULT_FORMAT, data + count * bits_per_frame / 8, (chunk_size - count) * 1);
    count = chunk_size;
  }
  while (count > 0) {
    if (test_position)
      do_test_position();
    r = snd_pcm_writei(AHandle, data, count);
    if (test_position)
      do_test_position();
    if (r == -EAGAIN || (r >= 0 && (size_t)r < count)) {
    } else if (r == -EPIPE) {
      xrun();
    } else if (r == -ESTRPIPE) {
      suspend();
    } else if (r < 0) {
      fprintf(stderr, "write error: %s", snd_strerror(r));
    }
    if (r > 0) {
      result += r;
      count -= r;
      data += r * bits_per_frame / 8;
    }
  }
  return result;
}

//>
//<alsa_init

int
alsa_init()
{
  int             err;
  const char           *device = getenv ("ALSA_DEFAULT");
  if (device == NULL) {
    device = "default";
  }
  if ((err =
       snd_pcm_open(&AHandle, device, SND_PCM_STREAM_PLAYBACK, 0)) < 0) {
    fprintf(stderr, "Playback open error: %s\n", snd_strerror(err));
    exit(1);
  }
  err = snd_output_stdio_attach(&Log, stderr, 0);
  assert(err >= 0);
  chunk_bytes = alsa_configure();
  return chunk_bytes;
}

//>
//<alsa_close

int
alsa_close()
{
  // shut down alsa
  snd_pcm_close(AHandle);
  free(waveBuffer);
  return TCL_OK;
}

//>
//<eciFree

void
TclEciFree(ClientData eciHandle)
{
  _eciDelete(eciHandle);
}

//>
//<tcleci_init

int
Atcleci_Init(Tcl_Interp * interp)
{
  int             rc;
  size_t          chunk_bytes = 0;
  void           *eciHandle;
  void           *eciLib;
  //< configure shared library symbols

  eciLib = dlopen(ECILIBRARYNAME, RTLD_LAZY);
  if (eciLib == NULL) {
    Tcl_AppendResult(interp, "Could not load ",
                     ECILIBRARYNAME,
                     "\n",
                     dlerror(),
                     "\nPlease install the IBM ViaVoice Outloud RTK",
                     NULL);
    return TCL_ERROR;
  }

  _eciVersion =
    (void (*)(char *)) (unsigned long) dlsym(eciLib, "eciVersion");
  _eciGetAvailableLanguages =
    (int (*)(enum ECILanguageDialect *, int *)) (unsigned long)
    dlsym(eciLib, "eciGetAvailableLanguages");
  _eciNewEx = (void *(*)(enum ECILanguageDialect)) (unsigned long)
    dlsym(eciLib, "eciNewEx");
  _eciDelete =
    (void (*)(void *)) (unsigned long) dlsym(eciLib, "eciDelete");
  _eciReset = (int (*)(void *)) (unsigned long) dlsym(eciLib, "eciReset");
  _eciStop = (int (*)(void *)) (unsigned long) dlsym(eciLib, "eciStop");
  _eciClearInput =
    (int (*)(void *)) (unsigned long) dlsym(eciLib, "eciClearInput");
  _eciPause =
    (int (*)(void *, int)) (unsigned long) dlsym(eciLib, "eciPause");
  _eciSynthesize =
    (int (*)(void *)) (unsigned long) dlsym(eciLib, "eciSynthesize");
  _eciSynchronize =
    (int (*)(void *)) (unsigned long) dlsym(eciLib, "eciSynchronize");
  _eciSpeaking =
    (int (*)(void *)) (unsigned long) dlsym(eciLib, "eciSpeaking");
  _eciInsertIndex =
    (int (*)(void *, int)) (unsigned long) dlsym(eciLib,
                                                 "eciInsertIndex");
  _eciAddText =
    (int (*)(void *, char *)) (unsigned long) dlsym(eciLib,
                                                    "eciAddText");
  _eciSetParam =
    (int (*)(void *, int, int)) (unsigned long) dlsym(eciLib,
                                                      "eciSetParam");
  _eciGetVoiceParam = (int (*)(void *, int, int))
    (unsigned long) dlsym(eciLib, "eciGetVoiceParam");
  _eciSetVoiceParam = (int (*)(void *, int, int, int))
    (unsigned long) dlsym(eciLib, "eciSetVoiceParam");
  _eciRegisterCallback = (void
                          (*)(void *,
                              int (*)(void *, int, long,
                                      void *), void *)) (unsigned long)
    dlsym(eciLib, "eciRegisterCallback");
  _eciSetOutputBuffer = (int (*)(void *, int, short *)) (unsigned long)
    dlsym(eciLib, "eciSetOutputBuffer");
  _eciSetOutputDevice =
    (int (*)(void *, int)) (unsigned long) dlsym(eciLib,
                                                 "eciSetOutputDevice");

  //>
  //< check for needed symbols

  int             okay = 1;
  if (!_eciNewEx) {
    okay = 0;
    Tcl_AppendResult(interp, "eciNewEx undef\n", NULL);
  }
  if (!_eciDelete) {
    okay = 0;
    Tcl_AppendResult(interp, "eciDelete undef\n", NULL);
  }
  if (!_eciReset) {
    okay = 0;
    Tcl_AppendResult(interp, "eciReset undef\n", NULL);
  }
  if (!_eciStop) {
    okay = 0;
    Tcl_AppendResult(interp, "eciStop undef\n", NULL);
  }
  if (!_eciClearInput) {
    okay = 0;
    Tcl_AppendResult(interp, "eciClearInput undef\n", NULL);
  }
  if (!_eciPause) {
    okay = 0;
    Tcl_AppendResult(interp, "eciPause undef\n", NULL);
  }
  if (!_eciSynthesize) {
    okay = 0;
    Tcl_AppendResult(interp, "eciSynthesize undef\n", NULL);
  }
  if (!_eciSpeaking) {
    okay = 0;
    Tcl_AppendResult(interp, "eciSpeaking undef\n", NULL);
  }
  if (!_eciInsertIndex) {
    okay = 0;
    Tcl_AppendResult(interp, "eciInsertIndex undef\n", NULL);
  }
  if (!_eciAddText) {
    okay = 0;
    Tcl_AppendResult(interp, "eciAddText undef\n", NULL);
  }
  if (!_eciSetParam) {
    okay = 0;
    Tcl_AppendResult(interp, "eciSetParam undef\n", NULL);
  }
  if (!_eciSetParam) {
    okay = 0;
    Tcl_AppendResult(interp, "eciSetParam undef\n", NULL);
  }
  if (!_eciGetVoiceParam) {
    okay = 0;
    Tcl_AppendResult(interp, "eciGetVoiceParam undef\n", NULL);
  }
  if (!_eciSetVoiceParam) {
    okay = 0;
    Tcl_AppendResult(interp, "eciSetVoiceParam undef\n", NULL);
  }
  if (!_eciRegisterCallback) {
    okay = 0;
    Tcl_AppendResult(interp, "eciRegisterCallback undef\n", NULL);
  }
  if (!_eciSetOutputBuffer) {
    okay = 0;
    Tcl_AppendResult(interp, "eciSetOutputBuffer undef\n", NULL);
  }
  if (!_eciSetOutputDevice) {
    okay = 0;
    Tcl_AppendResult(interp, "eciSetOutputDevice undef\n", NULL);
  }
  if (!_eciGetAvailableLanguages) {
    okay = 0;
    Tcl_AppendResult(interp, "_eciGetAvailableLanguages undef\n", NULL);
  }
  if (!okay) {
    Tcl_AppendResult(interp, "Missing symbols from ",
                     ECILIBRARYNAME, NULL);
    return TCL_ERROR;
  }
  //>
  //<setup package, create tts handle

  if (Tcl_PkgProvide(interp, PACKAGENAME, PACKAGEVERSION) != TCL_OK) {
    Tcl_AppendResult(interp, "Error loading ", PACKAGENAME, NULL);
    return TCL_ERROR;
  }

  static enum ECILanguageDialect aLanguages[LANG_INFO_MAX];
  int             nLanguages = LANG_INFO_MAX;
  _eciGetAvailableLanguages(aLanguages, &nLanguages);

  enum ECILanguageDialect aDefaultLanguage =
    initLanguage(interp, aLanguages, nLanguages);
  if (aDefaultLanguage == NODEFINEDCODESET) {
    Tcl_AppendResult(interp, "No language found", PACKAGENAME, NULL);
    return TCL_ERROR;
  }

  eciHandle = _eciNewEx(aDefaultLanguage);
  if (eciHandle == 0) {
    Tcl_AppendResult(interp, "Could not open text-to-speech engine", NULL);
    return TCL_ERROR;
  }
  //>
  //<initialize alsa
  chunk_bytes = alsa_init();
  //<Finally, allocate waveBuffer

  fprintf(stderr, "allocating %d samples\n", (int)chunk_bytes);
  waveBuffer = (short *) malloc(chunk_bytes * sizeof(short));
  if (waveBuffer == NULL) {
    fprintf(stderr, "not enough memory");
    exit(EXIT_FAILURE);
  }
  //>
  //>
  //<initialize TTS

  if ((_eciSetParam(eciHandle, eciInputType, 1) == -1)
      || (_eciSetParam(eciHandle, eciSynthMode, 1) == -1)
      || (_eciSetParam(eciHandle, eciSampleRate, 1) == -1)) {
    Tcl_AppendResult(interp, "Could not initialized tts", NULL);
    _eciDelete(eciHandle);
    return TCL_ERROR;
  }
  _eciRegisterCallback(eciHandle, eciCallback, interp);

  //>
  //<set output to buffer

  rc = _eciSynchronize(eciHandle);
  if (!rc) {
    Tcl_AppendResult(interp, "Error  resetting TTS engine.\n", NULL);
    return TCL_ERROR;
  }
  rc = _eciSetOutputBuffer(eciHandle, chunk_bytes, waveBuffer);
  if (!rc) {
    Tcl_AppendResult(interp, "Error setting output buffer.\n", NULL);
    return TCL_ERROR;
  }
  fprintf(stderr,
          "output buffered to waveBuffer with size %d\n", (int) chunk_bytes);

  //>
  //<register tcl commands

  Tcl_CreateObjCommand(interp, "setRate", SetRate,
                       (ClientData) eciHandle, TclEciFree);
  Tcl_CreateObjCommand(interp, "getRate", GetRate,
                       (ClientData) eciHandle, TclEciFree);
  Tcl_CreateObjCommand(interp, "ttsVersion", getTTSVersion,
                       (ClientData) eciHandle, TclEciFree);
  Tcl_CreateObjCommand(interp, "alsaState", showAlsaState,
                       (ClientData) NULL, TclEciFree);
  Tcl_CreateObjCommand(interp, "say", Say,
                       (ClientData) eciHandle, TclEciFree);
  Tcl_CreateObjCommand(interp, "synth", Say, (ClientData) eciHandle, NULL);
  Tcl_CreateObjCommand(interp, "synchronize", Synchronize,
                       (ClientData) eciHandle, TclEciFree);
  Tcl_CreateObjCommand(interp, "stop", Stop,
                       (ClientData) eciHandle, TclEciFree);
  Tcl_CreateObjCommand(interp, "speakingP", SpeakingP,
                       (ClientData) eciHandle, TclEciFree);
  Tcl_CreateObjCommand(interp, "pause", Pause,
                       (ClientData) eciHandle, TclEciFree);
  Tcl_CreateObjCommand(interp, "resume", Resume,
                       (ClientData) eciHandle, TclEciFree);
  Tcl_CreateObjCommand(interp, "setLanguage", SetLanguage,
                       (ClientData) eciHandle, TclEciFree);
  //>
  //<set up index processing

  rc = Tcl_Eval(interp, "proc index x {global tts; \
set tts(last_index) $x}");

  //>
  return TCL_OK;
}

//>
//<playTTS

int
playTTS(int count)
{
  pcm_write(waveBuffer, count);
  return eciDataProcessed;
}

//>
//<eciCallBack

int
eciCallback(void *eciHandle, int msg, long lparam, void *data)
{
  int             rc;
  Tcl_Interp     *interp = (Tcl_Interp *) data;
  if (msg == eciIndexReply) {
    char            buffer[128];
    snprintf(buffer, 128, "index %ld", lparam);
    rc = Tcl_Eval(interp, buffer);
    if (rc != TCL_OK)
      Tcl_BackgroundError(interp);
  } else if ((msg == eciWaveformBuffer) && (lparam > 0)) {
    playTTS(lparam);
  }
  return 1;
}

//>
//<getRate, setRate

int
GetRate(ClientData eciHandle, Tcl_Interp * interp,
        int objc, Tcl_Obj * CONST objv[])
{
  int             rc,
    rate,
    voice;
  if (objc != 2) {
    Tcl_AppendResult(interp, "Usage: getRate voiceCode  ", TCL_STATIC);
    return TCL_ERROR;
  }
  rc = Tcl_GetIntFromObj(interp, objv[1], &voice);
  if (rc != TCL_OK)
    return rc;
  rate = _eciGetVoiceParam(eciHandle, voice, 6 /* eciSpeed */ );
  Tcl_SetObjResult(interp, Tcl_NewIntObj(rate));
  return TCL_OK;
}

int
SetRate(ClientData eciHandle, Tcl_Interp * interp,
        int objc, Tcl_Obj * CONST objv[])
{
  int             rc,
    rate,
    voice;
  if (objc != 3) {
    Tcl_AppendResult(interp,
                     "Usage: setRate voiceCode speechRate ", TCL_STATIC);
    return TCL_ERROR;
  }
  rc = Tcl_GetIntFromObj(interp, objv[1], &voice);
  if (rc != TCL_OK)
    return rc;
  rc = Tcl_GetIntFromObj(interp, objv[2], &rate);
  if (rc != TCL_OK)
    return rc;
  rc = _eciSetVoiceParam(eciHandle, voice, 6 /* eciSpeed */ ,
                         rate);
  if (rc == -1) {
    Tcl_AppendResult(interp, "Could not set rate", TCL_STATIC);
    return TCL_ERROR;
  }
  // fprintf(stderr, "setRate returned %d\n", rc);
  rate = _eciGetVoiceParam(eciHandle, voice, 6 /* eciSpeed */ );
  fprintf(stderr,
          "eciGetVoiceParam returned %d for voice %d \n", rate, voice);
  return TCL_OK;
}

//>
//<say

int
Say(ClientData eciHandle, Tcl_Interp * interp,
    int objc, Tcl_Obj * CONST objv[])
{
  int             i,
    rc,
    index,
    length;
  for (i = 1; i < objc; i++) {
    // if string begins with -, assume it is an index value
    char           *txt = Tcl_GetStringFromObj(objv[i], &length);
    if (Tcl_StringMatch(txt, "-reset")) {
      _eciReset(eciHandle);
      if ((_eciSetParam(eciHandle, eciInputType, 1) == -1)
          || (_eciSetParam(eciHandle, eciSynthMode, 1) == -1)
          || (_eciSetParam(eciHandle, eciSampleRate, 1) == -1)) {
        Tcl_AppendResult(interp, "Could not re-initialized tts", NULL);
        return TCL_ERROR;
      }
    } else if (Tcl_StringMatch(txt, "-index")) {
      i++;
      if (i == objc) {
        Tcl_AppendResult(interp, "missing index parameter", TCL_STATIC);
        return TCL_ERROR;
      }
      rc = Tcl_GetIntFromObj(interp, objv[i], &index);
      if (rc != TCL_OK)
        return rc;
      rc = _eciInsertIndex(eciHandle, index);
      if (!rc) {
        Tcl_AppendResult(interp, "Could not insert index", TCL_STATIC);
        return TCL_ERROR;
      }
    } else {
      char           *dest = convertFromUTF8(interp,
                                             Tcl_GetStringFromObj(objv[i],
                                                                  NULL));
      if (dest) {
        rc = _eciAddText(eciHandle, dest);
        free(dest);
        if (!rc) {
          Tcl_SetResult(interp, const_cast<char*>("Internal tts error"), TCL_STATIC);
          return TCL_ERROR;
        }
      }
    }
  }
  if (Tcl_StringMatch(Tcl_GetStringFromObj(objv[0], NULL), "synth")) {
    rc = _eciSynthesize(eciHandle);
    if (!rc) {
      Tcl_SetResult(interp, const_cast<char*>("Internal tts synth error"), TCL_STATIC);
      return TCL_ERROR;
    }
  }
  return TCL_OK;
}

//>
//<stop, pause, resume

//<synchronize, stop

int
Synchronize(ClientData eciHandle,
            Tcl_Interp * interp, int objc, Tcl_Obj * CONST objv[])
{
  int             rc = _eciSynchronize(eciHandle);
  if (!rc) {
    Tcl_SetResult(interp, const_cast<char*>("Internal tts synth error"), TCL_STATIC);
    return TCL_ERROR;
  }
  return TCL_OK;
}

int
Stop(ClientData eciHandle,
     Tcl_Interp * interp, int objc, Tcl_Obj * CONST objv[])
{
  if (_eciStop(eciHandle)) {
    snd_pcm_drop(AHandle);
    snd_pcm_prepare(AHandle);
    return TCL_OK;
  }
  Tcl_SetResult(interp, const_cast<char*>("Could not stop synthesis"), TCL_STATIC);
  return TCL_ERROR;
}

//>

int
SpeakingP(ClientData eciHandle, Tcl_Interp * interp, int objc,
          Tcl_Obj * CONST objv[])
{
  if (_eciSpeaking(eciHandle)) {
    Tcl_SetObjResult(interp, Tcl_NewIntObj(1));
  } else {
    Tcl_SetObjResult(interp, Tcl_NewIntObj(0));
  }
  return TCL_OK;
}

int
Pause(ClientData eciHandle, Tcl_Interp * interp, int objc,
      Tcl_Obj * CONST objv[])
{
  if (_eciPause(eciHandle, 1))
    return TCL_OK;
  Tcl_SetResult(interp, const_cast<char*>("Could not pause synthesis"), TCL_STATIC);
  return TCL_ERROR;
}

int
Resume(ClientData eciHandle, Tcl_Interp * interp, int objc,
       Tcl_Obj * CONST objv[])
{
  if (_eciPause(eciHandle, 0))
    return TCL_OK;
  Tcl_SetResult(interp, const_cast<char*>("Could not resume synthesis"), TCL_STATIC);
  return TCL_ERROR;
}

//>
//<getVersion

int
getTTSVersion(ClientData eciHandle, Tcl_Interp * interp,
              int objc, Tcl_Obj * CONST objv[])
{
  char           *version = (char *) malloc(16);
  if (objc != 1) {
    Tcl_AppendResult(interp, "Usage: ttsVersion   ", TCL_STATIC);
    return TCL_ERROR;
  }
  _eciVersion(version);
  Tcl_SetResult(interp, version, TCL_STATIC);
  return TCL_OK;
}

//>
//<show alsa state

int
showAlsaState(ClientData eciHandle, Tcl_Interp * interp,
              int objc, Tcl_Obj * CONST objv[])
{
  if (objc != 1) {
    Tcl_AppendResult(interp, "Usage: alsaState   ", TCL_STATIC);
    return TCL_ERROR;
  }
  snd_pcm_dump(AHandle, Log);
  return TCL_OK;
}

//>
//<SetLanguage

int
SetLanguage(ClientData eciHandle, Tcl_Interp * interp,
            int objc, Tcl_Obj * CONST objv[])
{
  int             aIndex;
  const char     *code = getAnnotation(interp, &aIndex);
  if (code) {
    int             rc;
    char            buffer[ANNOTATION_MAX_SIZE];
    snprintf(buffer, ANNOTATION_MAX_SIZE, "`l%s", code);
    rc = _eciAddText(eciHandle, buffer);
  }
  return TCL_OK;
}

//>
//<end of file
// local variables:
// folded-file: t
// end:
//>
