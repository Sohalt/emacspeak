;;; emacspeak-newsticker.el --- Speech-enable newsticker
;;; $Id$
;;; $Author$
;;; Description:  Emacspeak front-end for NEWSTICKER 
;;; Keywords: Emacspeak, newsticker 
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

;;; Copyright (C) 1999 T. V. Raman <raman@cs.cornell.edu>
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

;;; Commentary:
;;{{{  Introduction:

;;; Newsticker provides a continuously updating newsticker using
;;; RSS
;;; Provides functionality similar to amphetadesk --but in pure elisp

;;}}}
;;{{{ required modules

;;; Code:
(require 'emacspeak-preamble)
;;}}}
;;{{{ advice functions

(defadvice newsticker-callback-enter (around emacspeak pre act
                                             comp)
  "Silence messages temporarily to avoid chatter."
  (let ((emacspeak-speak-messages nil))
    ad-do-it
    ad-return-value))
(defadvice newsticker-retrieval-tick (around emacspeak pre act comp)
  "Silence messages temporarily to avoid chatter."
  (let ((emacspeak-speak-messages nil))
    ad-do-it
    ad-return-value))

;;}}}
;;{{{ advice interactive commands

(defadvice newsticker-previous-new-item (after emacspeak pre act
                                           comp)
  "Provide spoken feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))

(defadvice newsticker-next-new-item (after emacspeak pre act
                                           comp)
  "Provide spoken feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))



(defadvice newsticker-previous-item (after emacspeak pre act
                                           comp)
  "Provide spoken feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))
(defadvice newsticker-next-item (after emacspeak pre act
                                           comp)
  "Provide spoken feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))




;;}}}
(provide 'emacspeak-newsticker)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
