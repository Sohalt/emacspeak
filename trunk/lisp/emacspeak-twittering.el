;;; emacspeak-twittering.el --- Speech-enable Twittering-mode
;;; $Id: emacspeak-twit.el 6133 2009-03-17 02:36:43Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable twit.el and twitter.el --- Twitter from Emacs
;;; Keywords: Emacspeak,  Audio Desktop twittering-mode
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
;;;Copyright (C) 1995 -- 2009, T. V. Raman
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
;;; MERCHANTABILITY or FITNTWIT FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:
;;;  module twittering-mode.el  is found on  the emacs wiki
;;; This module speech-enables twittering-mode which works using
;;;  oauth for authentication.
;;; Note: As of Thu Sep  2 08:11:25 PDT 2010
;;; twit.el is broken.

;;; Advices interactive functions to speak

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)

;;}}}
;;{{{ Map->Voice Mappings:

(voice-setup-add-map
 '(
   (twittering-username-face voice-smoothen)
   (twittering-uri-face  voice-brighten)))

;;}}}
;;{{{ Advice interactive commands: twittering-mode

(loop for command in
      '(
        twittering-goto-next-status-of-user
        twittering-goto-previous-status-of-user
        twittering-goto-next-thing
        twittering-goto-previous-thing
        twittering-goto-first-status)
      do
      (eval
       `(defadvice ,command (after emacspeak pre act comp)
          "Provide spoken and auditory feedbackfeedback."
          (when (interactive-p)
            (emacspeak-auditory-icon 'select-object)
            (emacspeak-speak-line)))))

(defadvice twittering-goto-previous-status (around emacspeak pre
                                                   act comp)
  "Speak status moved to."
  (let ((orig (point)))
    ad-do-it
    (emacspeak-speak-region orig (point))
    (emacspeak-auditory-icon 'select-object)
    ad-return-value))

(defadvice twittering-goto-next-status (around emacspeak pre
                                               act comp)
  "Speak status moved to."
  (let ((orig (point)))
    ad-do-it
    (emacspeak-speak-region orig (point))
    (emacspeak-auditory-icon 'select-object)
    ad-return-value))
(defadvice twittering-edit-post-status (after emacspeak pre act
                                              comp)
  "Produce auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))
(defadvice twittering-update-status-interactive (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(loop for command in
      '(twittering-friends-timeline
        twittering-replies-timeline
        twittering-user-timeline
        twittering-direct-messages-timeline
        twittering-update-status-interactive
        twittering-search
        twittering-switch-to-previous-timeline
        twittering-switch-to-next-timeline
        twittering-other-user-list-interactive
        twittering-visit-timeline
        twittering-current-timeline
        twittering-view-user-page
        )
      do
      (eval
       `(defadvice ,command (after emacspeak pre act comp)
          "Provide spoken and auditory feedbackfeedback."
          (when (interactive-p)
            (emacspeak-auditory-icon 'task-done)
            (emacspeak-speak-mode-line)))))

;;}}}
;;{{{ turn on voice lock:

;;; no minor mode hook for now alas:

(add-hook 'twittering-mode-hook
          #'(lambda ()
              (voice-lock-mode 1)))

;;}}}
(provide 'emacspeak-twittering)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
