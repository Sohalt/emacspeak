;;; emacspeak-jde.el --- Speech enable JDE -- An integrated Java Development Environment
;;; $Id$
;;; $Author$ 
;;; Description: Auditory interface to JDE
;;; Keywords: Emacspeak, Speak, Spoken Output, Java
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

;;; Copyright (c) 1995 -- 2001, T. V. Raman
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-speak)
(require 'emacspeak-keymap)
(require 'emacspeak-sounds)
(require 'voice-lock)

;;}}}
;;{{{  Introduction

;;;Speech enable Java IDE.
;;; The Java IDE --JDE-- can be found at 
;;;http://sunsite.auc.dk/jde/

;;}}}
;;{{{ Advice interactive commands:
(defadvice jde-complete-at-point (around emacspeak pre act)
  "Say what you completed."
  (let ((emacspeak-speak-messages nil))
    (when dtk-stop-immediately (dtk-stop))
    ad-do-it
    (dtk-speak emacspeak-last-message)
    ad-return-value))

(defadvice jde-compile (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (dtk-speak "Compiling current java project")))

(defadvice bsh (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (setq emacspeak-comint-autospeak nil)
    (emacspeak-speak-mode-line)))

(defadvice jde-run (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (setq emacspeak-comint-autospeak nil)
    (emacspeak-speak-mode-line)))

(defadvice jde-db (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{ voice lock 

(declaim (special voice-lock-defaults-alist))
(if (not (assq 'jde-mode voice-lock-defaults-alist))
    (setq voice-lock-defaults-alist
          (cons
           (cons 'jde-mode

                 ;; jde-mode-defaults
                 '((java-voice-lock-keywords java-voice-lock-keywords-1
                                             java-voice-lock-keywords-2 java-voice-lock-keywords-3)
                   nil nil ((?_ . "w") (?$ . "w")) nil
                   (voice-lock-mark-block-function . mark-defun)))

           voice-lock-defaults-alist)))

;;}}}
;;{{{ jdebug 

(defadvice jde-debug (after emacspeak pre act comp)
  "Speak the line where we eventually stop. "
  (when (interactive-p)
    (emacspeak-speak-line)
    (emacspeak-auditory-icon 'large-movement)))


(defadvice jde-bug-step-over (after emacspeak pre act comp)
  "Speak the line we stepped to "
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice jde-bug-step-into (after emacspeak pre act comp)
  "Speak the line we stepped to "
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice jde-bug-step-out (after emacspeak pre act comp)
  "Speak the line we stepped to "
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice jde-bug-continue (after emacspeak pre act comp)
  "Speak the line we stop  to "
  (when (interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))

(defadvice jde-bug-exit (after emacspeak pre act comp)
  "Produce auditory icon indicating successful exit "
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-line)))

(defadvice jde-bug-set-breakpoint (after emacspeak pre act comp)
  "Speak the line we set the break point at "
  (when (interactive-p)
    (emacspeak-auditory-icon 'mark-object)
    (emacspeak-speak-line)))
(defadvice jde-bug-clear-breakpoint (after emacspeak pre act comp)
  "Speak the line we nuked the breakpoint  "
  (when (interactive-p)
    (emacspeak-auditory-icon 'deselect-object)
    (emacspeak-speak-line)))
(defadvice jde-bug-highlight-breakpoint (after emacspeak pre
                                               act comp)
  "Annotate line with an auditory icon. "
  (let ((start nil))
    (save-excursion
      (beginning-of-line)
      (setq  start (point))
      (back-to-indentation)
      (ems-modify-buffer-safely
       (put-text-property start (point)
                          'auditory-icon 'mark-object)))))
(defadvice jde-bug-remove-breakpoint-highlight (after emacspeak pre act comp)
  "Clear auditory annotation"
  (let ((start nil))
    (save-excursion
      (beginning-of-line)
      (setq  start (point))
      (back-to-indentation)
      (ems-modify-buffer-safely
       (remove-text-properties
        start (point)
        (list 'auditory-icon 'mark-object))))))

(defadvice jde-bug-up-stack (after emacspeak pre act comp)
  "Speak the line we stepped to "
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))


(defadvice jde-bug-down-stack (after emacspeak pre act comp)
  "Speak the line we stepped to "
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

;;}}}
(provide 'emacspeak-jde )
;;{{{ end of file 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
