;;; sox.el --- Audio WorkBench Using SoX
;;; $Id: sox.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable SOX An Emacs Interface to sox
;;; Keywords: Emacspeak,  Audio Desktop sox
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
;;; MERCHANTABILITY or FITNSOX FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary: This module defines a convenient speech-enabled
;;; interface for editting mp3 and wav files using SoX. 
;;; 
;;; Launching this module creates a special interaction buffer
;;; that provides single keystroke commands for editing and
;;; applying effects to a selected sound file. For adding mp3
;;; support to sox, 
;;; 
 ;;; sudo apt-get libsox-fmt-mp3 install
;;;
;;; This module can be used independent of Emacspeak.

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'derived)

;;}}}
;;{{{ Define Special Mode

(defun sox-draw-effect (effect)
  "Insert a representation of specified effect at point."
  (let ((name (sox-effect-name effect))
        (params (sox-effect-params effect)))
    (insert (propertize  name 'face  'font-lock-keyword-face))
    (loop
     for p in params do
     (insert (propertize (first p) 'face 'font-lock-string-face))
     (insert " ")
     (insert (propertize (second p) 'face 'bold)))
    (insert "\n")))

(defun sox-redraw (context)
  "Redraws sox buffer."
  (let ((inhibit-read-only t)
        (orig (point-min))
        (file (sox-context-file context))
        (effects (sox-context-effects context)))
    (goto-char orig)
    (erase-buffer)
    (insert (propertize "Audio File:  " 'face font-lock-doc-face))
    (when  file (insert  (propertize file 'face font-lock-keyword-face)))
    (insert "\n")
    (when effects (mapc #'sox-draw-effect effects))))

(define-derived-mode sox-mode special-mode
  "Interactively manipulate audio files."
  "An audio workbench for the Emacspeak desktop."
  (declare (special sox-context))
  (setq sox-context (make-sox-context))
  (sox-redraw sox-context)
  (setq buffer-read-only t)
  (setq header-line-format "Audio Workbench"))

(defvar sox-buffer "Audio WorkBench"
  "Buffer name of workbench.")

;;;###autoload
(defun sox ()
  "Create a new Audio Workbench or switch to an existing workbench."
  (interactive)
  (declare (special sox-buffer))
  (unless (get-buffer sox-buffer)
    (let ((buffer (get-buffer-create sox-buffer)))
      (with-current-buffer buffer
        (sox-mode)
        (sox-setup-keys))))
  (funcall-interactively #'switch-to-buffer sox-buffer))

(defgroup sox nil
  "Audio workbench for the Emacspeak Audio Desktop."
  :group 'emacspeak
  :group 'applications)

(defun sox-setup-keys ()
  "Set up sox keymap."
  (declare (special sox-mode-map))
  (loop
   for k in
   '(
     ("E" sox-add-effect)
     ("e" sox-set-effect)
     ("f" sox-open-file)
     ("p" sox-play)
     ("s" sox-save)
     )
   do
   (define-key sox-mode-map (first k) (second k))))

;;}}}
;;{{{ Top-level Context:

(defstruct sox-effect
  name ; effect name
  params ; list of effect name/value pairs
  )

(defstruct sox-context
  file ; file being manipulated
  effects ; list of effects with params
  start-time ; play start time
  stop-time ; play stop time
  play ; play process handle
  )

(defvar sox-context nil
  "Buffer-local handle to sox context.")

(make-variable-buffer-local 'sox-context)

(defcustom sox-edit
  (executable-find "sox")
  "Location of SoX utility."
  :type 'file)

(defcustom sox-play (executable-find "play")
  "Location of play from SoX utility."
  :type 'file)

;;}}}
;;{{{ Commands:

(defvar sox-sound-regexp
  (regexp-opt  '(".mp3" ".wav" ".au"))
  "Regexp matching sound files.")

(defsubst sox-sound-p (snd-file)
  "Predicate to test if we can edit this file."
  (declare (special sox-sound-regexp))
  (let ((case-fold-search t))
    (string-match  sox-sound-regexp snd-file)))

(defun sox-open-file (snd-file)
  "Open specified snd-file on the Audio Workbench."
  (interactive "fSound File: ")
  (declare (special sox-context))
  (unless sox-context (error "Audio Workbench not initialized."))
  (let ((inhibit-read-only t)
        (type (sox-sound-p snd-file)))
    (unless type (error "%s does not look like a sound file." snd-file))
    (setf (sox-context-file sox-context)
          snd-file))
  (cd(file-name-directory snd-file))
  (sox-redraw sox-context)
  (message "Selected file %s" snd-file))

(defun sox-action (context action &optional save-file)
  "Apply action to    current context."
  (let ((file (sox-context-file context))
        (effects (sox-context-effects context))
        (command nil)
        (options nil))
    (loop
     for e in effects  do
     (push (sox-effect-name e) options)
     (loop
      for  p in (sox-effect-params e) do
      (push (second p)  options)))
    (setq options (nreverse options))
    (when (string= action sox-edit) (push save-file options))
    (apply #'start-process
           sox-play "*SOX*" action file options)))

(defun sox-play ()
  "Play sound from current context."
  (interactive)
  (declare (special sox-context sox-play))
  (setf (sox-context-start-time sox-context) (current-time))
  (setf (sox-context-play sox-context)(sox-action sox-context
                                                  sox-play)))

(defun sox-stop ()
  "Stop currently playing  sound from current context."
  (interactive)
  (declare (special sox-context))
  (setf (sox-context-stop-time sox-context) (current-time))
  (delete-process (sox-context-play sox-context))
  (message "%s"
           (time-to-seconds (time-subtract (sox-context-stop-time sox-context) (sox-context-start-time sox-context)))))

(defun sox-save(save-file)
  "Save context to  file after prompting."
  (interactive "FSave File: ")
  (declare (special sox-context sox-edit))
  (sox-action sox-context sox-edit save-file))

(defconst sox-effects
  '(
    "bass"
    "chorus"
    "reverb"
    "treble"
    "trim")

  "Table of implemented effects.")

(defun sox-set-effect (name)
  "Set effect."
  (interactive
   (list (completing-read "SoX Effect: " sox-effects nil t)))
  (declare (special sox-context  sox-effects))
  (setf (sox-context-effects sox-context)
        (list
         (funcall (intern (format  "sox-get-%s-effect"  name)))))
  (sox-redraw sox-context)
  (message "Set effect  %s" name))

(defun sox-add-effect (name)
  "Adds  effect at the end of the effect list"
  (interactive
   (list (completing-read "Add SoX Effect: "  sox-effects nil t)))
  (declare (special sox-context  sox-effects))
  (setf (sox-context-effects sox-context)
        (append
         (sox-context-effects sox-context)
         (list
          (funcall (intern (format  "sox-get-%s-effect"  name))))))
  (sox-redraw sox-context)
  (message "Set effect  %s" name))
(defun sox-read-effect-params (param-desc)
  "Read list of effect  params."
  (mapcar
   #'(lambda (p)
       (list p (read-from-minibuffer (capitalize p))))
   param-desc))

;;}}}
;;; Effects:
;;{{{ Trim:

(defun sox-get-trim-effect ()
  "Read needed params for effect trim,
and return a suitable effect structure."
  (make-sox-effect
   :name "trim"
   :params
   (let ((s (read-from-minibuffer "Time Offset: "))
         (params nil))
     (while (string-match "[0-9:.]+" s)
       (push  (list "|" s) params)
       (setq s (read-from-minibuffer "Offset Time: ")))
     (nreverse params))))

;;}}}
;;{{{ Bass:

;;; bass|treble gain [frequency[k] [width[s|h|k|o|q]]]
(defvar sox-bass-params
  '("gain" "frequency" "width")
  "Params accepted by bass.")

(defun sox-get-bass-effect ()
  "Read needed params for effect bass,
and return a suitable effect structure."
  (declare (special sox-bass-params))
  (make-sox-effect
   :name "bass"
   :params (sox-read-effect-params sox-bass-params)))

;;}}}
;;{{{ Treble:

;;; bass|treble gain [frequency[k] [width[s|h|k|o|q]]]
(defvar sox-treble-params
  '("gain" "frequency" "width")
  "Params accepted by treble.")

(defun sox-get-treble-effect ()
  "Read needed params for effect treble,
and return a suitable effect structure."
  (declare (special sox-treble-params))
  (make-sox-effect
   :name "treble"
   :params (sox-read-effect-params sox-treble-params) ))

;;}}}
;;{{{ Chorus:

;;;  chorus gain-in gain-out <delay decay speed depth -s|-t>
(defvar sox-chorus-params
  '("gain-in" "gain-out" "delay" "decay" "speed" "step" "shape" )
  "Parameters for effect chorus.")

(defun sox-get-chorus-effect  ()
  "Read needed params for effect chorus
and return a suitable effect structure."
  (declare (special sox-chorus-params))
  (make-sox-effect
   :name "chorus"
   :params (sox-read-effect-params sox-chorus-params)))

;;}}}
;;{{{ Reverb:

;;;reverb [-w|--wet-only] [reverberance (50%) [HF-damping (50%)
;;; [room-scale (100%) [stereo-depth (100%)
;;; [pre-delay (0ms) [wet-gain (0dB)]]]]]]

(defconst sox-reverb-params
  nil
  "Parameters for effect reverb.")

(defun sox-get-reverb-effect  ()
  "Read needed params for effect reverb
and return a suitable effect structure."
  (declare (special sox-reverb-params))
  (make-sox-effect
   :name "reverb"
   :params (sox-read-effect-params sox-reverb-params)))

;;}}}
(provide 'sox)
;;{{{ Add Emacspeak Support

;;; Code here can be factored out to emacspeak-sox.el 
(require 'emacspeak-preamble)

;;}}}
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
