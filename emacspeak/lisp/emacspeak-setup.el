;;; emacspeak-setup.el --- Setup Emacspeak environment --loaded to start Emacspeak
;;; $Id$
;;; $Author$ 
;;; Description:  File for setting up and starting Emacspeak
;;; Keywords: Emacspeak, Setup, Spoken Output
;;{{{  LCD Archive entry: 
;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date$ |
;;;  $Revision$ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2001, T. V. Raman 
;;; Copyright (c) 1994, 1995 by Digital Equipment Corporation.
;;; All Rights Reserved. 
;;;
;;; This file is not part of GNU Emacs, but the same permissions apply.
;;;
;;; GNU Emacs is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 2, or (at your option)
;;; any later version.
;;;
;;; GNU Emacs is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'custom)
(eval-when (compile)
  (require 'emacspeak-speak))
(defvar emacspeak-unibyte t
  "Emacspeak will force emacs to unibyte unless this
variable is set to nil.
To use emacspeak with emacs running in multibyte mode, this
variable should be set to nil *before* 
emacspeak is compiled or started.")

(defvar emacspeak-directory
  (expand-file-name  "/home/tvraman/emacs/lisp/emacspeak")
  "Directory where emacspeak is installed. ")

(defvar emacspeak-lisp-directory
  (expand-file-name  "lisp/" emacspeak-directory)
  "Directory where emacspeak lisp files are  installed. ")

(defvar emacspeak-sounds-directory
  (expand-file-name  "sounds/" emacspeak-directory)
  "Directory containing auditory icons for Emacspeak.")

(defvar emacspeak-etc-directory
  (expand-file-name  "etc/" emacspeak-directory)
  "Directory containing miscellaneous files  for
  Emacspeak.")

(defvar emacspeak-servers-directory
  (expand-file-name  "servers/" emacspeak-directory)
  "Directory containing speech servers  for
  Emacspeak.")

(defvar emacspeak-info-directory
  (expand-file-name  "info/" emacspeak-directory)
  "Directory containing  Emacspeak info files.")
(defcustom emacspeak-play-program
  (cond
   ((getenv "EMACSPEAK_PLAY_PROGRAM"))
   ((file-exists-p "/usr/bin/play") "/usr/bin/play")
   ((file-exists-p "/usr/bin/audioplay") "/usr/bin/audioplay")
   ((file-exists-p "/usr/demo/SOUND/play") "/usr/demo/SOUND/play")
   (t (expand-file-name emacspeak-etc-directory "play")))
  "Name of executable that plays sound files. "
  :group 'emacspeak
  :type 'string)

(defvar emacspeak-resource-directory (expand-file-name "~/.emacspeak/")
  "Directory where Emacspeak resource files such as
pronunciation dictionaries are stored. ")



(defcustom outloud-default-speech-rate 50
  "Default speech rate for outloud."
  :group 'tts
:type 'integer)

(defcustom dtk-default-speech-rate 225
  "*Default speech rate at which TTS is started. "
  :group 'tts
  :type 'integer)

(defvar tts-default-speech-rate dtk-default-speech-rate
  "Setup on a per engine basis.")

(unless (featurep 'emacspeak)
  (setq load-path
        (cons emacspeak-lisp-directory 
              load-path )))
(defconst  emacspeak-xemacs-p
  (when
  (or (boundp 'running-xemacs)
   (string-match "Lucid\\|XEmacs" emacs-version))
  t)
"T if we are running under XEmacs.")

(load-library "emacspeak")
(defvar dtk-startup-hook nil)

(add-hook 'dtk-startup-hook 
          (function (lambda () 
                      (dtk-set-rate tts-default-speech-rate  t))))
(defvar emacspeak-startup-hook nil)

;;; Use (add-hook 'emacspeak-startup-hook ...)
;;; to add your personal settings. 
(emacspeak)
;;{{{  emacs local variables 

;;; local variables:
;;; major-mode: emacs-lisp-mode
;;; folded-file: t
;;; end: 

;;}}}
