;;; emacspeak-imcom.el --- Emacspeak interface to IMCom/Jabber
;;; $Id$
;;; $Author$
;;; Description:  Contains convenience imcom
;;; Keywords: Emacspeak,  Audio Desktop Imcom
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; IMCom is a Jabber client written in Python.
;;; This module wraps IMCom for use on the Emacspeak audio
;;; desktop.

;;}}}
;;{{{  Required modules

(eval-when-compile (require 'cl))
(declaim  (optimize  (safety 0) (speed 3)))
(require 'custom)
(require 'thingatpt)
(require 'voice-lock)
(require 'emacspeak-speak)
(require 'emacspeak-sounds)
(require 'comint)
(eval-when-compile (require 'emacspeak-w3))

;;}}}
;;{{{ Custom

(defgroup emacspeak-imcom nil
  "Jabber access from the Emacspeak audio desktop.")

(defcustom emacspeak-imcom-client "imcom"
  "Name of IMCom command-line client."
  :type 'string
  :group 'emacspeak)

(defcustom emacspeak-imcom-personal-directory
  (expand-file-name "~/.imcom")
  "Directory where IMCom stores personalization files."
  :type 'string
  :group 'emacspeak-imcom)

;;}}}
;;{{{ Create and launch IMCom process

;;}}}
;;{{{  define IMCom mode

;;}}}
;;{{{  Define commands

;;}}}
;;{{{  bind keys 

;;}}}
(provide 'emacspeak-imcom)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
