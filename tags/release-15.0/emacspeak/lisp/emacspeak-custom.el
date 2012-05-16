;;; emacspeak-custom.el --- Speech enable interactive Emacs customization 
;;; $Id$
;;; $Author$ 
;;; Description: Auditory interface to custom
;;; Keywords: Emacspeak, Speak, Spoken Output, custom
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

(eval-when-compile (require 'cl))
(declaim  (optimize  (safety 0) (speed 3)))
(eval-when (compile)
  (require 'emacspeak-speak)
  (require 'voice-lock)
  (require 'emacspeak-keymap)
  (require 'emacspeak-sounds)
  (require 'widget)
  (require 'wid-edit)
  (require 'emacspeak-widget))

;;}}}
;;{{{  Introduction

;;;Advise custom to speak.
;;; most of the work is actually done by emacspeak-widget.el
;;; which speech-enables the widget libraries.

;;}}}
;;{{{ Advice

(defadvice customize-save-customized (after emacspeak pre act comp)
  "Provide auditory feedback. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'save-object)
    (message "Saved customizations.")))

(defadvice custom-save-all (after emacspeak pre
                                            act comp)
  "Provide auditory feedback. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'save-object)
    (message "Saved customizations.")))
(defadvice custom-set (after emacspeak pre act comp)
  "Provide auditory feedback. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'mark-object)
    (message "Set all updates.")))


(defadvice customize (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (voice-lock-mode 1)
    (emacspeak-custom-goto-group)
    (emacspeak-speak-line)))

(defadvice customize-group (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-custom-goto-group)
    (voice-lock-mode 1)
    (emacspeak-speak-line)))

(defadvice customize-browse (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (voice-lock-mode 1)
    (emacspeak-speak-mode-line)))

(defadvice customize-option (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (let ((symbol (ad-get-arg 0)))
      (emacspeak-auditory-icon 'open-object)
      (search-forward (custom-unlispify-tag-name symbol))
      (beginning-of-line)
      (voice-lock-mode 1)
      (emacspeak-speak-line))))

(defadvice customize-apropos (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (let ((symbol (ad-get-arg 0)))
      (emacspeak-auditory-icon 'open-object)
      (voice-lock-mode 1)
      (beginning-of-line)
      (emacspeak-speak-line))))


(defadvice customize-variable (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (let ((symbol (ad-get-arg 0)))
      (emacspeak-auditory-icon 'open-object)
      (voice-lock-mode 1)
      (search-forward (custom-unlispify-tag-name symbol))
      (beginning-of-line)
      (emacspeak-speak-line))))

(defadvice Custom-goto-parent (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (voice-lock-mode 1)
    (emacspeak-speak-line)))

;;}}}
;;{{{ custom hook

(add-hook 'custom-mode-hook
          (function
           (lambda nil
             (voice-lock-mode 1)
             (emacspeak-pronounce-refresh-pronunciations))))

;;}}}
;;{{{  custom navigation

(defcustom emacspeak-custom-group-regexp
  "^/-"
  "Pattern identifying start of custom group."
  :type 'regexp
  :group 'emacspeak-custom)

(defun emacspeak-custom-goto-group ()
  "Jump to custom group when in a customization buffer."
  (interactive)
  (declare (special emacspeak-custom-group-regexp))
  (when (eq major-mode 'custom-mode)
    (goto-char (point-min))
    (re-search-forward emacspeak-custom-group-regexp
                       nil t)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))


(defcustom emacspeak-custom-toolbar-regexp
  "^Operate on everything in this buffer:"
  "Pattern that identifies toolbar section."
  :type 'regexp
  :group 'emacspeak-custom)

(defun emacspeak-custom-goto-toolbar ()
  "Jump to custom toolbar when in a customization buffer."
  (interactive)
  (declare (special emacspeak-custom-toolbar-regexp))
  (when (eq major-mode 'custom-mode)
    (goto-char (point-min))
    (re-search-forward emacspeak-custom-toolbar-regexp nil
                       t)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))

;;}}}
;;{{{  bind emacspeak commands 

(declaim (special custom-mode-map))
(define-key custom-mode-map "," 'backward-paragraph)
(define-key custom-mode-map "." 'forward-paragraph)
(define-key custom-mode-map  "\M-t" 'emacspeak-custom-goto-toolbar)
(define-key custom-mode-map  "\M-g"
  'emacspeak-custom-goto-group)

;;}}}
;;{{{ augment custom widgets

;;}}}
(provide 'emacspeak-custom)
;;{{{ end of file 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}