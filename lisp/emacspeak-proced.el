;;; emacspeak-proced.el --- Speech-enable PROCED Task Manager
;;; $Id: emacspeak-proced.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable PROCED A Task manager for Emacs
;;; Keywords: Emacspeak,  Audio Desktop proced Task Manager
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
;;; MERCHANTABILITY or FITNPROCED FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:
;;; PROCED ==  Process Editor
;;; A new Task Manager for Emacs.
;;; Proced is part of emacs 23.

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)

;;}}}
;;{{{ Customizations

;;}}}
;;{{{ Variables

(defvar emacspeak-proced-fields nil
  "Association list holding field-name . column-position pairs.")

;;}}}
;;{{{ Helpers and actions

(defun emacspeak-proced-update-fields ()
  "Updates cache of field-name .column-positions alist."
  (declare (special proced-header-line
                    emacspeak-proced-fields))
  (let ((positions nil)
        (next nil)
        (header proced-header-line)
        (start 0)
        (end 0))
    (setq start (string-match "[A-Za-z%]" header))
    (while (and (<  end (length header))
      (setq end (string-match " " header start)))
      (setq next (string-match "[A-Za-z%]" header end))
      (push
       (cons (substring header start end)
             (cons start (1- next)))
       positions)
      (setq start next))
    (push
       (cons (substring header start)
             (cons start  (1- (length header))))
       positions)
    (setq emacspeak-proced-fields
          (nreverse positions)))))

(defsubst emacspeak-proced-field-to-position (field)
  "Return column position of this field."
  (declare (special emacspeak-proced-fields))
  (cdr (assoc field emacspeak-proced-fields)))

(defun emacspeak-proced-position-to-field (position)
  "Return field name for this position."
  (declare (special emacspeak-proced-fields))
  (let ((fields emacspeak-proced-fields)
    (field nil)
    (range nil)
    (found nil))
  (while (and fields
              (not found))
    (setq field (car fields))
    (setq range (cdr field))
    (setq fields (cdr fields))
    (when (and
           (<= (car range) position)
           (<= position (cdr range)))
      (setq found t)))
  (car field)))
    (when (and
           
              

(defun emacspeak-proced-next-field ()
  "Navigate to next field."
  (interactive)
  (declare (special emacspeak-proced-fields))
  (let ((tabs emacspeak-proced-fields))
    (while (and tabs
                (>= (current-column) (car tabs)))
      (setq tabs (cdr tabs)))
    (cond
     ((null tabs) (error "On last field "))
     (t
      (goto-char
       (+ (line-beginning-position) (car tabs)))
      (emacspeak-auditory-icon 'large-movement)))))

(defun emacspeak-proced-previous-field ()
  "Navigate to previous field."
  (interactive)
  (declare (special emacspeak-proced-fields))
  (let ((tabs emacspeak-proced-fields)
        (target nil))
    (forward-char -1)
    (while (and tabs
                (>= (current-column) (car tabs)))
      (setq target (car tabs)
            tabs (cdr tabs)))
    (cond
     ((null target) (error "On first field "))
     (t
      (goto-char
       (+ (line-beginning-position) target))
      (emacspeak-auditory-icon 'large-movement)))))

;;}}}
;;{{{ Advice interactive commands:


(defadvice proced-update (after emacspeak pre act comp)
  "Update cache of field positions."
  (setq emacspeak-proced-fields
        (emacspeak-proced-update-fields))
(loop for f in
      '(proced-next-line proced-previous-line)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Speak relevant information."
	  (emacspeak-speak-line 1)
	  (emacspeak-auditory-icon 'select-object))))

;;}}}
(provide 'emacspeak-proced)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
