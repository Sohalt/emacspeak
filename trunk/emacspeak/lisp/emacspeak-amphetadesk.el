;;; emacspeak-amphetadesk.el --- Emacspeak News Portal Interface
;;; $Id$
;;; $Author$
;;; Description:  RSS Wizard for the emacspeak desktop
;;; Keywords: Emacspeak,  Audio Desktop RSS
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
;;;Copyright (C) 1995 -- 2003, T. V. Raman 
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

;;; AmphetaDesk --http://amphetadesk.sf.net is an RSS news aggregator.
;;; This module provides a simple emacs front-end to amphetadesk
;;; Emacspeak users should try this in conjunction with the
;;; AmphetaDesk lite theme available in the Emacspeak CVS repository 
;;; under tvr/amphetadesk

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'custom)
(require 'browse-url)
(require 'emacspeak-preamble)
(condition-case nil
(require 'emacspeak-w3)
(error nil))
;;}}}
;;{{{ amphetadesk

(defgroup emacspeak-amphetadesk nil
  "AmphetaDesk"
  :group 'aplications)

(defcustom emacspeak-amphetadesk-program
  "/usr/local/share/amphetadesk-src-v0.93.1/AmphetaDesk.pl "
  "Script that launches amphetadesk."
  :type 'file
  :group 'emacspeak-amphetadesk)

(defcustom emacspeak-amphetadesk-port 8888
  "Port where AmphetaDesk listens."
  :type 'integer
  :group 'emacspeak-amphetadesk)

(defsubst emacspeak-amphetadesk-ensure-live ()
  "Ensure AmphetaDesk is alive, and start it if necessary."
  (declare (special emacspeak-amphetadesk-program
                    emacspeak-amphetadesk-port))
  (if (=  1
          (shell-command
           (format "netstat -nat | grep %s"
		   emacspeak-amphetadesk-port)))
      (shell-command
       (format "%s &"
               emacspeak-amphetadesk-program)
       "*AmphetaDesk*")))

;;;###autoload
(defun emacspeak-amphetadesk ()
  "Open amphetadesk."
  (interactive)
  (declare (special browse-url-browser-function))
  (emacspeak-amphetadesk-ensure-live)
  (cond
   ((and (featurep 'w3)
	 (eq browse-url-browser-function 'browse-url-w3))
    (emacspeak-w3-without-xsl
     (browse-url "http://127.0.0.1:8888/")))
   (t
    (browse-url "http://127.0.0.1:8888/"))))

;;}}}
(provide 'emacspeak-amphetadesk)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
