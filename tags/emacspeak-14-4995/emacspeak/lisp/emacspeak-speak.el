;;; emacspeak-speak.el --- Implements Emacspeak's core speech services
;;; $Id$
;;; $Author$
;;; Description:  Contains the functions for speaking various chunks of text
;;; Keywords: Emacspeak,  Spoken Output
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
;;;Copyright (C) 1995 -- 2000, T. V. Raman 
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

;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'backquote)
(require 'custom)
(require 'thingatpt)
(require 'dtk-speak)
(eval-when (compile)
  (require 'voice-lock)
           (require 'emacspeak-table-ui)
           (require 'emacspeak-sounds)
(require 'shell))

;;}}}
;;{{{  Introduction:

;;; Commentary:

;;; This module defines the core speech services used by emacspeak.
;;; It depends on the speech server interface modules
;;; It protects other parts of emacspeak
;;; from becoming dependent on the speech server modules
;;; Code:

;;}}}
;;{{{  custom group 
(defconst  emacspeak-xemacs-p
  (when (or (boundp 'running-xemacs)
      (string-match "Lucid\\|XEmacs" emacs-version))
  t)
"T if we are running under XEmacs.")
(defgroup emacspeak-speak nil
"Basic speech output commands."
:group 'emacspeak)

;;}}}
;;{{{ inhibit-point-motion-hooks
(defsubst ems-inhibit-point-motion-hooks ()
  (declare (special inhibit-point-motion-hooks))
  (if (boundp 'inhibit-point-motion-hooks)
      inhibit-point-motion-hooks
    nil))

;;}}}
;;{{{  Macros

;;; Save read-only and modification state, perform some actions and
;;; restore state
(defmacro ems-modify-buffer-safely   (&rest body )
  "Allow BODY to temporarily modify read-only content."
  (`
   (progn
     (declare (special inhibit-point-motion-hooks))
   (unwind-protect
       (let    ((save-read-only buffer-read-only)
                (buffer-read-only nil )
                (save-inhibit-read-only inhibit-read-only)
                (inhibit-read-only t)
                (save-inhibit-point-motion-hooks (ems-inhibit-point-motion-hooks))
                (inhibit-point-motion-hooks t)
                (modification-flag (buffer-modified-p)))
         (unwind-protect
             (,@ body )
           (setq buffer-read-only save-read-only
                 inhibit-read-only save-inhibit-read-only
                 inhibit-point-motion-hooks save-inhibit-point-motion-hooks)
           (set-buffer-modified-p modification-flag )))))))


                                        ; Internal macro used by Emacspeak to set a personality temporarily.
                                        ; The previous property is reset after executing body.
                                        ; At present, we assume that region from start to end has the
                                        ; same personality.

(defmacro ems-set-personality-temporarily (start end value
                                                 &rest body)
  "Temporarily set personality.
Argument START   specifies the start of the region to operate on.
Argument END specifies the end of the region.
Argument VALUE is the personality to set temporarily
Argument BODY specifies forms to execute."
  (`
   (unwind-protect
       (progn
         (declare (special voice-lock-mode ))
         (let ((save-voice-lock voice-lock-mode)
               (saved-personality (get-text-property
                                   (, start) 'personality))
               (save-read-only buffer-read-only)
               (buffer-read-only nil )
               (save-inhibit-read-only inhibit-read-only)
               (inhibit-read-only t)
               (save-inhibit-point-motion-hooks (ems-inhibit-point-motion-hooks))
               (inhibit-point-motion-hooks t)
               (modification-flag (buffer-modified-p)))
           (unwind-protect
               (progn
                 (setq voice-lock-mode t )
                 (put-text-property
                  (max (point-min) (, start))
                  (min (point-max) (, end))
                  'personality (, value))
                 (,@ body))
             (put-text-property
              (max (point-min) (, start))
              (min (point-max)  (, end)) 'personality saved-personality)
             (setq buffer-read-only save-read-only
                   inhibit-read-only save-inhibit-read-only
                   inhibit-point-motion-hooks save-inhibit-point-motion-hooks
                   voice-lock-mode save-voice-lock )
             (set-buffer-modified-p modification-flag )))))))

;;}}}
;;{{{ getting and speaking text ranges

(defsubst emacspeak-speak-get-text-range (property)
  "Return text range  starting at point and having the same value as  specified by argument PROPERTY."
  (let ((start (point))
        (end (next-single-property-change (point)
                                          property
                                          (current-buffer)
                                          (point-max))))
    (buffer-substring start end )))

(defun emacspeak-speak-text-range (property)
  "Speak text range identified by this PROPERTY."
  (dtk-speak (emacspeak-speak-get-text-range property)))

;;}}}
;;{{{  Apply audio annotations

;;; prompt for auditory icon with completion

(defsubst ems-ask-for-auditory-icon ()
  "Prompt for an auditory icon."
  (declare (special emacspeak-sounds-table))
  (intern
   (completing-read  "Select sound:"
                     (mapcar
                      (lambda (xx)
                        (let ((x (car xx)))
                          (list
                           (format "%s" x)
                           (format "%s" x ))))
                      emacspeak-sounds-table))))

(defun emacspeak-audio-annotate-paragraphs (&optional prefix)
  "Set property auditory-icon at front of all paragraphs.
Interactive PREFIX arg prompts for sound cue to use"
  (interactive "P")
  (save-excursion
    (goto-char (point-max))
    (ems-modify-buffer-safely
     (let ((sound-cue  (if prefix
                           (ems-ask-for-auditory-icon)
                         'paragraph)))
       (while (not (bobp))
         (backward-paragraph)
         (put-text-property  (1+ (point))
                             (+ 2    (point ))
                             'auditory-icon sound-cue ))))))

(defcustom  emacspeak-speak-paragraph-personality 'paul-animated
  "*Personality used to mark start of paragraph."
  :group 'emacspeak-speak
:type 'symbol)

(defvar emacspeak-speak-voice-annotated-paragraphs nil
  "Records if paragraphs in this buffer have been voice annotated.")
(make-variable-buffer-local
 'emacspeak-speak-voice-annotated-paragraphs)

(defsubst emacspeak-speak-voice-annotate-paragraphs ()
  "Locate paragraphs and voice annotate the first word.
Here, paragraph is taken to mean a chunk of text preceeded by a blank line.
Useful to do this before you listen to an entire buffer."
  (interactive)
  (declare (special emacspeak-speak-paragraph-personality
                    emacspeak-speak-voice-annotated-paragraphs))
  (when emacspeak-speak-paragraph-personality
    (save-excursion
      (goto-char (point-min))
      (let ((start nil)
            (blank-line "\n[ \t\n]*\n"))
        (ems-modify-buffer-safely
         (while (re-search-forward blank-line nil t)
           (skip-syntax-forward " ")
           (setq start (point))
           (unless (get-text-property start 'personality)
             (skip-syntax-forward "^ ")
             (put-text-property start (point)
                                'personality
                                emacspeak-speak-paragraph-personality)))))
      (setq emacspeak-speak-voice-annotated-paragraphs t))))

;;}}}
;;{{{ helper function --prepare completions buffer

(defsubst emacspeak-prepare-completions-buffer()
  (ems-modify-buffer-safely
  (goto-char (point-min))
  (forward-line 3)
  (delete-region (point-min) (point))
  (emacspeak-auditory-icon 'help)))

;;}}}
;;{{{  Actions

;;; Setting value of property 'emacspeak-action to a list
;;; of the form (before | after function)
;;; function to be executed before or after the unit of text at that
;;; point is spoken.

(defvar emacspeak-action-mode nil
  "Determines if action mode is active.
Non-nil value means that any function that is set as the
value of property action is executed when the text at that
point is spoken."

  )

(make-variable-buffer-local 'emacspeak-action-mode)

;;; Record in the mode line
(or (assq 'emacspeak-action-mode minor-mode-alist)
    (setq minor-mode-alist
	  (append minor-mode-alist
		  '((emacspeak-action-mode " Action")))))

;;; Return the appropriate action hook variable that defines actions
;;; for this mode.


(defsubst  emacspeak-action-get-action-hook (mode)
  "Retrieve action hook.
Argument MODE defines action mode."
  (intern (format "emacspeak-%s-actions-hook" mode )))
  

(defun emacspeak-toggle-action-mode  (&optional prefix)
  "Toggle state of  Emacspeak  action mode.
Interactive PREFIX arg means toggle  the global default value, and then set the
current local  value to the result."
  (interactive  "P")
  (declare  (special  emacspeak-action-mode))
  (cond
   (prefix
    (setq-default  emacspeak-action-mode
                   (not  (default-value 'emacspeak-action-mode )))
    (setq emacspeak-action-mode (default-value 'emacspeak-action-mode )))
   (t (make-local-variable'emacspeak-action-mode)
      (setq emacspeak-action-mode
	    (not emacspeak-action-mode ))))
  (when emacspeak-action-mode
    (require 'emacspeak-actions)
    (let ((action-hook (emacspeak-action-get-action-hook  major-mode
                                                          )))
      (and (boundp action-hook)
           (run-hooks action-hook ))))
  (emacspeak-auditory-icon
   (if emacspeak-action-mode 'on 'off))
  (message "Turned %s Emacspeak Action Mode  %s "
           (if emacspeak-action-mode "on" "off" )
	   (if prefix "" "locally")))

;;; Execute action at point
(defsubst emacspeak-handle-action-at-point ()
  "Execute action specified at point."
  (declare (special emacspeak-action-mode ))
  (let ((action-spec (get-text-property (point) 'emacspeak-action )))
    (when (and emacspeak-action-mode action-spec )
      (condition-case nil
          (funcall  action-spec )
        (error (message "Invalid actionat %s" (point )))))))

;;}}}
;;{{{  line, Word and Character echo

(defcustom emacspeak-line-echo nil
  "If t, then emacspeak echoes lines as you type.
You can use \\[emacspeak-toggle-line-echo] to set this
option."
  :group 'emacspeak-speak
  :type 'boolean)

(defun emacspeak-toggle-line-echo (&optional prefix)
  "Toggle state of  Emacspeak  line echo.
Interactive PREFIX arg means toggle  the global default value, and then set the
current local  value to the result."
  (interactive  "P")
  (declare  (special  emacspeak-line-echo ))
  (cond
   (prefix
    (setq-default  emacspeak-line-echo
                   (not  (default-value 'emacspeak-line-echo )))
    (setq emacspeak-line-echo (default-value 'emacspeak-line-echo )))
   (t (make-local-variable 'emacspeak-line-echo)
      (setq emacspeak-line-echo
	    (not emacspeak-line-echo ))))
  (emacspeak-auditory-icon
   (if emacspeak-line-echo 'on 'off))
  (message "Turned %s line echo%s "
           (if emacspeak-line-echo "on" "off" )
	   (if prefix "" " locally")))

(defcustom emacspeak-word-echo t
  "If t, then emacspeak echoes words as you type.
You can use \\[emacspeak-toggle-word-echo] to toggle this
option."
  :group 'emacspeak-speak
  :type 'boolean)

(defun emacspeak-toggle-word-echo (&optional prefix)
  "Toggle state of  Emacspeak  word echo.
Interactive PREFIX arg means toggle  the global default value, and then set the
current local  value to the result."
  (interactive  "P")
  (declare  (special  emacspeak-word-echo ))
  (cond
   (prefix
    (setq-default  emacspeak-word-echo
                   (not  (default-value 'emacspeak-word-echo )))
    (setq emacspeak-word-echo (default-value 'emacspeak-word-echo )))
   (t (make-local-variable 'emacspeak-word-echo )
      (setq emacspeak-word-echo
	    (not emacspeak-word-echo ))))
  (emacspeak-auditory-icon
   (if emacspeak-word-echo 'on 'off ))
  (message "Turned %s word echo%s "
           (if emacspeak-word-echo "on" "off" )
	   (if prefix "" " locally")))

(defcustom emacspeak-character-echo t
  "If t, then emacspeak echoes characters  as you type.
You can 
use \\[emacspeak-toggle-character-echo] to toggle this
setting."
  :group 'emacspeak-speak
  :type 'boolean)

(defun emacspeak-toggle-character-echo (&optional prefix)
  "Toggle state of  Emacspeak  character echo.
Interactive PREFIX arg means toggle  the global default value, and then set the
current local  value to the result."
  (interactive  "P")
  (declare  (special  emacspeak-character-echo ))
  (cond
   (prefix
    (setq-default  emacspeak-character-echo
                   (not  (default-value 'emacspeak-character-echo )))
    (setq emacspeak-character-echo (default-value 'emacspeak-character-echo )))
   (t (make-local-variable 'emacspeak-character-echo)
      (setq emacspeak-character-echo
	    (not emacspeak-character-echo ))))
  (emacspeak-auditory-icon
   (if emacspeak-character-echo 'on 'off))
  (message "Turned %s character echo%s "
           (if emacspeak-character-echo "on" "off" )
	   (if prefix "" " locally")))

;;}}}
;;{{{ Showing the point:

(defcustom emacspeak-show-point nil
  " If T, then command  `emacspeak-speak-line' indicates position of point by an
aural highlight.  You can use 
command `emacspeak-toggle-show-point' bound to
\\[emacspeak-toggle-show-point] to toggle this setting."
  :group 'emacspeak-speak
  :type 'boolean)

(defun emacspeak-toggle-show-point (&optional prefix)
  "Toggle state of  Emacspeak-show-point.
Interactive PREFIX arg means toggle  the global default value, and then set the
current local  value to the result."
  (interactive  "P")
  (declare  (special  emacspeak-show-point ))
  (cond
   (prefix
    (setq-default  emacspeak-show-point
                   (not  (default-value 'emacspeak-show-point )))
    (setq emacspeak-show-point (default-value 'emacspeak-show-point )))
   (t (make-local-variable 'emacspeak-show-point)
      (setq emacspeak-show-point
	    (not emacspeak-show-point ))))
  (emacspeak-auditory-icon
   (if emacspeak-show-point 'on 'off))
  (message "Turned %s show point %s "
           (if emacspeak-show-point "on" "off" )
	   (if prefix "" " locally")))

;;}}}
;;{{{ compute percentage into the buffer:

(defsubst emacspeak-get-current-percentage-into-buffer ()
  "Return percentage of position into current buffer."
  (let* ((pos (point))
	 (total (buffer-size))
	 (percent (if (> total 50000)
		      ;; Avoid overflow from multiplying by 100!
		      (/ (+ (/ total 200) (1- pos)) (max (/ total 100) 1))
		    (/ (+ (/ total 2) (* 100 (1- pos))) (max total 1)))))
    percent))

;;}}}
;;{{{  indentation:

(defcustom emacspeak-audio-indentation nil
  "Option indicating if line indentation is cued.
If non-nil , then speaking a line indicates its indentation.  
You can use  command `emacspeak-toggle-audio-indentation' bound
to \\[emacspeak-toggle-audio-indentation] to toggle this
setting.."
:group 'emacspeak-speak
  :type 'boolean)

(make-variable-buffer-local 'emacspeak-audio-indentation)

;;; Indicate indentation.
;;; Argument indent   indicates number of columns to indent.

(defsubst emacspeak-indent (indent)
  "Return indentation for this line as specified by argument INDENT."
  (when (> indent 1 )
    (let ((duration (+ 50 (* 20  indent ))))
      (dtk-tone  250 duration))))

(defvar emacspeak-audio-indentation-methods
  '(("speak" . "speak")
    ("tone" . "tone"))
  "Possible methods of indicating indentation.")

(defcustom emacspeak-audio-indentation-method "speak"
  "*Current technique used to cue indentation.  Default is
`speak'.  You can specify `tone' for producing a beep
indicating the indentation.  Automatically becomes local in
any buffer where it is set."
:group 'emacspeak-speak
:type '(choice
        (const "speak")
        (const "tone")))

(make-variable-buffer-local
 'emacspeak-audio-indentation-method)

(defun emacspeak-toggle-audio-indentation (&optional prefix)
  "Toggle state of  Emacspeak  audio indentation.
Interactive PREFIX arg means toggle  the global default value, and then set the
current local  value to the result.
Specifying the method of indentation as `tones'
results in the Dectalk producing a tone whose length is a function of the
line's indentation.  Specifying `speak'
results in the number of initial spaces being spoken."
  (interactive  "P")
  (declare  (special  emacspeak-audio-indentation
                      emacspeak-audio-indentation-methods ))
  (cond
   (prefix
    (setq-default  emacspeak-audio-indentation
                   (not  (default-value 'emacspeak-audio-indentation )))
    (setq emacspeak-audio-indentation (default-value 'emacspeak-audio-indentation )))
   (t (setq emacspeak-audio-indentation
	    (not emacspeak-audio-indentation ))))
  (when emacspeak-audio-indentation
    (setq emacspeak-audio-indentation emacspeak-audio-indentation-method)
    (and prefix
         (setq-default emacspeak-audio-indentation
                       emacspeak-audio-indentation )))
  (emacspeak-auditory-icon
   (if emacspeak-audio-indentation 'on 'off))
  (message "Turned %s audio indentation %s "
           (if emacspeak-audio-indentation "on" "off" )
	   (if prefix "" "locally")))

;;}}}
;;{{{  sync emacspeak and TTS:

(defsubst   emacspeak-dtk-sync ()
  "Bring emacspeak and dtk in sync."
  (dtk-interp-sync))

;;}}}
;;{{{ Core speech functions:

;;{{{  Speak units of text

(defsubst emacspeak-speak-region (start end )
  "Speak region.
Argument START  and END specify region to speak."
  (interactive "r" )
  (declare (special emacspeak-speak-voice-annotated-paragraphs))
  (when (and voice-lock-mode
             (not emacspeak-speak-voice-annotated-paragraphs))
    (save-restriction
      (narrow-to-region start end )
      (emacspeak-speak-voice-annotate-paragraphs)))
  (emacspeak-handle-action-at-point)
  (dtk-speak (buffer-substring start end )))

(defcustom emacspeak-horizontal-rule "^\\([=_-]\\)\\1+$"
  "*Regular expression to match horizontal rules in ascii
text."
  :group 'emacspeak-speak
:type 'string)

(put 'emacspeak-horizontal-rule 'variable-interactive
     "sEnterregular expression to match horizontal rule: ")


(defcustom emacspeak-decoration-rule
  "^[ \t!@#$%^&*()<>|_=+/\\,.;:-]+$"
  "*Regular expressions to match lines that are purely
decorative ascii."
  :group 'emacspeak-speak
:type 'string)

(put 'emacspeak-decoration-rule 'variable-interactive
     "sEnterregular expression to match lines that are decorative ASCII: ")

(defcustom emacspeak-unspeakable-rule
  "^[^0-9a-zA-Z]+$"
  "*Pattern to match lines of special chars.
This is a regular expression that matches lines containing only
non-alphanumeric characters.  emacspeak will generate a tone
instead of speaking such lines when punctuation mode is set
to some."
  :group 'emacspeak-speak
:type 'string)

(put 'emacspeak-unspeakable-rule 'variable-interactive
     "sEnterregular expression to match unspeakable lines: ")
(defcustom emacspeak-speak-maximum-line-length  512
  "*Threshold for determining `long' lines.
Emacspeak will ask for confirmation before speaking lines
that are longer than this length.  This is to avoid accidentally
opening a binary file and torturing the speech synthesizer
with a long string of gibberish."
  :group 'emacspeak-speak
:type 'number)



;;{{{ filtering columns 

(defcustom emacspeak-speak-line-column-filter nil
  "*List that specifies columns to be filtered.
The list when set holds pairs of start-col.end-col pairs 
that specifies the columns that should not be spoken.
Each column contains a single character --this is inspired
by cut -c on UNIX."
  :group 'emacspeak-speak
:type 'list)

(defvar emacspeak-speak-filter-table (make-hash-table)
  "Hash table holding persistent filters.")

(make-variable-buffer-local 'emacspeak-speak-line-column-filter)

(defsubst emacspeak-speak-line-apply-column-filter (line)
  (declare (special emacspeak-speak-line-column-filter))
  (let ((filter emacspeak-speak-line-column-filter)
        (l (1+ (length line)))
        (pair nil))
    (while filter 
      (setq pair (pop filter))
      (when (and (< (first pair) l)
                 (< (second pair) l))
        (put-text-property (first pair)
                           (second pair)
                           'personality 'inaudible
                           line)))
    line))

(defsubst emacspeak-speak-persist-filter-entry (k v)
  (insert 
   (format
    "(cl-puthash 
(intern \"%s\")
 '%s
 emacspeak-speak-filter-table)\n" k v )))

(defvar emacspeak-speak-filter-persistent-store
  (expand-file-name ".filters"
                    emacspeak-resource-directory)
  "File where emacspeak filters are persisted.")

(defvar emacspeak-speak-filters-loaded-p nil
  "Records if we    have loaded filters in this session.")


(defun emacspeak-speak-lookup-persistent-filter (key)
  "Lookup a filter setting we may have persisted."
  (declare (special emacspeak-speak-filter-table))
  (gethash  (intern key) emacspeak-speak-filter-table))

(defun emacspeak-speak-set-persistent-filter (key value)
  "Persist filter setting for future use."
  (declare (special emacspeak-speak-filter-table))
  (setf (gethash  (intern key) emacspeak-speak-filter-table)
        value))


(defun emacspeak-speak-persist-filter-settings ()
  "Persist emacspeak filter settings for future sessions."
  (declare (special emacspeak-speak-filter-persistent-store
                    emacspeak-speak-filter-table))
  (let ((buffer (find-file-noselect
                 emacspeak-speak-filter-persistent-store)))
    (save-excursion
      (set-buffer buffer)
      (erase-buffer)
      (maphash 'emacspeak-speak-persist-filter-entry
               emacspeak-speak-filter-table)
      (save-buffer)
      (kill-buffer buffer))))



(defsubst emacspeak-speak-load-filter-settings ()
  "Load emacspeak filter settings for future sessions."
  (declare (special emacspeak-speak-filter-persistent-store
                    emacspeak-speak-filter-table
                    emacspeak-speak-filters-loaded-p))
  (unless emacspeak-speak-filters-loaded-p
    (load-file emacspeak-speak-filter-persistent-store)
    (setq emacspeak-speak-filters-loaded-p t)
    (add-hook 'emacspeak-speak-persist-filter-settings
              'kill-emacs-hook)))

(defun emacspeak-speak-line-set-column-filter (filter)
  "Set up filter for selectively ignoring portions of lines.
The filter is specified as a list of pairs.
For example, to filter out columns 1 -- 10 and 20 -- 25,
specify filter as 
((0 9) (20 25)). Filter settings are persisted across
sessions.
A persisted filter is used as the default when prompting for
a filter.
This allows one to accumulate a set of filters for specific
files like /var/adm/messages and /var/adm/maillog over time."
  (interactive
   (list 
    (read-minibuffer "Specify columns to filter out: "
                     (format "%s"
                             (if  (buffer-file-name )
                                 (emacspeak-speak-lookup-persistent-filter (buffer-file-name))
                               "")))))
  (cond
   ((and (listp filter)
         (every 
          (lambda (l)
            (and (listp l)
                 (= 2 (length l))))
          filter))
    (setq emacspeak-speak-line-column-filter filter)
    (when (buffer-file-name)
      (emacspeak-speak-set-persistent-filter (buffer-file-name) filter)))
   (t 
    (message "Unset column filter")
    (setq emacspeak-speak-line-column-filter nil))))

;;}}}
(defun emacspeak-speak-line (&optional arg)
  "Speaks current line.
With prefix ARG, speaks the rest of the line
from point.  Negative prefix optional arg speaks from start of line
  to point.  Voicifies if option `voice-lock-mode' is on.  Indicates
  indentation with a tone if audio indentation is in use.  Indicates
  position of point with an aural highlight if option
  `emacspeak-show-point' is turned on --see command `emacspeak-show-point'
  bound to \\[emacspeak-show-point].
Lines that start hidden blocks of text,
e.g.  outline header lines,
or header lines of blocks created by command
`emacspeak-hide-or-expose-block' are indicated with auditory icon ellipses."
  (interactive "P")
  (declare (special voice-lock-mode
                    outline-minor-mode folding-mode
                    emacspeak-speak-maximum-line-length
                    emacspeak-use-midi
                    emacspeak-show-point
                    emacspeak-decoration-rule
                    emacspeak-horizontal-rule
                    emacspeak-unspeakable-rule emacspeak-audio-indentation))
  (when (listp arg) (setq arg (car arg )))
  (save-excursion
    (let ((start  nil)
          (end nil )
          (dtk-stop-immediately dtk-stop-immediately)
          (inhibit-point-motion-hooks t)
          (line nil)
          (auditory-icon nil)
          (orig (point))
          (indent nil))
      (beginning-of-line)
      (emacspeak-handle-action-at-point)
      (setq start (point))
      (when (and emacspeak-audio-indentation
                 (null arg ))
        (save-excursion
          (back-to-indentation )
          (setq indent  (current-column ))))
      (end-of-line)
      (setq end (point))
      (goto-char orig)
      (cond
       ((null arg))
       ((> arg 0) (setq start orig))
       (t (setq end orig)))
      (when (and emacspeak-audio-indentation
                 (string= emacspeak-audio-indentation "tone")
                 (null arg ))
        (setq dtk-stop-immediately nil )
        (emacspeak-indent indent ))
      (if emacspeak-show-point
          (ems-set-personality-temporarily
           (point) (1+ (point))
           'paul-animated
           (setq line
                 (buffer-substring  start end )))
        (setq line (buffer-substring start end )))
      (when (get-text-property  start 'emacspeak-hidden-block)
        (emacspeak-auditory-icon 'ellipses))
      (cond
       ((string= ""  (buffer-substring start end)) ;blank line
        (if dtk-stop-immediately (dtk-stop))
        (dtk-tone 250   120 'force)
        (when emacspeak-use-midi-icons
          (emacspeak-midi-icon 'empty-line)))
       ((string-match  "^[ \t]+$" (buffer-substring start end )) ;only white space
        (if dtk-stop-immediately (dtk-stop))
        (dtk-tone 250   100 'force)
        (when emacspeak-use-midi-icons
          (emacspeak-midi-icon 'blank-line)))
       ((and
         (not (string= "all" dtk-punctuation-mode))
         (string-match  emacspeak-horizontal-rule
                        (buffer-substring start end))) ;horizontal rule
        (if dtk-stop-immediately (dtk-stop))
        (dtk-tone 350   100 'force)
        (when emacspeak-use-midi-icons
        (emacspeak-midi-icon 'horizontal-rule)))
       ((and
         (not (string= "all" dtk-punctuation-mode))
         (string-match  emacspeak-decoration-rule
                        (buffer-substring start end)) ) ;decorative rule
        (if dtk-stop-immediately (dtk-stop))
        (dtk-tone 450   100 'force)
        (when emacspeak-use-midi-icons
          (emacspeak-midi-icon 'decorative-rule)))
       ((and
         (not (string= "all" dtk-punctuation-mode))
         (string-match  emacspeak-unspeakable-rule
                        (buffer-substring start end)) ) ;unspeakable rule
        (if dtk-stop-immediately (dtk-stop))
        (dtk-tone 550   100 'force)
        (when emacspeak-use-midi-icons
          (emacspeak-midi-icon 'unspeakable-rule)))
       (t
        (let ((l (length line)))
          (when (or
                 (and (boundp 'outline-minor-mode) outline-minor-mode)
                 (and (boundp 'folding-mode) folding-mode)
                 (< l emacspeak-speak-maximum-line-length)
                 (get-text-property start 'emacspeak-speak-this-long-line)
                 (y-or-n-p
                  (format "Speak  this  %s long line? "
                          l)))
            (unless (or
                     (and (boundp 'outline-minor-mode) outline-minor-mode)
                     (and (boundp 'folding-mode) folding-mode)
                     (< l emacspeak-speak-maximum-line-length))
              ;; record the y answer
              (ems-modify-buffer-safely
               (put-text-property start end
                                  'emacspeak-speak-this-long-line t)))
           (when (and (null arg)
                      emacspeak-speak-line-column-filter)
             (setq line
                   (emacspeak-speak-line-apply-column-filter line)))
            (if (and (string= "speak" emacspeak-audio-indentation )
                     (null arg )
                     indent
                     (> indent 0))
                (progn
                  (setq indent (format "indent %d" indent))
                  (put-text-property   0 (length indent)
                                       'personality 'indent-voice  indent )
                  (setq auditory-icon (get-text-property 0  'auditory-icon line))
                  (when auditory-icon
                    (put-text-property   0 (length indent)
                                         'auditory-icon auditory-icon  indent ))
                  (dtk-speak (concat indent line)))
              (dtk-speak line)))))))))

(defvar emacspeak-speak-last-spoken-word-position nil
  "Records position of the last word that was spoken.
Local to each buffer.  Used to decide if we should spell the word
rather than speak it.")

(make-variable-buffer-local 'emacspeak-speak-last-spoken-word-position)
(defsubst emacspeak-speak-spell-word (word)
  "Spell WORD."
  (declare (special voice-lock-mode))
  (let ((result "")
        (char-string ""))
    (loop for char across word
          do
          (setq char-string (format "%c " char))
          (when (and (<= ?A char)
                     (<= char ?Z))
            (if voice-lock-mode
                (put-text-property 0 1
                                   'personality 'paul-animated
                                   char-string)
              (setq char-string (format "cap %s " char-string))))
          (setq result
                (concat result
                        char-string)))
    (dtk-speak result)))

(defun emacspeak-speak-spell-current-word ()
  "Spell word at  point."
  (interactive)
  (emacspeak-speak-spell-word (word-at-point)))
  
(defun emacspeak-speak-word (&optional arg)
  "Speak current word.
With prefix ARG, speaks the rest of the word from point.
Negative prefix arg speaks from start of word to point.
If executed  on the same buffer position a second time, the word is
spelt instead of being spoken."
  (interactive "P")
  (declare (special voice-lock-mode
                    emacspeak-speak-last-spoken-word-position))
  (when (listp arg) (setq arg (car arg )))
  (emacspeak-handle-action-at-point)
  (save-excursion
        (let ((orig (point))
              (inhibit-point-motion-hooks t)
              (start nil)
              (end nil)
              (speaker 'dtk-speak))
          (forward-word 1)
          (setq end (point))
          (backward-word 1)
          (setq start (min orig  (point)))
          (cond
           ((null arg ))
           ((> arg 0) (setq start orig))
           ((< arg 0) (setq end orig )))
          ;; select speak or spell
          (cond
           ((and (interactive-p)
                 (eq emacspeak-speak-last-spoken-word-position orig))
            (setq speaker 'emacspeak-speak-spell-word)
            (setq emacspeak-speak-last-spoken-word-position nil))
           (t (setq  emacspeak-speak-last-spoken-word-position orig)))
          (funcall speaker  (buffer-substring  start end )))))

(defsubst emacspeak-is-alpha-p (c)
  "Check if argument C is an alphabetic character."
  (= 119 (char-syntax c)))

;;{{{  phonemic table

(defvar emacspeak-char-to-phonetic-table
  '(
    ("1"  . "one")
    ("2" .  "two")
    ("3" .  "three")
    ("4" .  "four")
    ("5" .  "five")
    ("6" .  "six")
    ("7" .  "seven")
    ("8" .  "eight")
    ("9" .  "nine")
    ("0".  "zero")
    ("a" . "alpha" )
    ("b" . "bravo")
    ("c" .  "charlie")
    ("d" . "delta")
    ("e" . "echo")
    ("f" . "foxtrot")
    ("g" . "golf")
    ("h" . "hotel")
    ("i" . "india")
    ("j" . "juliet")
    ("k" . "kilo")
    ("l" . "lima")
    ("m" . "mike")
    ("n" . "november")
    ("o" . "oscar")
    ("p" . "poppa")
    ("q" . "quebec")
    ("r" . "romeo")
    ("s" . "sierra")
    ("t" . "tango")
    ("u" . "unicorn")
    ("v" . "victor")
    ("w" . "whisky")
    ("x" . "xray")
    ("y" . "yankee")
    ("z" . "zulu")
    ("A" . "cap alpha" )
    ("B" . "cap bravo")
    ("C" .  "cap charlie")
    ("D" . "cap delta")
    ("E" . "cap echo")
    ("F" . "cap foxtrot")
    ("G" . "cap golf")
    ("H" . "cap hotel")
    ("I" . "cap india")
    ("J" . "cap juliet")
    ("K" . "cap kilo")
    ("L" . "cap lima")
    ("M" . "cap mike")
    ("N" . "cap november")
    ("O" . "cap oscar")
    ("P" . "cap poppa")
    ("Q" . "cap quebec")
    ("R" . "cap romeo")
    ("S" . "cap sierra")
    ("T" . "cap tango")
    ("U" . "cap unicorn")
    ("V" . "cap victor")
    ("W" . "cap whisky")
    ("X" . "cap xray")
    ("Y" . "cap yankee")
    ("Z" . "cap zulu"))
  "Mapping from characters to their phonemic equivalents.")


(defun emacspeak-get-phonetic-string (char)
  "Return the phonetic string for this CHAR or its upper case equivalent.
char is assumed to be one of a--z."
  (declare (special emacspeak-char-to-phonetic-table))
  (let ((char-string   (char-to-string char )))
    (or   (cdr
           (assoc char-string emacspeak-char-to-phonetic-table ))
          " ")))

;;}}}
(defun emacspeak-speak-char (&optional prefix)
  "Speak character under point.
Pronounces character phonetically unless  called with a PREFIX arg."
  (interactive "P")
  (let ((dtk-stop-immediately t )
        (char  (following-char )))
    (when char
      (emacspeak-handle-action-at-point)
      (cond
       ((and (not prefix)
             (emacspeak-is-alpha-p char))
        (dtk-speak (emacspeak-get-phonetic-string char )))
       ((emacspeak-is-alpha-p char) (dtk-letter (char-to-string char )))
       (t (dtk-dispatch
           (dtk-char-to-speech char )))))))

(defun emacspeak-speak-this-char (char)
  "Speak this CHAR."
  (let ((dtk-stop-immediately t ))
    (when char
      (emacspeak-handle-action-at-point)
      (cond
       ((emacspeak-is-alpha-p char) (dtk-letter (char-to-string char )))
       (t (dtk-dispatch
           (dtk-char-to-speech char )))))))


;;{{{ emacspeak-speak-display-char

(defun emacspeak-speak-display-char  (&optional prefix)
  "Display char under point using current speech display table.
Behavior is the same as command `emacspeak-speak-char'
bound to \\[emacspeak-speak-char]
for characters in the range 0--127.
Optional argument PREFIX  specifies that the character should be spoken phonetically."
  (interactive "P")
  (declare (special dtk-display-table ))
  (let ((char (following-char )))
    (cond
     ((and dtk-display-table
           (> char 127))
      (dtk-dispatch (aref dtk-display-table char)))
     (t (emacspeak-speak-char prefix)))))

;;}}}
;;{{{ emacspeak-speak-set-display-table

(defvar emacspeak-speak-display-table-list
  '(("iso ascii" . "iso ascii")
    ("default" . "default"))
  "Available speech display tables.")

(defun emacspeak-speak-set-display-table(&optional prefix)
  "Sets up buffer specific speech display table that controls how
special characters are spoken. Interactive prefix argument causes
setting to be global."
  (interactive "P")
  (declare (special dtk-display-table
                    emacspeak-speak-display-table-list))
  (let ((type (completing-read
               "Select speech display table: "
               emacspeak-speak-display-table-list
               nil t ))
        (table nil))
    (cond
     ((string= "iso ascii" type)
      (setq table dtk-iso-ascii-character-to-speech-table))
     (t (setq table nil)))
    (cond
     (prefix
      (setq-default dtk-display-table table )
      (setq dtk-display-table table))
     (t (setq dtk-display-table table)))))

;;}}}
(defun emacspeak-speak-sentence (&optional arg)
  "Speak current sentence.
With prefix ARG, speaks the rest of the sentence  from point.
Negative prefix arg speaks from start of sentence to point."
  (interactive "P" )
  (when (listp arg) (setq arg (car arg )))
  (save-excursion
    (let ((orig (point))
          (inhibit-point-motion-hooks t)
          (start nil)
          (end nil))
      (forward-sentence 1)
      (setq end (point))
      (backward-sentence 1)
      (setq start (point))
      (emacspeak-handle-action-at-point)
      (cond
       ((null arg ))
       ((> arg 0) (setq start orig))
       ((< arg 0) (setq end orig )))
      (dtk-speak (buffer-substring start end )))))


(defun emacspeak-speak-sexp (&optional arg)
  "Speak current sexp.
With prefix ARG, speaks the rest of the sexp  from point.
Negative prefix arg speaks from start of sexp to point.
If option  `voice-lock-mode' is on, then uses the personality."
  (interactive "P" )
  (when (listp arg) (setq arg (car arg )))
  (save-excursion
    (let ((orig (point))
          (inhibit-point-motion-hooks t)
          (start nil)
          (end nil))
      (condition-case nil
          (forward-sexp 1)
        (error nil ))
      (setq end (point))
      (condition-case nil
          (backward-sexp 1)
        (error nil ))
      (setq start (point))
      (emacspeak-handle-action-at-point)
      (cond
       ((null arg ))
       ((> arg 0) (setq start orig))
       ((< arg 0) (setq end orig )))
      (dtk-speak (buffer-substring  start end )))))

(defun emacspeak-speak-page (&optional arg)
  "Speak a page.
With prefix ARG, speaks rest of current page.
Negative prefix arg will read from start of current page to point.
If option  `voice-lock-mode' is on, then it will use any defined personality."
  (interactive "P")
  (when (listp arg) (setq arg (car arg )))
  (save-excursion
    (let ((orig (point))
          (inhibit-point-motion-hooks t)
          (start nil)
          (end nil))
      (mark-page)
      (setq start  (point))
      (emacspeak-handle-action-at-point)
      (setq end  (mark))
      (cond
       ((null arg ))
       ((> arg 0) (setq start orig))
       ((< arg 0) (setq end orig )))
      (dtk-speak (buffer-substring start end )))))


(defun emacspeak-speak-paragraph(&optional arg)
  "Speak paragraph.
With prefix arg, speaks rest of current paragraph.
Negative prefix arg will read from start of current paragraph to point.
If voice-lock-mode is on, then it will use any defined personality. "
  (interactive "P")
  (when (listp arg) (setq arg (car arg )))
  (save-excursion
    (let ((orig (point))
          (inhibit-point-motion-hooks t)
          (start nil)
          (end nil))
      (forward-paragraph 1)
      (setq end (point))
      (backward-paragraph 1)
      (setq start (point))
      (emacspeak-handle-action-at-point)
      (cond
       ((null arg ))
       ((> arg 0) (setq start orig))
       ((< arg 0) (setq end orig )))
      (dtk-speak (buffer-substring  start end )))))

;;}}}
;;{{{  Speak buffer objects such as help, completions minibuffer etc

(defun emacspeak-speak-buffer (&optional arg)
  "Speak current buffer  contents.
With prefix ARG, speaks the rest of the buffer from point.
Negative prefix arg speaks from start of buffer to point.
 If voice lock mode is on, the paragraphs in the buffer are
voice annotated first,  see command `emacspeak-speak-voice-annotate-paragraphs'."
  (interactive "P" )
  (declare (special emacspeak-speak-voice-annotated-paragraphs))
  (when (and voice-lock-mode
             (not emacspeak-speak-voice-annotated-paragraphs))
    (emacspeak-speak-voice-annotate-paragraphs))
  (when (listp arg) (setq arg (car arg )))
  (let ((start nil )
        (end nil))
    (cond
     ((null arg)
      (setq start (point-min)
            end (point-max)))
     ((> arg 0)
      (setq start (point)
            end (point-max)))
     (t (setq start (point-min)
              end (point))))
    (dtk-speak (buffer-substring start end ))))
(defun emacspeak-speak-front-of-buffer()
  "Speak   the buffer from start to   point"
  (interactive)
  (emacspeak-speak-buffer -1))

(defun emacspeak-speak-rest-of-buffer()
  "Speak remainder of the buffer starting at point"
  (interactive)
  (emacspeak-auditory-icon 'select-object)
  (emacspeak-speak-buffer 1))

(defun emacspeak-speak-help(&optional arg)
  "Speak help buffer if one present.
With prefix arg, speaks the rest of the buffer from point.
Negative prefix arg speaks from start of buffer to point."
  (interactive "P")
  (declare (special voice-lock-mode
                    help-buffer-list))
  (let ((help-buffer
         (if (boundp 'help-buffer-list)
             (car help-buffer-list)
           (get-buffer "*Help*"))))
    (cond
     (help-buffer
      (save-excursion
	(set-buffer help-buffer)
        (voice-lock-mode 1)
	(emacspeak-speak-buffer arg )))
     (t (dtk-speak "First ask for help" )))))

(defun emacspeak-speak-completions()
  "Speak completions  buffer if one present."
  (interactive )
  (let ((completions-buffer (get-buffer "*Completions*"))
        (start nil)
        (end nil )
        (continue t))
    (cond
     ((and completions-buffer
           (window-live-p (get-buffer-window completions-buffer )))
      (save-window-excursion
        (save-match-data
          (select-window  (get-buffer-window completions-buffer ))
          (goto-char (point-min))
          (forward-line 3)
          (while continue
            (setq start (point)
                  end (or  (re-search-forward "\\( +\\)\\|\n"  (point-max) t)
                           (point-max )))
            (dtk-speak (buffer-substring start end ) t) ;wait
            (setq continue  (sit-for 1))
            (if (eobp) (setq continue nil )))) ;end while
        (discard-input)
        (goto-char start )
        (choose-completion )))
     (t (dtk-speak "No completions" )))))

(defun emacspeak-speak-minibuffer(&optional arg)
  "Speak the minibuffer contents
 With prefix arg, speaks the rest of the buffer from point.
Negative prefix arg speaks from start of buffer to point."
  (interactive "P" )
  (let ((minibuff (window-buffer (minibuffer-window ))))
    (save-excursion
      (set-buffer minibuff)
      (emacspeak-speak-buffer arg))))
(unless (fboundp 'next-completion)
  (progn
    (defun next-completion (n)
      "Move to the next item in the completion list.
WIth prefix argument N, move N items (negative N means move backward)."
      (interactive "p")
      (while (and (> n 0) (not (eobp)))
        (let ((prop (get-text-property (point) 'mouse-face))
              (end (point-max)))
          ;; If in a completion, move to the end of it.
          (if prop
              (goto-char (next-single-property-change (point) 'mouse-face nil end)))
          ;; Move to start of next one.
          (goto-char (next-single-property-change (point) 'mouse-face nil end)))
        (setq n (1- n)))
      )

    (defun previous-completion (n)
      "Move to the previous item in the completion list."
      (interactive "p")
      (setq n (- n ))
      (while (and (< n 0) (not (bobp)))
        (let ((prop (get-text-property (1- (point)) 'mouse-face))
              (end (point-min)))
          ;; If in a completion, move to the start of it.
          (if prop
              (goto-char (previous-single-property-change
                          (point) 'mouse-face nil end)))
          ;; Move to end of the previous completion.
          (goto-char (previous-single-property-change (point) 'mouse-face nil end))
          ;; Move to the start of that one.
          (goto-char (previous-single-property-change (point) 'mouse-face nil end)))
        (setq n (1+ n))))


    (declaim (special completion-list-mode-map))
    (or completion-list-mode-map
        (make-sparse-keymap ))
    (define-key completion-list-mode-map '[right] 'next-completion)
    (define-key completion-list-mode-map '[left] 'previous-completion)
    ));; end emacs pre-19.30 specials



(defun emacspeak-get-current-completion-from-completions  ()
  "Return the completion string under point in the *Completions* buffer."
  (let (beg end)
    (if (and (not (eobp)) (get-text-property (point) 'mouse-face))
	(setq end (point) beg (1+ (point))))
    (if (and (not (bobp)) (get-text-property (1- (point)) 'mouse-face))
	(setq end (1- (point)) beg (point)))
    (if (null beg)
	(error "No current  completion "))
    (setq beg (or
               (previous-single-property-change beg 'mouse-face)
               (point-min)))
    (setq end (or (next-single-property-change end 'mouse-face) (point-max)))
    (buffer-substring beg end)))

;;}}}

;;}}}
;;{{{ mail check

(defcustom emacspeak-mail-spool-file
  (expand-file-name
   (user-login-name)
   (if (boundp 'rmail-spool-directory)
       rmail-spool-directory
     "/usr/spool/mail/"))
  "Mail spool file examined  to alert you about newly
arrived mail."
  :type '(file :tag "Mail drop location")
  :group 'emacspeak-speak)
               
  
(defsubst emacspeak-get-file-modification-time (filename)
  "Return file modification time for file FILENAME."
  (or                                (nth 5 (file-attributes filename ))
                                     0))

(defsubst emacspeak-get-file-size (filename)
  "Return file size for file FILENAME."
  (or (nth 7 (file-attributes filename))
      0))

(defvar emacspeak-mail-last-alerted-time 0
  "Least  significant 16 digits of the time when mail alert was last issued.
Alert the user only if mail has arrived since this time in the future.")

(defsubst emacspeak-mail-get-last-mail-arrival-time ()
  "Return time when mail was last checked."
  (declare (special emacspeak-mail-spool-file))
  (condition-case                                nil

      (nth
       1(emacspeak-get-file-modification-time emacspeak-mail-spool-file))
    (error 0)))
                                     

(defun emacspeak-mail-alert-user ()
  "Alerts user about the arrival of new mail."
  (declare (special emacspeak-mail-last-alerted-time
                    emacspeak-mail-spool-file))
  (let ((mod-time (emacspeak-mail-get-last-mail-arrival-time))
        (size (emacspeak-get-file-size emacspeak-mail-spool-file)))
    (cond
     ((and (> mod-time emacspeak-mail-last-alerted-time)
           (> size 0))
      (emacspeak-auditory-icon 'new-mail)
      (setq emacspeak-mail-last-alerted-time mod-time ))
     (t(setq emacspeak-mail-last-alerted-time mod-time )
       nil))))

(defcustom emacspeak-mail-alert t
  "*Option to indicate cueing of new mail.
If t, emacspeak will alert you about newly arrived mail
with an auditory icon when
displaying the mode line.
You can use command 
`emacspeak-toggle-mail-alert' bound to
\\[emacspeak-toggle-mail-alert] to set this option."
  :group 'emacspeak-speak
:type 'boolean)

(defun emacspeak-toggle-mail-alert (&optional prefix)
  "Toggle state of  Emacspeak  mail alert.
Interactive PREFIX arg means toggle  the global default value, and then set the
current local  value to the result.
Turning on this option results in Emacspeak producing an auditory icon
indicating the arrival  of new mail when displaying the mode line."
  (interactive  "P")
  (declare  (special  emacspeak-mail-alert))
  (cond
   (prefix
    (setq-default  emacspeak-mail-alert
                   (not  (default-value 'emacspeak-mail-alert )))
    (setq emacspeak-mail-alert (default-value 'emacspeak-mail-alert )))
   (t (make-local-variable'emacspeak-mail-alert)
      (setq emacspeak-mail-alert
	    (not emacspeak-mail-alert ))))
  (emacspeak-auditory-icon
   (if emacspeak-mail-alert 'on 'off))
  (message "Turned %s mail alert  %s "
           (if emacspeak-mail-alert "on" "off" )
	   (if prefix "" "locally")))

;;}}}
;;{{{  Speak mode line information

;;;compute current line number
(defsubst emacspeak-get-current-line-number()
  (let ((start (point)))
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        (+ 1 (count-lines start (point)))))))

;;; make line-number-mode buffer local
(declaim (special line-number-mode))
(make-variable-buffer-local 'line-number-mode)
(setq-default line-number-mode nil)


;;; make column-number-mode buffer local
(declaim (special column-number-mode))
(make-variable-buffer-local 'column-number-mode)
(setq-default column-number-mode nil)
;;{{{ tone based  mode line speaker
(defvar emacspeak-which-function-mode  nil
  "*If T, speaking mode line speaks the name of function containing point.")

(make-variable-buffer-local 'emacspeak-which-function-mode)

(defun emacspeak-toggle-which-function (&optional prefix)
  "Toggle state of  Emacspeak  which function mode.
Interactive PREFIX arg means toggle  the global default value, and then set the
current local  value to the result."
  (interactive  "P")
  (declare  (special  emacspeak-which-function-mode
semantic-toplevel-bovine-cache ))
  (require 'which-func)
  (cond
   (prefix
    (setq-default  emacspeak-which-function-mode
                   (not  (default-value 'emacspeak-which-function-mode )))
    (setq emacspeak-which-function-mode (default-value 'emacspeak-which-function-mode )))
   (t
    (setq emacspeak-which-function-mode
          (not emacspeak-which-function-mode ))))
  (emacspeak-auditory-icon
   (if emacspeak-which-function-mode 'on 'off ))
  (message "Turned %s which function mode%s %s"
           (if emacspeak-which-function-mode "on" "off" )
	   (if prefix "" " locally")
           (if semantic-toplevel-bovine-cache
               ""
             "Rebuild imenu index to  hear function name in mode line." )))

(defsubst emacspeak-speak-which-function ()
  "Speak which function we are on.  Uses which-function from
which-func without turning that mode on.  We actually use
semantic to do the work."
  (declare (special semantic-toplevel-bovine-cache))
  (require 'which-func)
  (when  (and (featurep 'semantic)
              semantic-toplevel-bovine-cache)
    (message  (or 
               (which-function)
               "Not inside a function."))))



(defun emacspeak-speak-mode-line ()
  "Speak the mode-line."
  (interactive)
  (declare (special  mode-name major-mode
                     emacspeak-which-function-mode
                     column-number-mode line-number-mode
                     emacspeak-mail-alert mode-line-format ))
  (dtk-stop)
  (emacspeak-dtk-sync)
  (force-mode-line-update)
  (let ((dtk-stop-immediately nil )
        (frame-info nil))
    (when (and  emacspeak-which-function-mode
                (fboundp 'which-function)
                (which-function))
      (emacspeak-speak-which-function))
    (cond
     ((> (length (frame-list)) 1)
      (setq frame-info
            (or (frame-parameter (selected-frame) 'emacspeak-label)
                (format "Frame %s " (frame-parameter (selected-frame) 'name))))
      (put-text-property 0 (length frame-info)
                         'personality 'annotation-voice frame-info))
     (t (setq frame-info "")))
    (when (buffer-modified-p )
      (dtk-tone 700 70))
    (when buffer-read-only
      (dtk-tone 250 50))
    (when  emacspeak-mail-alert
      (and (emacspeak-mail-alert-user)
           (dtk-tone 450 75)))
    (cond
     ((stringp mode-line-format)
      (dtk-speak mode-line-format ))
     (t 
      (dtk-speak
       (concat frame-info
               (format  "%s %s %s  %d%%  %s"
                        (if line-number-mode
                            (format "line %d"
                                    (emacspeak-get-current-line-number))
                          "")
                        (if column-number-mode
                            (format "Column %d"
                                    (current-column))
                          "")
                        (buffer-name)
                        (emacspeak-get-current-percentage-into-buffer)
                        (if  major-mode major-mode ""))))))))

;;}}}
;;;Helper --return string describing coding system info if
;;;relevant

(defvar emacspeak-speak-default-os-coding-system
  'raw-text-unix
  "Default coding system used for text files.
This should eventually be initialized based on the OS we are
running under.")

(defsubst emacspeak-speak-buffer-coding-system-info ()
  "Return buffer coding system info if releant.
If emacspeak-speak-default-os-coding-system is set and matches the
current coding system, then we return an empty string."
  (declare (special buffer-file-coding-system
                    emacspeak-speak-default-os-coding-system))
  (cond
   ((and (boundp 'buffer-file-coding-system)
         buffer-file-coding-system
         emacspeak-speak-default-os-coding-system
         (not (eq buffer-file-coding-system emacspeak-speak-default-os-coding-system)))
    (let ((value (format "%s" buffer-file-coding-system)))
      (put-text-property 0  (length value)
                         'personality
                         'annotation-voice
                         value)
      value))
   (t "")))

(defun emacspeak-speak-minor-mode-line ()
  "Speak the minor mode-information."
  (interactive)
  (declare (special minor-mode-alist
                    voice-lock-mode))
  (force-mode-line-update)
  (let ((info (format "Active minor modes:  %s"
            (mapconcat
             (function (lambda(item)
                         (let ((var (car item))
                               (value (cadr item )))
                           (cond
                            ((and (boundp var) (eval var ))
                             (if (symbolp value)
                                 (eval value)
                               value))
                            (t "")))))
             minor-mode-alist " ")))
        (voice-lock-mode t))
  (dtk-speak
   (concat 
    info
    (emacspeak-speak-buffer-coding-system-info)))))
  

(defun emacspeak-speak-line-number ()
  "Speak the line number of the current line."
  (interactive)
  (message "line %d"
           (emacspeak-get-current-line-number)))

(defun emacspeak-speak-buffer-filename ()
  "Speak name of file being visited in current buffer.
Speak default directory if invoked in a dired buffer,
or when the buffer is not visiting any file."
  (interactive)
  (dtk-speak
   (or (buffer-file-name)
       (format "Default directory is %s"
               default-directory))))

;;}}}
;;{{{  Speak text without moving point

;;; Functions to browse without moving:
(defun emacspeak-read-line-internal(arg)
  "Read a line without moving.
Line to read is specified relative to the current line, prefix args gives the
offset. Default  is to speak the previous line. "
  (save-excursion
    (cond
     ((zerop arg) (emacspeak-speak-line ))
     ((zerop (forward-line arg))
      (emacspeak-speak-line ))
     (t (dtk-speak "Not that many lines in buffer ")))))

(defun emacspeak-read-previous-line(&optional arg)
  "Read previous line, specified by an offset, without moving.
Default is to read the previous line. "
  (interactive "p")
  (emacspeak-read-line-internal (- (or arg 1 ))))

(defun emacspeak-read-next-line(&optional arg)
  "Read next line, specified by an offset, without moving.
Default is to read the next line. "
  (interactive "p")
  (emacspeak-read-line-internal (or arg 1 )))

(defun emacspeak-read-word-internal(arg)
  "Read a word without moving.
word  to read is specified relative to the current word, prefix args gives the
offset. Default  is to speak the previous word. "
  (save-excursion
    (cond
     ((= arg 0) (emacspeak-speak-word ))
     ((forward-word arg)
      (skip-syntax-forward " ")
      (emacspeak-speak-word 1 ))
     (t (dtk-speak "Not that many words ")))))

(defun emacspeak-read-previous-word(&optional arg)
  "Read previous word, specified as a prefix arg, without moving.
Default is to read the previous word. "
  (interactive "p")
  (emacspeak-read-word-internal (- (or arg 1 ))))

(defun emacspeak-read-next-word(&optional arg)
  "Read next word, specified as a numeric  arg, without moving.
Default is to read the next word. "
  (interactive "p")
  (emacspeak-read-word-internal  (or arg 1 )))

;;}}}
;;{{{  Speak misc information e.g. time, version, current-kill  etc

(defcustom emacspeak-speak-time-format-string
  "%_I %M %p on %A, %B %_e, %Y "
  "*Format string that specifies how the time should be spoken.
See the documentation for function
`format-time-string'"
  :group 'emacspeak-speak
:type 'string)

(defun emacspeak-speak-time ()
  "Speak the time."
  (interactive)
  (declare (special emacspeak-speak-time-format-string))
      (tts-with-punctuations "some"
                             (dtk-speak
                              (format-time-string
                               emacspeak-speak-time-format-string))))
                             

(defun emacspeak-speak-version ()
  "Announce version information for running emacspeak."
  (interactive)
  (declare (special emacspeak-version))
  (dtk-speak
   (format "You are using emacspeak %s "
           emacspeak-version )))

(defun emacspeak-speak-current-kill (count)
  "Speak the current kill entry.
This is the text that will be yanked in by the next \\[yank].
Prefix numeric arg, COUNT, specifies that the text that will be yanked as a
result of a
\\[yank]  followed by count-1 \\[yank-pop]
be spoken.
 The kill number that is spoken says what numeric prefix arg to give
to command yank."
  (interactive "p")
  (let ((voice-lock-mode t)
        (context
         (format "kill %s "
                 (if current-prefix-arg (+ 1 count)  1 ))))
    (put-text-property 0 (length context)
                       'personality 'annotation-voice context )
    (dtk-speak
     (concat
      context
      (current-kill (if current-prefix-arg count 0)t)))))

(defun emacspeak-zap-tts ()
  "Send this command to the TTS directly."
  (interactive)
  (dtk-dispatch
   (read-from-minibuffer"Enter TTS command string: ")))

(defun emacspeak-speak-string-to-phone-number (string)
  "Convert alphanumeric phone number to true phone number.
Argument STRING specifies the alphanumeric phone number."
  (setq string (downcase string ))
  (let ((i 0))
    (loop for character across string
          do
          (aset string i
                (case character
                  (?a  ?2)
                  (?b ?2)
                  (?c ?2)
                  (?d ?3)
                  (?e ?3)
                  (?f ?3)
                  (?g ?4)
                  (?h ?4)
                  (?i ?4)
                  (?j ?5)
                  (?k ?5)
                  (?l ?5)
                  (?m ?6)
                  (?n ?6)
                  (?o ?6)
                  (?p ?7)
                  (?r ?7)
                  (?s ?7)
                  (?t ?8)
                  (?u ?8)
                  (?v ?8)
                  (?w ?9)
                  (?x ?9)
                  (?y ?9)
                  (?q ?1)
                  (?z ?1)
                  (otherwise character)))
          (incf i))
    string))

(defun emacspeak-dial-dtk (number)
  "Prompt for and dial a phone NUMBER with the Dectalk."
  (interactive "sEnter phone number to dial:")
  (let ((dtk-stop-immediately nil))
    (dtk-dispatch (format "[:dial %s]"
                          (emacspeak-speak-string-to-phone-number number)))
    (sit-for 4)))

(defun emacspeak-dtk-speak-version ()
  "Use this to find out which version of the Dectalk firmware you are running."
  (interactive)
  (dtk-dispatch
   "this is [:version speak]  "))

;;}}}
;;{{{ speaking marks

;;; Intelligent mark feedback for emacspeak:
;;;

(defun emacspeak-speak-current-mark (count)
  "Speak the line containing the mark.
With no argument, speaks the
line containing the mark--this is where `exchange-point-and-mark'
\\[exchange-point-and-mark] would jump.  Numeric prefix arg 'COUNT' speaks
line containing mark 'n' where 'n' is one less than the number of
times one has to jump using `set-mark-command' to get to this marked
position.  The location of the mark is indicated by an aural highlight
achieved by a change in voice personality."
  (interactive "p")
  (unless (mark)
    (error "No marks set in this buffer"))
  (when (and current-prefix-arg
             (> count (length mark-ring)))
    (error "Not that many marks in this buffer"))
  (let ((voice-lock-mode t)
        (line nil)
        (position nil)
        (context
         (format "mark %s "
                 (if current-prefix-arg count   0 ))))
    (put-text-property 0 (length context)
                       'personality 'annotation-voice context )
    (setq position
          (if current-prefix-arg
              (elt mark-ring(1-  count))
            (mark)))
    (save-excursion
      (goto-char position)
      (ems-set-personality-temporarily
       position (1+ position) 'paul-animated
       (setq line
             (thing-at-point  'line ))))
    (dtk-speak
     (concat context line))))

;;}}}
;;{{{  Execute command repeatedly, browse

(defun emacspeak-execute-repeatedly (command)
  "Execute COMMAND repeatedly."
  (interactive "CCommand to execute repeatedly:")
  (let ((key "")
        (position (point ))
        (continue t )
        (message (format "Press space to execute %s again" command)))
    (while continue
      (call-interactively command )
      (cond
       ((= (point) position ) (setq continue nil))
       (t (setq position (point))
          (setq key
                (let ((dtk-stop-immediately nil ))
                                        ;(sit-for 2)
                  (read-key-sequence message )))
          (when(and (stringp key)
                    (not (=  32  (string-to-char key ))))
            (dtk-stop)
            (setq continue nil )))))
    (dtk-speak "Exited continuous mode ")))

(defun emacspeak-speak-continuously ()
  "Speak a buffer continuously.
First prompts using the minibuffer for the kind of action to perform after
speaking each chunk.
E.G.  speak a line at a time etc.
Speaking commences at current buffer position.
Pressing  \\[keyboard-quit] breaks out, leaving point on last chunk that was spoken.
 Any other key continues to speak the buffer."
  (interactive)
  (let ((command (key-binding
                  (read-key-sequence "Press key sequence to repeat: "))))
    (unless command
      (error "You specified an invalid key sequence.  " ))
    (emacspeak-execute-repeatedly command)))

(defun emacspeak-speak-browse-buffer (&optional define-paragraph)
  "Browse the current buffer by reading it a paragraph at a
time.
Optional interactive prefix arg define-paragraph 
prompts for regexp that defines paragraph start and
paragraph-separate. "
  (interactive "P")
  (when define-paragraph
    (setq paragraph-start
          (read-from-minibuffer "Paragraph Start pattern:
"))
    (setq paragraph-separate
          (read-from-minibuffer "Paragraph separate pattern: "
                                paragraph-start)))
  (emacspeak-execute-repeatedly 'forward-paragraph))

(defvar emacspeak-read-line-by-line-quotient 10
  "Determines behavior of emacspeak-read-line-by-line.")

(defvar emacspeak-read-by-line-by-line-tick 1.0
  "Granularity of time for reading line-by-line.")

                                        ;(defun emacspeak-read-line-by-line ()
                                        ;  "Read line by line until interrupted"
                                        ;  (interactive)
                                        ;  (let ((count 0)
                                        ;        (line-length 0)
                                        ;        (continue t))
                                        ;    (while
                                        ;        (and continue
                                        ;             (not (eobp)))
                                        ;      (setq dtk-last-output "")
                                        ;      (call-interactively 'next-line)
                                        ;      (setq line-length (length  (thing-at-point 'line)))
                                        ;      (setq count 0)
                                        ;      (when (> line-length 0)
                                        ;        (while(and (< count
                                        ;                      (1+ (/ line-length emacspeak-read-line-by-line-quotient)))
                                        ;                   (setq continue
                                        ;                         (sit-for
                                        ;                          emacspeak-read-by-line-by-line-tick 0 nil ))
                                        ;                   (not (string-match  "done" dtk-last-output))
                                        ;                   (incf count))))))
                                        ;  (emacspeak-auditory-icon 'task-done)
                                        ;  (message "done moving "))

;;}}}
;;{{{  skimming

(defun emacspeak-speak-skim-paragraph()
  "Skim paragraph.
Skimming a paragraph results in the speech speeding up after
the first clause.
Speech is scaled by the value of dtk-speak-skim-scale"
  (interactive)
  (save-excursion
    (let ((inhibit-point-motion-hooks t)
          (start nil)
          (end nil))
      (forward-paragraph 1)
      (setq end (point))
      (backward-paragraph 1)
      (setq start (point))
      (dtk-speak (buffer-substring  start end )
                 'skim))))

(defun emacspeak-speak-skim-next-paragraph()
  "Skim next paragraph."
  (interactive)
  (forward-paragraph 1)
  (emacspeak-speak-skim-paragraph))

(defun emacspeak-speak-skim-buffer ()
  "Skim the current buffer  a paragraph at a time."
  (interactive)
  (emacspeak-execute-repeatedly 'emacspeak-speak-skim-next-paragraph))

;;}}}
;;{{{ comint

(defcustom emacspeak-comint-autospeak t
  "Says if comint output is automatically spoken.
You can use 
  `emacspeak-toggle-comint-autospeak` bound to
  \\[emacspeak-toggle-comint-autospeak] to toggle this
setting."
:group 'emacspeak-speak
  :type 'boolean)

(defun emacspeak-toggle-comint-autospeak (&optional prefix)
  "Toggle state of Emacspeak comint autospeak.
When turned on, comint output is automatically spoken.  Turn this on if
you want your shell to speak its results.  Interactive
PREFIX arg means toggle the global default value, and then
set the current local value to the result."

  (interactive  "P")
  (declare  (special  emacspeak-comint-autospeak
emacspeak-comint-split-speech-on-newline ))
  (cond
   (prefix
    (setq-default  emacspeak-comint-autospeak
                   (not  (default-value 'emacspeak-comint-autospeak )))
    (setq emacspeak-comint-autospeak (default-value 'emacspeak-comint-autospeak )))
   (t (make-local-variable 'emacspeak-comint-autospeak)
      (setq emacspeak-comint-autospeak
	    (not emacspeak-comint-autospeak ))))
  (and emacspeak-comint-autospeak
       emacspeak-comint-split-speech-on-newline
       (modify-syntax-entry 10 ">"))
  (emacspeak-auditory-icon
   (if emacspeak-comint-autospeak 'on 'off))
  (message "Turned %s comint autospeak %s "
           (if emacspeak-comint-autospeak "on" "off" )
	   (if prefix "" "locally")))

(defvar emacspeak-comint-output-monitor nil
"Switch to monitor comint output.
When turned on,  comint output will be spoken even when the
buffer is not current or its window live.")

(make-variable-buffer-local
 'emacspeak-comint-output-monitor)

(defun emacspeak-toggle-comint-output-monitor (&optional prefix)
  "Toggle state of Emacspeak comint monitor.
When turned on, comint output is automatically spoken.  Turn this on if
you want your shell to speak its results.  Interactive
PREFIX arg means toggle the global default value, and then
set the current local value to the result."
  (interactive  "P")
  (declare  (special  emacspeak-comint-output-monitor ))
  (cond
   (prefix
    (setq-default  emacspeak-comint-output-monitor
                   (not  (default-value 'emacspeak-comint-output-monitor )))
    (setq emacspeak-comint-output-monitor (default-value 'emacspeak-comint-output-monitor )))
   (t (make-local-variable 'emacspeak-comint-output-monitor)
      (setq emacspeak-comint-output-monitor
	    (not emacspeak-comint-output-monitor ))))
  (emacspeak-auditory-icon
   (if emacspeak-comint-output-monitor 'on 'off))
  (message "Turned %s comint monitor %s "
           (if emacspeak-comint-output-monitor "on" "off" )
	   (if prefix "" "locally")))

(defcustom emacspeak-comint-split-speech-on-newline  t
  "*Option to have comint split speech on newlines.
Non-nil means we split speech on newlines in comint buffer."
  :group 'emacspeak-speak
:type 'boolean)

(add-hook 'shell-mode-hook
          (function
           (lambda nil
             (declare (special
                       emacspeak-comint-split-speech-on-newline ))
             (dtk-set-punctuations "all")
             (when emacspeak-comint-split-speech-on-newline
               (modify-syntax-entry 10 ">")))))

(add-hook 'comint-mode-hook
          (function
           (lambda nil
             (declare (special
                       emacspeak-comint-split-speech-on-newline ))
             (dtk-set-punctuations "all")
             (when emacspeak-comint-split-speech-on-newline
               (modify-syntax-entry 10 ">")))))

;;}}}
;;{{{   quiten messages

(defcustom emacspeak-speak-messages t
  "*Option indicating if messages are spoken.  If nil,
emacspeak will not speak messages as they are echoed to the
message area.  You can use command
`emacspeak-toggle-speak-messages' bound to
\\[emacspeak-toggle-speak-messages]."

:group 'emacspeak-speak
:type 'boolean)

(defun emacspeak-toggle-speak-messages ()
  "Toggle the state of whether emacspeak echoes messages."
  (interactive)
  (declare (special emacspeak-speak-messages ))
  (and (y-or-n-p
        (format "This will %s  Emacs speaking messages.  Are you sure? "
                (if emacspeak-speak-messages " stop " " start ")))
       (setq  emacspeak-speak-messages
              (not emacspeak-speak-messages))
       (emacspeak-auditory-icon
        (if emacspeak-speak-messages  'on 'off))
       (dtk-speak
        (format "Turned  speaking of emacs messages %s"
                (if emacspeak-speak-messages  " on" " off")))))

;;}}}
;;{{{  Moving across fields:

;;; For the present, we define a field
;;; as a contiguous series of non-blank characters
;;; helper function: speak a field
(defsubst  emacspeak-speak-field (start end )
  "Speaks field delimited by arguments START and END."
  (let ((header (or (get-text-property start  'field-name) "")))
    (dtk-speak
     (concat
      (progn (put-text-property 0 (length header )
                                'personality 'annotation-voice
                                header )
             header )
      " "
      (buffer-substring  start end)))))

(cond 
 ;; emacs 21 defines fields 
 ((fboundp 'field-beginning)
  (defun emacspeak-speak-current-field ()
    "Speak current field.
A field is
defined  by Emacs 21."
    (interactive)
    (emacspeak-speak-region (field-beginning)
                            (field-end))))
 (t 
  (defun emacspeak-speak-current-field ()
    "Speak current field.
A field is defined currently as a sequence of non-white space characters.  may be made
  mode specific later."
    (interactive)
    (cond
     ((window-minibuffer-p (selected-window))
      (emacspeak-speak-line))
     (t (let ((start nil ))
          (save-excursion
            (skip-syntax-backward "^ ")
            (setq start (point ))
            (skip-syntax-forward "^ ")
            (emacspeak-speak-field start (point )))))))))

(defun emacspeak-speak-next-field ()
  "Skip across and speak the next contiguous sequence of non-blank characters.
Useful in moving across fields.
Will be improved if it proves useful."
  (interactive)
  (let ((start nil ))
    (skip-syntax-forward "^ ")
    (skip-syntax-forward " ")
    (setq start (point ))
    (save-excursion
      (skip-syntax-forward "^ ")
      (emacspeak-speak-field start (point)))))

(defun emacspeak-speak-previous-field ()
  "Skip backwards across and speak  contiguous sequence of non-blank characters.
Useful in moving across fields.
Will be improved if it proves useful."
  (interactive)
  (let ((start nil ))
    (skip-syntax-backward " ")
    (setq start (point ))
    (skip-syntax-backward "^ ")
    (emacspeak-speak-field (point ) start)))

(defun emacspeak-speak-current-column ()
  "Speak the current column."
  (interactive)
  (message "Point at column %d" (current-column )))

(defun emacspeak-speak-current-percentage ()
  "Announce the percentage into the current buffer."
  (interactive)
  (message "Point is  %d%% into  the current buffer"
           (emacspeak-get-current-percentage-into-buffer )))

;;}}}
;;{{{  Speak the last message again:

(defun emacspeak-speak-message-again ()
  "Speak the last message from Emacs once again."
  (interactive)
  (declare (special emacspeak-last-message ))
  (dtk-speak   emacspeak-last-message ))

(defun emacspeak-announce (announcement)
  "Speak the ANNOUNCEMENT, if possible.
Otherwise just display a message."
  (message announcement))

;;}}}
;;{{{  Using emacs's windows usefully:

;;Return current window contents
(defsubst emacspeak-get-window-contents ()
  "Return window contents."
  (let ((start nil))
    (save-excursion
      (move-to-window-line 0)
      (setq start (point))
      (move-to-window-line -1)
      (end-of-line)
      (buffer-substring start (point)))))

(defun emacspeak-speak-window-information ()
  "Speaks information about current windows."
  (interactive)
  (message "Current window has %s lines and %s columns"
           (window-height) (window-width)))

(defun emacspeak-speak-current-window ()
  "Speak contents of current window.
Speaks entire window irrespective of point."
  (interactive)
  (emacspeak-speak-region (window-start) (window-end )))

(defun emacspeak-speak-other-window (&optional arg)
  "Speak contents of `other' window.
Speaks entire window irrespective of point.
Semantics  of `other' is the same as for the builtin Emacs command
`other-window'.
Optional argument ARG  specifies `other' window to speak."
  (interactive "nSpeak window")
  (save-window-excursion
    (other-window arg )
    (save-excursion
      (set-buffer (window-buffer))
      (emacspeak-speak-region
       (max (point-min) (window-start) )
       (min (point-max)(window-end ))))))

(defun emacspeak-speak-next-window ()
  "Speak the next window."
  (interactive)
  (emacspeak-speak-other-window 1 ))

(defun emacspeak-speak-previous-window ()
  "Speak the previous window."
  (interactive)
  (emacspeak-speak-other-window -1 ))


(defun  emacspeak-owindow-scroll-up ()
  "Scroll up the window that command `other-window' would move to.
Speak the window contents after scrolling."
  (interactive)
  (let ((error nil))
    (condition-case nil
        (scroll-other-window  nil)
      (error (setq error t)))
    (if error
        (message "There is no other window ")
      (progn
        (force-mode-line-update 'all)
        (emacspeak-auditory-icon 'scroll)
        (emacspeak-speak-other-window 1)))))
          

(defun  emacspeak-owindow-scroll-down ()
  "Scroll down  the window that command `other-window' would move to.
Speak the window contents after scrolling."
  (interactive)
  (let ((error nil)
        (start
         (save-window-excursion
           (other-window 1)
           (window-start )))
        (height (save-window-excursion
                  (other-window 1)
                  (window-height))))
    (condition-case nil
        (scroll-other-window  (- height ))
      (error (setq error t )))
    (if error
        (message "There is no other window ")
      (save-window-excursion
        (other-window 1)
        (cond
         ((= start (window-start) )
          (message "At top of other window "))
         (t (emacspeak-auditory-icon 'scroll)
            (emacspeak-speak-region (window-start) (window-end ))))))))

(defun emacspeak-owindow-next-line (count)
  "Move to the next line in the other window and speak it.
Numeric prefix arg COUNT can specify number of lines to move."
  (interactive "p")
  (setq count (or count 1 ))
  (let  ((residue nil )
         (old-buffer (current-buffer )))
    (unwind-protect
        (progn
          (set-buffer (window-buffer (next-window )))
          (end-of-line)
          (setq residue (forward-line count))
          (cond
           ((> residue 0) (message "At bottom of other window "))
           (t (set-window-point (get-buffer-window (current-buffer ))
                                (point))
              (emacspeak-speak-line ))))
      (set-buffer old-buffer ))))

(defun emacspeak-owindow-previous-line (count)
  "Move to the next line in the other window and speak it.
Numeric prefix arg COUNT specifies number of lines to move."
  (interactive "p")
  (setq count (or count 1 ))
  (let  ((residue nil )
         (old-buffer (current-buffer )))
    (unwind-protect
        (progn
          (set-buffer (window-buffer (next-window )))
          (end-of-line)
          (setq residue (forward-line (- count)))
          (cond
           ((> 0 residue) (message "At top of other window "))
           (t (set-window-point (get-buffer-window (current-buffer ))
                                (point))
              (emacspeak-speak-line ))))
      (set-buffer old-buffer ))))

(defun emacspeak-owindow-speak-line ()
  "Speak the current line in the other window."
  (interactive)
  (let  ((old-buffer (current-buffer )))
    (unwind-protect
        (progn
          (set-buffer (window-buffer (next-window )))
          (goto-char (window-point ))
          (emacspeak-speak-line))
      (set-buffer old-buffer ))))
(defun emacspeak-speak-predefined-window (&optional arg)
  "Speak one of the first 10 windows on the screen.
In general, you'll never have Emacs split the screen into more than
two or three.
Argument ARG determines the 'other' window to speak.
 Speaks entire window irrespective of point.
Semantics  of `other' is the same as for the builtin Emacs command
`other-window'."
  (interactive "P")
  (let* ((window-size-change-functions nil)
         (window
          (condition-case nil
              (read (format "%c" last-input-event ))
            (error nil ))))
    (or (numberp window)
        (setq window
              (read-minibuffer "Window   between 1 and 9 to speak")))
    (save-window-excursion
      (other-window window )
      (emacspeak-speak-region (window-start) (window-end )))))

;;}}}
;;{{{  Intelligent interactive commands for reading:

;;; Prompt the user if asked to prompt.
;;; Prompt is:
;;; press 'b' for beginning of unit,
;;; 'r' for rest of unit,
;;; any other key for entire unit
;;; returns 1, -1, or nil accordingly.
;;; If prompt is nil, does not prompt: just gets the input

(defun emacspeak-ask-how-to-speak (unit-name prompt)
  "Argument UNIT-NAME specifies kind of unit that is being spoken.
Argument PROMPT specifies the prompt to display."

  (if prompt
      (message
       (format "Press s to speak start of %s, r for rest of  %s. \
 Any  key for entire %s "
               unit-name unit-name unit-name )))
  (let ((char (read-char )))
    (cond
     ((= char ?s) -1)
     ((= char ?r) 1)
     (t nil )))
  )

(defun emacspeak-speak-buffer-interactively ()
  "Speak the start of, rest of, or the entire buffer.
's' to speak the start.
'r' to speak the rest.
any other key to speak entire buffer."
  (interactive)
  (emacspeak-speak-buffer
   (emacspeak-ask-how-to-speak "buffer" (sit-for 1 0 nil ))))



(defun emacspeak-speak-help-interactively ()
  "Speak the start of, rest of, or the entire help.
's' to speak the start.
'r' to speak the rest.
any other key to speak entire help."
  (interactive)
  (emacspeak-speak-help
   (emacspeak-ask-how-to-speak "help" (sit-for 1 0 nil ))))


(defun emacspeak-speak-line-interactively ()
  "Speak the start of, rest of, or the entire line.
's' to speak the start.
'r' to speak the rest.
any other key to speak entire line."
  (interactive)
  (emacspeak-speak-line
   (emacspeak-ask-how-to-speak "line" (sit-for 1 0 nil ))))

(defun emacspeak-speak-paragraph-interactively ()
  "Speak the start of, rest of, or the entire paragraph.
's' to speak the start.
'r' to speak the rest.
any other key to speak entire paragraph."
  (interactive)
  (emacspeak-speak-paragraph
   (emacspeak-ask-how-to-speak "paragraph" (sit-for 1 0 nil ))))

(defun emacspeak-speak-page-interactively ()
  "Speak the start of, rest of, or the entire page.
's' to speak the start.
'r' to speak the rest.
any other key to speak entire page."
  (interactive)
  (emacspeak-speak-page
   (emacspeak-ask-how-to-speak "page" (sit-for 1 0 nil ))))

(defun emacspeak-speak-word-interactively ()
  "Speak the start of, rest of, or the entire word.
's' to speak the start.
'r' to speak the rest.
any other key to speak entire word."
  (interactive)
  (emacspeak-speak-word
   (emacspeak-ask-how-to-speak "word" (sit-for 1 0 nil ))))

(defun emacspeak-speak-sexp-interactively ()
  "Speak the start of, rest of, or the entire sexp.
's' to speak the start.
'r' to speak the rest.
any other key to speak entire sexp."
  (interactive)
  (emacspeak-speak-sexp
   (emacspeak-ask-how-to-speak "sexp" (sit-for 1 0 nil ))))

;;}}}
;;{{{  emacs' register related commands

;;; Things like view-register are useful.

(defun emacspeak-view-register ()
  "Display the contents of a register, and then speak it."
  (interactive)
  (call-interactively 'view-register)
  (save-excursion (set-buffer "*Output*")
                  (dtk-speak (buffer-string ))))

;;}}}
;;{{{  emacs rectangles and regions:

(eval-when (compile) (require 'rect))
;;; These help you listen to columns of text. Useful for tabulated data
(defun emacspeak-speak-rectangle ( start end )
  "Speak a rectangle of text.
Rectangle is delimited by point and mark.
When call from a program,
arguments specify the START and END of the rectangle."
  (interactive  "r")
  (require 'rect)
  (dtk-speak-list (extract-rectangle start end )))
    

;;; helper function: emacspeak-put-personality
;;; sets property 'personality to personality
(defsubst emacspeak-put-personality (start end personality )
  "Apply specified personality to region delimited by START and END.
Argument PERSONALITY gives the value for property personality."
  (put-text-property start end 'personality personality ))

;;; Compute table of possible voices to use in completing-read
(defsubst  emacspeak-possible-voices ()
  "Return possible voices."
  (declare (special dtk-voice-table ))
  (loop for key being the hash-keys of dtk-voice-table
        collect  (cons
                  (symbol-name key)
                  (symbol-name key))))


(defun emacspeak-voicify-rectangle (start end &optional personality )
  "Voicify the current rectangle.
When calling from a program,arguments are
START END personality
Prompts for PERSONALITY  with completion when called interactively."
  (interactive "r")
  (require 'rect)
  (require 'voice-lock )
  (or voice-lock-mode (setq voice-lock-mode t ))
  (let ((personality-table (emacspeak-possible-voices )))
    (when (interactive-p)
      (setq personality
            (read
             (completing-read "Use personality: "
                              personality-table nil t ))))
    (ems-modify-buffer-safely
     (operate-on-rectangle
      (function (lambda ( start-seg begextra endextra )
                  (emacspeak-put-personality start-seg  (point) personality )))
      start end  nil))))

(defun emacspeak-voicify-region (start end &optional personality )
  "Voicify the current region.
When calling from a program,arguments are
START END personality.
Prompts for PERSONALITY  with completion when called interactively."
  (interactive "r")
  (require 'voice-lock )
  (or voice-lock-mode (setq voice-lock-mode t ))
  (let ((personality-table (emacspeak-possible-voices )))
    (when (interactive-p)
      (setq personality
            (read
             (completing-read "Use personality: "
                              personality-table nil t ))))
    (put-text-property start end 'personality personality )))

(defun emacspeak-put-text-property-on-rectangle   (start end prop value )
  "Set property to specified value for each line in the rectangle.
Argument START and END specify the rectangle.
Argument PROP specifies the property and VALUE gives the
value to apply."
  (require 'rect)
  (operate-on-rectangle
   (function (lambda ( start-seg begextra endextra )
               (put-text-property  start-seg (point)    prop value  )))
   start end  nil ))

;;}}}
;;{{{  Matching delimiters:

;;; A modified blink-matching-open that always displays the matching line
;;; in the minibuffer so emacspeak can speak it.

(defun emacspeak-blink-matching-open ()
  "Display matching delimiter in the minibuffer."
  (interactive)
  (declare (special blink-matching-paren-distance))
  (and (> (point) (1+ (point-min)))
       (not (memq (char-syntax (char-after (- (point) 2))) '(?/ ?\\ )))
       blink-matching-paren
       (let* ((oldpos (point))
              (emacspeak-blink-delay 5)
	      (blinkpos)
	      (mismatch))
	 (save-excursion
	   (save-restriction
	     (if blink-matching-paren-distance
		 (narrow-to-region (max (point-min)
					(- (point) blink-matching-paren-distance))
				   oldpos))
	     (condition-case ()
		 (setq blinkpos (scan-sexps oldpos -1))
	       (error nil)))
	   (and blinkpos (/= (char-syntax (char-after blinkpos))
			     ?\$)
		(setq mismatch
		      (/= (char-after (1- oldpos))
			  (matching-paren (char-after blinkpos)))))
	   (if mismatch (setq blinkpos nil))
	   (if blinkpos
	       (progn
                 (goto-char blinkpos)
                 (message
                  "Matches %s"
                  ;; Show what precedes the open in its line, if anything.
                  (if (save-excursion
                        (skip-chars-backward " \t")
                        (not (bolp)))
                      (buffer-substring (progn (beginning-of-line) (point))
                                        (1+ blinkpos))
                    ;; Show what follows the open in its line, if anything.
                    (if (save-excursion
                          (forward-char 1)
                          (skip-chars-forward " \t")
                          (not (eolp)))
                        (buffer-substring blinkpos
                                          (progn (end-of-line) (point)))
                      ;; Otherwise show the previous nonblank line.
                      (concat
                       (buffer-substring (progn
                                           (backward-char 1)
                                           (skip-chars-backward "\n \t")
                                           (beginning-of-line)
                                           (point))
                                         (progn (end-of-line)
                                                (skip-chars-backward " \t")
                                                (point)))
                       ;; Replace the newline and other whitespace with `...'.
                       "..."
                       (buffer-substring blinkpos (1+
                                                   blinkpos)))))))
	     (cond (mismatch
		    (message "Mismatched parentheses"))
		   ((not blink-matching-paren-distance)
		    (message "Unmatched parenthesis")))))
         (sit-for emacspeak-blink-delay))))

(defun  emacspeak-use-customized-blink-paren ()
  "A customized blink-paren to speak  matching opening paren.
We need to call this in case Emacs
is anal and loads its own builtin blink-paren function
which does not talk."
  (interactive)
  (fset 'blink-matching-open (symbol-function 'emacspeak-blink-matching-open))
  (and (interactive-p)
       (message "Using customized blink-paren function provided by Emacspeak.")))

(emacspeak-use-customized-blink-paren)

;;}}}
;;{{{  Auxillary functions:

(defsubst emacspeak-kill-buffer-carefully (buffer)
  "Kill BUFFER BUF if it exists."
  (and buffer
       (get-buffer buffer)
       (buffer-name (get-buffer buffer ))
       (kill-buffer buffer)))

(defsubst emacspeak-overlay-get-text (o)
  "Return text under overlay OVERLAY.
Argument O specifies overlay."
  (save-excursion
    (set-buffer (overlay-buffer o ))
    (buffer-substring
     (overlay-start o)
     (overlay-end o ))))

;;}}}
;;{{{  moving across blank lines

(defun emacspeak-skip-blank-lines-forward ()
  "Move forward across blank lines.
The line under point is then spoken.
Signals end of buffer."
  (interactive)
  (let ((save-syntax (char-syntax 10))
        (skip 0))
    (unwind-protect
        (progn
          (modify-syntax-entry   10 " ")
          (setq skip (skip-syntax-forward " "))
          (cond
           ((zerop skip)
            (message "Did not move "))
           ((eobp)
            (message "At end of buffer"))
           (t(emacspeak-auditory-icon 'large-movement )
             (emacspeak-speak-line ))))
      (modify-syntax-entry 10 (format "%c" save-syntax )))))

(defun emacspeak-skip-blank-lines-backward ()
  "Move backward  across blank lines.
The line under point is   then spoken.
Signals beginning  of buffer."
  (interactive)
  (let ((save-syntax (char-syntax 10))
        (skip 0))
    (unwind-protect
        (progn
          (modify-syntax-entry   10 " ")
          (setq skip (skip-syntax-backward " "))
          (cond
           ((zerop skip)
            (message "Did not move "))
           ((bobp )
            (message "At start  of buffer"))
           (t (beginning-of-line)
              (emacspeak-auditory-icon 'large-movement )
              (emacspeak-speak-line ))))
      (modify-syntax-entry 10 (format "%c" save-syntax )))))

;;}}}
;;{{{ Speaking spaces

(defun emacspeak-speak-spaces-at-point ()
  "Speak the white space at point."
  (interactive)
  (cond
   ((not (= 32 (char-syntax (following-char ))))
    (message "Not on white space"))
   (t
    (let ((orig (point))
          (start (save-excursion
                   (skip-syntax-backward " ")
                   (point)))
          (end (save-excursion
                 (skip-syntax-forward " ")
                 (point))))
      (message "Space %s of %s"
               (1+ (- orig start)) (- end start ))))))

;;}}}
;;{{{   Switching buffers, killing buffers etc

(defun emacspeak-switch-to-previous-buffer  ()
  "Switch to most recently used interesting buffer."
  (interactive)
  (switch-to-buffer (other-buffer))
  (emacspeak-speak-mode-line )
  (emacspeak-auditory-icon 'select-object ))

(defun emacspeak-kill-buffer-quietly   ()
  "Kill current buffer without asking for confirmation."
  (interactive)
  (kill-buffer nil )
  (emacspeak-auditory-icon 'close-object)
  (emacspeak-speak-mode-line ))

;;}}}
;;{{{  translate faces to voices

(defun voice-lock-voiceify-faces ()
  "Map faces to personalities."
  (declare (special voice-lock-mode))
  (save-excursion
    (goto-char (point-min))
    (let ((inhibit-read-only t )
          (face nil )
          (start (point)))
      (setq voice-lock-mode t)
      (unwind-protect
          (while (not (eobp))
            (setq face (get-text-property (point) 'face ))
            (goto-char
             (or (next-single-property-change (point) 'face )
                 (point-max)))
            (put-text-property start  (point)
                               'personality
                               (if (listp face)
                                   (car face)
                                 face ))
            (setq start (point)))
        (setq inhibit-read-only nil)))))

;;}}}
;;{{{  completion helpers

;;{{{ switching to completions window from minibuffer:

(defsubst emacspeak-get-minibuffer-contents ()
  "Return contents of the minibuffer."
  (save-excursion
    (set-buffer (window-buffer (minibuffer-window)))
    (buffer-string)))

;;; Make all occurrences of string inaudible
(defsubst emacspeak-make-string-inaudible(string)
  (unless (string-match "^ *$" string)
    (save-excursion
      (goto-char (point-min))
      (save-match-data
        (ems-modify-buffer-safely
         (while (search-forward string nil t)
           (put-text-property (match-beginning 0)
                              (match-end 0)
                              'personality 'inaudible)))))))
(defvar emacspeak-completions-current-prefix nil
  "Prefix typed in the minibuffer before completions was invoked.")

(make-variable-buffer-local 'emacspeak-completions-current-prefix)

(defun emacspeak-switch-to-completions-window ()
  "Jump to the *Completions* buffer if it is active.
We make the current minibuffer contents (which is obviously the
prefix for each entry in the completions buffer) inaudible
to reduce chatter."
  (interactive)
  (declare (special voice-lock-mode
                    emacspeak-completions-current-prefix))
  (let ((completions-buffer (get-buffer "*Completions*"))
        (current-entry (emacspeak-get-minibuffer-contents)))
    (cond
     ((and completions-buffer
           (window-live-p (get-buffer-window completions-buffer )))
      (select-window  (get-buffer-window completions-buffer ))
      (when (interactive-p)
        (unless (get-text-property (point) 'mouse-face)
          (goto-char (next-single-property-change (point)
                                                  'mouse-face )))
        (setq voice-lock-mode t)
        (when (and  current-entry
                    (> (length current-entry) 0))
          (setq emacspeak-completions-current-prefix current-entry)
          (emacspeak-make-string-inaudible current-entry))
        (dtk-toggle-splitting-on-white-space)
        (dtk-speak
         (emacspeak-get-current-completion-from-completions)))
      (emacspeak-auditory-icon 'select-object))
     (t (message "No completions")))))

(defun emacspeak-completions-move-to-completion-group()
  "Move to group of choices beginning with character last
typed. If no such group exists, then we dont move. "
  (interactive)
  (declare (special last-input-char
                    emacspeak-completions-current-prefix))
  (let ((pattern (format "[ \t\n]%s%c"
                         (or
                          emacspeak-completions-current-prefix "")
                         last-input-char))
        (case-fold-search t))
    (when (re-search-forward pattern nil t)
      (emacspeak-auditory-icon 'search-hit))
    (dtk-speak
     (emacspeak-get-current-completion-from-completions ))))
(declaim (special completion-list-mode-map))
(let ((chars
       "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"))
  (loop for char across chars
        do
        (define-key completion-list-mode-map
          (format "%c" char)
          'emacspeak-completions-move-to-completion-group)))


;;}}}

;;}}}
;;{{{ mark convenience commands

(defsubst emacspeak-mark-speak-mark-line()
  (emacspeak-auditory-icon 'mark-object )
  (ems-set-personality-temporarily (point) (1+ (point))
                                   'paul-animated
                                   (emacspeak-speak-line)))

(defun emacspeak-mark-forward-mark ()
  "Cycle forward through the mark ring."
  (interactive)
  (set-mark-command t)
  (when (interactive-p )
    (emacspeak-mark-speak-mark-line)))

(defun emacspeak-mark-backward-mark ()
  "Cycle backward through the mark ring."
  (interactive)
  (declare (special mark-ring))
  (let ((target  (car (last mark-ring ))))
    (cond
     (target
      (setq mark-ring
            (cons (copy-marker (mark-marker))
                  (butlast mark-ring 1)))
      (set-marker (mark-marker) (+ 0 target)
                  (current-buffer))
      (move-marker target nil)
      (goto-char (mark t))
      (when (interactive-p)
        (emacspeak-mark-speak-mark-line)))
     (t (message "No previous mark to move to")))))

;;}}}
(provide 'emacspeak-speak )
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}