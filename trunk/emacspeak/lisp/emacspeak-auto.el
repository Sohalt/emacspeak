;;; emacspeak-auto.el --- Emacspeak Autoload Generator
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; generate autoloads for emacspeak 

;;}}}
;;{{{  Required modules

(eval-when-compile (require 'cl))
(declaim  (optimize  (safety 0) (speed 3)))
(require 'custom)
(require 'autoload)
;;}}}
;;{{{ generate autoloadms

(defgroup emacspeak-auto nil
  "Emacspeak autoload group.")
(declaim (special emacspeak-lisp-directory))
(defcustom emacspeak-auto-autoloads-file
  (expand-file-name "emacspeak-loaddefs.el"
   emacspeak-lisp-directory)
  "File that holds automatically generated autoloads for Emacspeak."
  :type 'file
  :group 'emacspeak-auto)

(defun emacspeak-auto-generate-autoloads ()
  "Generate emacspeak autoloads."
  (declare (special emacspeak-directory
                    emacspeak-lisp-directory
                    emacspeak-auto-autoloads-file))
  (let ((dtk-quiet t)
        (source-directory emacspeak-directory)
        (generated-autoload-file emacspeak-auto-autoloads-file))
(update-autoloads-from-directories emacspeak-lisp-directory)))

;;}}}
;;{{{ generate autoloads for all custom groups in current directory

(defun emacspeak-auto-generate-custom-loads (directory)
  "Generates buffer containing the needed statements to set up
autoloading  for all defgroup declarations found in current directory."
  (interactive "DDirectory: ")
  (let ((scratch-buffer (get-buffer-create "*defgroup-locater*"))
        (result-buffer (get-buffer-create "*defgroup-loads*"))
        (matches nil)
        (module-list nil))
    (save-excursion
      (set-buffer scratch-buffer)
      (erase-buffer)
      (cd directory)
      (setq matches 
            (shell-command
             "grep '^(defgroup ' *.el | cut -d ' ' -f 2"
             (current-buffer)))
      (when (= 0 matches) ;;;grep succeeded 
        (goto-char (point-min))
        (while (not (eobp))
          (pushnew  (thing-at-point 'sexp)
                    module-list
                    :test #'eql)
          (forward-line 1))))
    (save-excursion
      (set-buffer result-buffer)
      (erase-buffer)
      (loop for m in module-list
            do
            (insert
             (format
              "(put '%s 'custom-loads '(\"%s\"))\n"
              m m))))
    (kill-buffer scratch-buffer)
    (switch-to-buffer result-buffer)
    (emacs-lisp-mode)
    (goto-char (point-min))
    (when (interactive-p)
      (emacspeak-auditory-icon 'open-object)
      (emacspeak-speak-mode-line))))

;;}}}
(provide 'emacspeak-auto)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
