;;; emacspeak-calc.el --- Speech enable the Emacs Calculator -- a powerful symbolic algebra system
;;; $Id$
;;; $Author$ 
;;; Description: 
;;; Keywords:
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
;;;Copyright (C) 1995 -- 2002, T. V. Raman 
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

(require 'advice)
(eval-when-compile (require 'cl))
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-speak)
(require 'emacspeak-sounds)
;;{{{  Introduction:

;;; This module extends the Emacs Calculator.
;;; Extensions are minimal.
;;; We force a calc-load-everything,
;;; And use an after advice on this function
;;; To fix all of calc's interactive functions

;;}}}
;;{{{  advice calc interaction 

(defadvice calc-quit (after emacspeak pre act )
  "Announce the buffer that becomes current when calc is quit."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{  speak output 

(defadvice  calc-do (after emacspeak pre act comp)
  "Speak previous line of output."
    (emacspeak-read-previous-line)
    (emacspeak-auditory-icon 'select-object))

(defadvice  calc-trail-here (after emacspeak pre act comp)
  "Speak previous line of output."
    (emacspeak-speak-line)
    (emacspeak-auditory-icon 'select-object))

;;}}}
(provide 'emacspeak-calc)
;;{{{  emacs local variables 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}