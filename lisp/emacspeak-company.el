;;; emacspeak-company.el --- Speech-enable COMPANY-mode
;;; $Id: emacspeak-company.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable COMPANY An Emacs Interface to company
;;; Keywords: Emacspeak,  Audio Desktop company
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
;;; MERCHANTABILITY or FITNCOMPANY FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:
;;; COMPANY -mode: Complete Anything Support for emacs.
;;; This module provides an Emacspeak Company Front-end,
;;; And advices the needed interactive commands in Company.

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)

;;}}}
;;{{{ Customizations:

;;}}}
;;{{{ Emacspeak Front-End For Company:
(defun emacspeak-company-frontend (command)
  "Emacspeak front-end for Company."
    (case command
      (pre-command
       (dtk-speak
        (format "%d: %s" (length company-candidates) (car company-candidates))))
      (post-command (dtk-speak (format "%s" (car company-candidates))))
      (hide (dtk-stop ))))

;;}}}
;;{{{ Advice Interactive Commands:

;;}}}
;;{{{ Company Setup For Emacspeak:

;;}}}
(provide 'emacspeak-company)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
