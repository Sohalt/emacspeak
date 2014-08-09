;;; emacspeak-load-path.el -- Setup Emacs load-path for compiling Emacspeak
;;; $Id$
;;; $Author: tv.raman.tv $ 
;;; Description:  Sets up load-path for emacspeak compilation and installation
;;; Keywords: Emacspeak, Speech extension for Emacs
;;{{{  LCD Archive entry: 
;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2007-08-25 18:28:19 -0700 (Sat, 25 Aug 2007) $ |
;;;  $Revision: 4532 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2011, T. V. Raman 
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
(defvar emacspeak-directory
  (expand-file-name "../" (file-name-directory load-file-name))
  "Directory where emacspeak is installed. ")

(defvar emacspeak-lisp-directory
  (expand-file-name "lisp/" emacspeak-directory)
  "Directory containing lisp files for  Emacspeak.")  

(unless (member emacspeak-lisp-directory load-path )
  (setq load-path
        (cons emacspeak-lisp-directory load-path )))

(defvar emacspeak-resource-directory (expand-file-name "~/.emacspeak")
  "Directory where Emacspeak resource files such as pronunciation dictionaries are stored. ")

(setq byte-compile-warnings t)

;;{{{ Implementation:
;;; Notes:
;;; Comint completion advice doesn't work correctly.
;;; This implementation below appears to work for 90% of emacspeak.
(defvar ems-called-interactively-p nil
  "Flag recording interactive calls.")
;;; Using this in places where called-interactively hits deadlocks :

(defadvice call-interactively (before emacspeak  pre act comp)
  "Set our interactive flag."
  (setq ems-called-interactively-p (ad-get-arg 0)))

(defsubst ems-interactive-p ()
  "Check our interactive flag.
Return T if set and we are called from the advice for the current
interactive command. Turn off the flag once used."
  (when ems-called-interactively-p ; interactive call 
    (let ((caller (second (backtrace-frame 1))) 
          (caller-advice (ad-get-advice-info-field ems-called-interactively-p  'advicefunname))
          (result nil))
      (setq result (or (eq caller caller-advice) ; called from our advice
        (eq ems-called-interactively-p caller ) ; call-interactively call
        (eq this-command caller)))
  (cond
   (result 
    (setq ems-called-interactively-p nil) ; turn off now that we used  it
    result)
   (t nil)))))
    


;;}}}



(provide 'emacspeak-load-path)
