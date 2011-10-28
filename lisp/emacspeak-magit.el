;;; emacspeak-magit.el --- Speech-enable MAGIT: Git Client
;;; $Id: emacspeak-magit.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable MAGIT An Emacs Interface to magit
;;; Keywords: Emacspeak,  Audio Desktop magit
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
;;; MERCHANTABILITY or FITNMAGIT FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:
;;; MAGIT ==  Git interface in Emacs
;;; git clone http://github.com/magit/magit

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)

;;}}}
;;{{{ Map voices to faces:
(voice-setup-add-map
 '(
   ( magit-header voice-bolden)
   ( magit-section-title voice-annotate)
   ( magit-branch voice-lighten)
   ( magit-diff-file-header voice-animate)
   ( magit-diff-hunk-header voice-animate-medium)
   ( magit-diff-add voice-animate-extra)
   ( magit-diff-none voice-monotone)
   ( magit-diff-del voice-animate-extra)
   ( magit-log-graph voice-monotone)
   ( magit-log-sha1 voice-monotone)
   ( magit-log-message voice-monotone)
   ( magit-item-highlight voice-brighten)
   ( magit-item-mark voice-lighten-extra)
   ( magit-log-tag-label voice-annotate)
   ( magit-log-head-label-bisect-good voice-bolden)
   ( magit-log-head-label-bisect-bad voice-smoothen)
   ( magit-log-head-label-remote voice-bolden)
   ( magit-log-head-label-tags voice-animate)
   ( magit-log-head-label-patches voice-bolden)
   ( magit-whitespace-warning-face voice-monotone)
   ( magit-log-head-label-local voice-lighten)
   ( magit-log-head-label-default voice-monotone)
   ( magit-menu-selected-option voice-animate)))

;;}}}
;;{{{ Advice navigation commands:

;;; Advice navigators:

(loop for f in
      '(
        magit-ignore-file magit-ignore-item
                          magit-ignore-item-locally
        magit-goto-next-section magit-goto-previous-section
        magit-goto-parent-section magit-goto-line
        magit-goto-section magit-goto-section-at-path)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback"
          (when (interactive-p)
            (emacspeak-auditory-icon 'large-movement)
            (emacspeak-speak-line)))))

;;}}}
;;{{{ Advice generator to advice generated  commands:

(defadvice  magit-key-mode-generate (after emacspeak pre act comp)
  "Advice  the key-group menu for GROUP"
  (let ((group (ad-get-arg 0))))
  (eval
   `(defadvice ,(intern (concat "magit-key-mode-popup-" (symbol-name group))) 
      (after emacspeak  pre act comp)
      ,(concat "Speech-enabled Key menu for " (symbol-name group))
        (dtk-speak
         (save-excursion
           (set-buffer magit-key-mode-buf-name)
           (buffer-string))))))
;;; load the magit-key-mode file so the above advice gets applied:

(load-library "magit-key-mode")

;;}}}
;;{{{ Advice hide/show commands:
(loop for f in
      '(magit-show magit-show-branches
                   magit-show-branches-mode
                   magit-show-item-or-scroll-down magit-show-item-or-scroll-up
                   magit-show-level
                   magit-show-level-1 magit-show-level-1-all
                   magit-show-level-2 magit-show-level-2-all
                   magit-show-level-3 magit-show-level-3-all
                   magit-show-level-4 magit-show-level-4-all
                   magit-show-only-files magit-show-only-files-all
                   magit-expand-section magit-expand-collapse-section
                   magit-show-section magit-show-stash)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (interactive-p)
            (emacspeak-speak-line)
            (emacspeak-auditory-icon 'open-object)))))

(loop for f in
      '(magit-hide-section magit-collapse-section)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (interactive-p)
            (emacspeak-speak-line)
            (emacspeak-auditory-icon 'close-object)))))

                   

;;}}}
;;{{{ Additional commands to advice:
(defadvice magit-refresh (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'task-done)
    (emacspeak-speak-line)))

(defadvice magit-refresh-all (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'task-done)
    (emacspeak-speak-line)))

;;}}}
(provide 'emacspeak-magit)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
