;;; emacspeak-snd-edit.el --- Speech-enable SND-EDIT
;;; $Id: emacspeak-snd-edit.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable SND-EDIT An Emacs Interface to snd-edit
;;; Keywords: Emacspeak,  Audio Desktop snd-edit
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-05-03 18:13:44 -0700 (Thu, 03 May 2007) $ |
;;;  $Revision: 4532 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2007, 2011, T. V. Raman
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
;;; MERCHANTABILITY or FITNSND-EDIT FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary: This module defines a convenient speech-enabled
;;; interface for editting mp3 and wav files. It uses
;;; command-line tools like sox and mp3cut (from package
;;; poc-streamer) mp3split from package mp3splt and possibly
;;; mpgtx from package mpgtx under the covers.
;;; Launching this module creates a special interaction buffer 
;;; that provides single keystroke commands for editing and applying effects to a selected sound file.

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'derived)

;;}}}
;;{{{ Define Special Mode

(defun emacspeak-snd-edit-redraw ()
  "Redraws snd-edit buffer."
  (declare (special emacspeak-snd-edit-context))
  (let ((inhibit-read-only t)
        (start (point-min))
        (file (emacspeak-snd-edit-context-file emacspeak-snd-edit-context))
        (start-time (emacspeak-snd-edit-context-start emacspeak-snd-edit-context))
        (end-time (emacspeak-snd-edit-context-end emacspeak-snd-edit-context)))
    (goto-char start)
    (erase-buffer)    
    (insert "Audio File:  ")
    (put-text-property start (point) 'face font-lock-doc-face)
    (setq start (point))
    (when  file
      (insert  file)
      (put-text-property start (point) 'face font-lock-keyword-face))
    (insert "\n")
    (when start-time (insert (format "Start: %s" start-time)))
    (when end-time (insert (format "End: %s" end-time)))))

(define-derived-mode emacspeak-snd-edit-mode special-mode
                     "Interactively manipulate audio files."
  "An audio workbench for the Emacspeak desktop."
  (declare (special emacspeak-snd-edit-context))
  (unless emacspeak-snd-edit-context
    (setq emacspeak-snd-edit-context (make-emacspeak-snd-edit-context)))
  (emacspeak-snd-edit-redraw)
  (setq buffer-read-only t)
  (setq header-line-format "Audio Workbench"))

(defvar emacspeak-snd-edit-buffer "Audio WorkBench"
  "Buffer name of workbench.")

;;;###autoload
(defun emacspeak-snd-edit ()
  "Create a new Audio Workbench or switch to an existing workbench."
  (interactive)
  (declare (special emacspeak-snd-edit-buffer))
  (unless (get-buffer emacspeak-snd-edit-buffer)
    (let ((buffer (get-buffer-create emacspeak-snd-edit-buffer)))
    (with-current-buffer buffer
      (emacspeak-snd-edit-mode)
      (emacspeak-snd-edit-setup-keys))))
  (switch-to-buffer emacspeak-snd-edit-buffer)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-header-line))
    
    
(defgroup emacspeak-snd-edit nil
  "Audio workbench for the Emacspeak Audio Desktop."
  :group 'emacspeak)

(defun emacspeak-snd-edit-setup-keys ()
  "Set up snd-edit keymap."
  (declare (special emacspeak-snd-edit-mode-map))
  (loop
 for k in
 '(
   ("f" emacspeak-snd-edit-file)
   ("[" emacspeak-snd-edit-set-start)
   ("]" emacspeak-snd-edit-set-end)
   )
        do
        (emacspeak-keymap-update  emacspeak-snd-edit-mode-map k)))

;;}}}
;;{{{ Top-level Context:

(defstruct emacspeak-snd-edit-effect
  name ; effect name
  params ; list of effect params 
)

(defstruct emacspeak-snd-edit-context
  file ; file being manipulated 
  start end ; clipping params
  effects ; list of effects with params 
)

(defvar emacspeak-snd-edit-context
  nil
  "Buffer-local handle to snd-edit context.")

(make-variable-buffer-local 'emacspeak-snd-edit-context)

;;}}}
;;{{{ Common Commands 

(defsubst emacspeak-snd-edit-sound-p (snd-file)
  "Predicate to test if we can edit this file."
  (let ((case-fold-search t))
    (cond
     ((string-match  "\\.mp3$" snd-file) 'mp3)
     ((string-match  "\\.mp3$" snd-file) 'mp3)
     ((string-match "\\.au$" snd-file) 'au)
     ((string-match "\\.wav$" snd-file) 'wave)
     (t nil))))

(defun emacspeak-snd-edit-file (snd-file)
  "Open specified snd-file on the Audio Workbench."
  (interactive "fSound File: ")
  (declare (special emacspeak-snd-edit-context))
  (unless (emacspeak-snd-edit-sound-p snd-file)
    (error "%s does not look like a sound file." snd-file))
  (unless emacspeak-snd-edit-context
    (error "Audio Workbench not initialized."))
  (let ((inhibit-read-only t))
    (setf (emacspeak-snd-edit-context-file emacspeak-snd-edit-context) snd-file)
  (emacspeak-snd-edit-redraw)
  
  
  
  (message "Selected file %s" snd-file)
  (emacspeak-auditory-icon 'select-object)))

(defun emacspeak-snd-edit-read-timestamp (prompt)
  "Read timestamp hh:mm:ss.sss."
  (declare (special emacspeak-snd-edit-context))
  (let ((timestamp (read-from-minibuffer  prompt)))
    (unless emacspeak-snd-edit-context
      (error "Audio Workbench not initialized."))
    (unless (string-match "[0-9:.]+" timestamp)
      (error "%s does not look like a valid timestamp." timestamp))
    timestamp))

(defun emacspeak-snd-edit-set-start (timestamp)
  "Set start time."
  (interactive
   (list
    (emacspeak-snd-edit-read-timestamp "Start: ")))
  (setf (emacspeak-snd-edit-context-start emacspeak-snd-edit-context) timestamp)
  (emacspeak-snd-edit-redraw)
  (message "Set start to %s" timestamp))

(defun emacspeak-snd-edit-set-end (timestamp)
  "Set end time."
  (interactive
   (list
    (emacspeak-snd-edit-read-timestamp "End: ")))
  (setf (emacspeak-snd-edit-context-end emacspeak-snd-edit-context) timestamp)
  (emacspeak-snd-edit-redraw)
  (message "Set end to %s" timestamp))

;;}}}
;;{{{  SOX for Wave files :

(defcustom emacspeak-snd-edit-wave
  (executable-find "sox")
  "Location of SoX utility."
  :type 'file)

;;}}}
;;{{{ SoX for Wave edit commands 

;;}}}
;;{{{ mp3cut for mp3 files:

(defcustom emacspeak-snd-edit-mp3
  (executable-find "mp3cut")
  "Location of mp3cut utility from the poc-streamer package."
  :type 'file)

;;}}}
;;{{{  mp3 edit commands:

;;}}}
(provide 'emacspeak-snd-edit)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
