;;; emacspeak-pianobar.el --- Pandora Radio: Speech-enable PIANOBAR
;;; $Id: emacspeak-pianobar.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable PIANOBAR An Emacs Interface to pianobar
;;; Keywords: Emacspeak,  Audio Desktop pianobar
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
;;;Copyright (C) 1995 -- 2007, T. V. Raman
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
;;; MERCHANTABILITY or FITNPIANOBAR FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction
;;; pianobar git://github.com/PromyLOPh/pianobar.git
;;; Is a stand-alone client for Pandora Radio.
;;; pianobar.el available on the Emacs Wiki at
;;; http://www.emacswiki.org/emacs/pianobar.el
;;; Provides access to Pandora Radio via pianobar from the comfort of Emacs.
;;; This module speech-enables Pianobar and enhances it for the Complete Audio Desktop.
;;; Commentary:
;;; PIANOBAR == 

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'ansi-color)

;;}}}
;;{{{ Pianobar Fixups:

(defsubst emacspeak-pianobar-current-song  ()
  "Return current song."
  (declare (special pianobar-current-song))
   (ansi-color-apply (substring pianobar-current-song 4)))


(defadvice pianobar-currently-playing (around emacspeak pre act comp)
  "Override with our own notifier."
    (message  (emacspeak-pianobar-current-song)))

;;}}}
;;{{{ Advice Interactive Commands:

(defadvice pianobar (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (emacspeak-speak-mode-line)
    (emacspeak-auditory-icon 'open-object)))

;;; Advice all actions to play a pre-auditory icon

(loop for  f in
      '(pianobar-pause-song pianobar-love-current-song
pianobar-ban-current-song pianobar-bookmark-song
pianobar-create-station pianobar-delete-current-station
pianobar-explain-song
pianobar-add-shared-station pianobar-song-history
pianobar-currently-playing pianobar-add-shared-station
pianobar-move-song-different-station pianobar-next-song
 pianobar-rename-current-station
pianobar-change-station
pianobar-tired-of-song
pianobar-upcoming-songs
pianobar-select-quickmix-stations pianobar-next-song)
      do
      (eval
       `(defadvice ,f (before emacspeak pre act comp)
          "Play auditory icon."
          (when (interactive-p)
            (emacspeak-auditory-icon 'select-object)))))
(defadvice pianobar-window-toggle (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (let ((state (get-buffer-window pianobar-buffer)))
      (cond
       (state
        (emacspeak-auditory-icon'open-object)
        (dtk-speak "Displayed pianobar"))
       (t
        (emacspeak-auditory-icon'close-object)
        (dtk-speak "Hid Pianobar "))))))


(defadvice pianobar-quit (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)))


;;}}}
;;; Simplified Pianobar Interaction

;;{{{ Customizations And Variables









;;}}}
;;{{{ emacspeak-pianobar

;;;###autoload
(defun emacspeak-pianobar  ()
  "Start or control Emacspeak Pianobar player."
  (interactive )
  (declare (special pianobar-buffer))
  (cond
   ((and  (buffer-live-p (get-buffer pianobar-buffer))
          (eq 'run (process-status (get-buffer-process pianobar-buffer))))
    (call-interactively 'emacspeak-pianobar-command))
   (t (pianobar))))
(defun emacspeak-pianobar-command (key)
  "Invoke Pianobar  commands."
  (interactive (list (read-key-sequence "Pianobar Key: ")))
  (declare (special pianobar-key-map))
  (cond
   ((and (stringp key)
         (string= ":" key))
    (call-interactively 'pianobar))
   ((lookup-key pianobar-key-map key)
    (call-interactively (lookup-key pianobar-key-map key)))
   (t (pianobar-send-key  key))))



;;}}}


(provide 'emacspeak-pianobar)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
