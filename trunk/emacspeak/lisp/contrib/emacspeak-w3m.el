;;; emacspeak-w3m.el --- speech-enables w3m-el
;;; This file is not part of Emacspeak, but the same terms and
;;; conditions apply.

;; Copyright (C) 2001,2002  Dimitri V. Paduchih

;; Author: Dimitri Paduchih <paduch@imm.uran.ru>
;; Keywords: emacspeak, w3m

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; 


;;; Code:

(require 'w3m nil t)
(require 'dtk-tcl)
(require 'emacspeak-sounds)


(define-key w3m-mode-map [M-tab] 'w3m-previous-anchor)
(define-key w3m-mode-map [tab] 'w3m-next-anchor)
(define-key w3m-mode-map [down] 'next-line)
(define-key w3m-mode-map [up] 'previous-line)
(define-key w3m-mode-map [right] 'emacspeak-forward-char)
(define-key w3m-mode-map [left] 'emacspeak-backward-char)

(defun emacspeak-w3m-personalize-string (string personality)
  (let ((newstring (copy-sequence string)))
    (put-text-property 0 (length newstring)
		       'personality personality
		       newstring)
    newstring))

(defun emacspeak-w3m-anchor-text (&optional default)
  "Return string containing text of anchor under point."
  (if (get-text-property (point) 'w3m-cursor-anchor)
      (buffer-substring
       (previous-single-property-change (1+ (point)) 'w3m-cursor-anchor)
       (next-single-property-change (point) 'w3m-cursor-anchor))
    (or default "")))

(defun emacspeak-w3m-speak-cursor-anchor ()
  (dtk-speak (emacspeak-w3m-anchor-text "Not found")))

(defun emacspeak-w3m-speak-form-input (form name type width maxlength value)
  (dtk-speak
   (format "%s input %s  %s"
	   type
	   name
	   (emacspeak-w3m-personalize-string
	    (or (w3m-form-get form name) value)
	    emacspeak-w3m-form-personality))))

(defun emacspeak-w3m-speak-form-input-password (form name)
  "Speech-enable password form element."
  (dtk-speak
   (format "password input %s  %s"
	   name
	   (emacspeak-w3m-personalize-string
	    (emacspeak-w3m-anchor-text)
	    emacspeak-w3m-form-personality))))

(defun emacspeak-w3m-speak-form-submit (form &optional name value)
  (dtk-speak
   (if (equal value "")
       "submit button"
     (format "button %s"
	     (emacspeak-w3m-personalize-string
	      value
	      emacspeak-w3m-button-personality)))))

(defun emacspeak-w3m-speak-form-input-radio (form name value)
  (and dtk-stop-immediately (dtk-stop))
  (let* ((active (equal value (w3m-form-get form name)))
	 (personality (if active
			  emacspeak-w3m-form-personality
			emacspeak-w3m-button-personality))
	 (dtk-stop-immediately nil))
    (emacspeak-auditory-icon (if active 'on 'off))
    (dtk-speak
     (if (equal value "")
	 (emacspeak-w3m-personalize-string
	  (format "unset radio %s" name)
	  personality)
       (format "%s of the radio %s"
	       (emacspeak-w3m-personalize-string
		(concat "option " value)
		personality)
	       name)))))

(defun emacspeak-w3m-speak-form-input-select (form name)
  (dtk-speak
   (format "select %s  %s"
	   name
	   (emacspeak-w3m-personalize-string
	    (emacspeak-w3m-anchor-text)
	    emacspeak-w3m-form-personality))))

(defun emacspeak-w3m-speak-form-input-textarea (form hseq)
  (dtk-speak
   (format "text area %s  %s"
	   (or (get-text-property (point) 'w3m-form-name) "")
	   (emacspeak-w3m-personalize-string
	    (emacspeak-w3m-anchor-text)
	    emacspeak-w3m-form-personality))))

(defun emacspeak-w3m-speak-form-reset (form)
  (dtk-speak
   (format "button %s"
	   (emacspeak-w3m-personalize-string
	    "reset"
	    emacspeak-w3m-button-personality))))


(defvar emacspeak-w3m-form-personality 'paul-animated)
(defvar emacspeak-w3m-button-personality 'harry)

(defvar emacspeak-w3m-speak-action-alist
  '((w3m-form-input . emacspeak-w3m-speak-form-input)
    (w3m-form-input-radio . emacspeak-w3m-speak-form-input-radio)
    (w3m-form-input-select . emacspeak-w3m-speak-form-input-select)
    (w3m-form-input-textarea . emacspeak-w3m-speak-form-input-textarea)
    (w3m-form-submit . emacspeak-w3m-speak-form-submit)
    (w3m-form-input-password . emacspeak-w3m-speak-form-input-password)
    (w3m-form-reset . emacspeak-w3m-speak-form-reset)))

(defun emacspeak-w3m-speak-this-anchor ()
  (let ((url (w3m-anchor))
	(act (w3m-action)))
    (cond
     (url (emacspeak-w3m-speak-cursor-anchor))
     ((consp act)
      (let ((speak-action (cdr (assq
				(car act)
				emacspeak-w3m-speak-action-alist))))
	(if (functionp speak-action)
	    (apply speak-action (cdr act))
	  (emacspeak-w3m-speak-cursor-anchor))))
     (t (emacspeak-w3m-speak-cursor-anchor)))))


;;; Advices for w3m commands

(defadvice w3m-goto-url (around emacspeak pre act)
  (let ((emacspeak-speak-messages nil))
    ad-do-it)
  (when (stringp w3m-current-title)
    (message "%s" w3m-current-title)))

(defadvice w3m-next-anchor (around emacspeak pre act)
  (let ((emacspeak-speak-messages nil))
    ad-do-it)
  (when (interactive-p)
    (emacspeak-w3m-speak-this-anchor)))

(defadvice w3m-previous-anchor (around emacspeak pre act)
  (let ((emacspeak-speak-messages nil))
    ad-do-it)
  (when (interactive-p)
    (emacspeak-w3m-speak-this-anchor)))

(defadvice w3m-next-form (around emacspeak pre act comp)
  (let ((emacspeak-speak-messages nil))
    ad-do-it)
  (when (interactive-p)
    (emacspeak-w3m-speak-this-anchor)))

(defadvice w3m-previous-form (around emacspeak pre act comp)
  (let ((emacspeak-speak-messages nil))
    ad-do-it)
  (when (interactive-p)
    (emacspeak-w3m-speak-this-anchor)))

(defadvice w3m-view-this-url (around emacspeak pre act comp)
  (let ((url (w3m-anchor))
	(act (w3m-action)))
    ad-do-it
    (when (and (interactive-p)
	       (not url)
	       (consp act)
	       (memq (car act)
		     '(w3m-form-input
		       w3m-form-input-radio
		       w3m-form-input-password)))
      (emacspeak-w3m-speak-this-anchor))))


;;; w3m-form-input-select-mode

(add-hook 'w3m-form-input-select-mode-hook
	  (lambda ()
	    (emacspeak-auditory-icon 'select-object)
	    (emacspeak-speak-line)))

(defadvice w3m-form-input-select-set (after emacspeak pre act comp)
  (when (and (interactive-p) (w3m-cursor-anchor))
    (emacspeak-w3m-speak-this-anchor)))

(defadvice w3m-form-input-select-exit (after emacspeak pre act comp)
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)))

;;; w3m-form-input-textarea-mode

(add-hook 'w3m-form-input-textarea-mode-hook
	  (lambda ()
	    (emacspeak-auditory-icon 'open-object)
	    (dtk-speak "edit text area")))

(defadvice w3m-form-input-textarea-set (after emacspeak pre act comp)
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-w3m-speak-this-anchor)))

(defadvice w3m-form-input-textarea-exit (after emacspeak pre act comp)
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)))



(provide 'emacspeak-w3m)
;;; emacspeak-w3m.el ends here

;;; local variables:
;;; byte-compile-dynamic: t
;;; end: 
