;;; emacspeak-ocr.el --- ocr Front-end for emacspeak desktop
;;; $Id$
;;; $Author$
;;; Description:  Emacspeak front-end for OCR
;;; Keywords: Emacspeak, ocr
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

;;{{{  Introduction:

;;; Commentary:

;;; This module defines Emacspeak front-end to OCR.
;;; This module assumes that sane is installed and working
;;; for image acquisition,
;;; and that there is an OCR engine that can take acquired
;;; images and produce text.
;;; Prerequisites:
;;; Sane installed and working.
;;; scanimage to generate tiff files from scanner.
;;; tiffcp to compress the tiff file.
;;; working ocr executable 
;;; by default this module assumes that the OCR executable
;;; is named "ocr"
;;;

;;}}}
;;{{{ required modules

;;; Code:

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-speak)
(require 'voice-lock)
(require 'emacspeak-sounds)
(require 'emacspeak-table)
(require 'emacspeak-table-ui)
(require 'derived)
(eval-when-compile (require 'emacspeak-keymap))
;;}}}
;;{{{  Customization variables

(defgroup emacspeak-ocr  nil
  "OCR front-end for emacspeak desktop."
  :group 'emacspeak
  :prefix 'emacspeak-ocr)

(defcustom emacspeak-ocr-scan-image "scanimage"
  "Name of image acquisition program."
  :type 'string 
  :group 'emacspeak-ocr)

(defcustom emacspeak-ocr-scan-image-options 
  "--format tiff --resolution 400"
  "Command line options to pass to image acquisition program."
  :type 'string 
  :group 'emacspeak-ocr)

(defcustom emacspeak-ocr-compress-image "tiffcp"
  "Command used to compress the scanned tiff file."
  :type 'string
  :group 'emacspeak-ocr)

(defcustom emacspeak-ocr-compress-image-options   
  "-c g3 "
  "Options used for compressing tiff image."
  :type 'string
  :group 'emacspeak-ocr)

(defcustom emacspeak-ocr-engine "ocr"
  "OCR engine to process acquired image."
  :type 'string
  :group 'emacspeak-ocr)

(defcustom emacspeak-ocr-engine-options nil
  "Command line options to pass to OCR engine."
  :type'string
  :group 'emacspeak-ocr)

(defcustom emacspeak-ocr-working-directory
  (expand-file-name "~/ocr")
  "Directory where images and OCR results
will be placed."
  :group 'emacspeak-ocr
  :type 'string)

;;}}}
;;{{{  helpers

(defvar emacspeak-ocr-current-page-number  nil
  "Number of current page in document.")

(make-variable-buffer-local
 'emacspeak-ocr-current-page-number)

(defvar emacspeak-ocr-last-page-number nil
  "Number of last page in document.")

(make-variable-buffer-local 'emacspeak-ocr-last-page-number)

(defvar emacspeak-ocr-page-positions nil
  "Vector holding page start positions.")

(make-variable-buffer-local 'emacspeak-ocr-page-positions)



(defvar emacspeak-ocr-buffer-name "*ocr*"
  "Name of OCR working buffer.")

(defsubst emacspeak-ocr-get-buffer ()
  "Return OCR working buffer."
  (declare (special emacspeak-ocr-buffer-name))
  (get-buffer-create emacspeak-ocr-buffer-name))

(defsubst emacspeak-ocr-get-text-name ()
  "Return name of current text document."
  (declare (special emacspeak-ocr-document-name))
  (format "%s.text" emacspeak-ocr-document-name))

(defsubst emacspeak-ocr-get-image-name ()
  "Return name of current image."
  (declare (special emacspeak-ocr-document-name
                    emacspeak-ocr-current-page-number))
  (format "%s-%s.tiff"
          emacspeak-ocr-document-name
          (1+ emacspeak-ocr-current-page-number)))

(defsubst emacspeak-ocr-get-page-name ()
  "Return name of current page."
  (declare (special emacspeak-ocr-document-name
                    emacspeak-ocr-current-page-number))
  (format "%s-%s.txt"
          emacspeak-ocr-document-name
          emacspeak-ocr-current-page-number))

(defvar emacspeak-ocr-mode-line-format
  '(
   (buffer-name)
   " "
   "page-"
   emacspeak-ocr-current-page-number)
  "Mode line format for OCR buffer.")

(defsubst emacspeak-ocr-get-mode-line-format ()
  "Return string suitable for use as the mode line."
  (declare (special major-mode
                    emacspeak-ocr-current-page-number))
  (format "%s Page-%s %s"
          (buffer-name)
          emacspeak-ocr-current-page-number
          major-mode))


(defsubst emacspeak-ocr-update-mode-line()
  "Update mode line for OCR mode."
  (declare (special mode-line-format))
  (setq mode-line-format
        (emacspeak-ocr-get-mode-line-format)))


;;}}}
;;{{{  emacspeak-ocr mode
(declaim (special emacspeak-ocr-mode-map))

(define-derived-mode emacspeak-ocr-mode fundamental-mode 
  "Major mode for document scanning and  OCR."
  "Major mode for document scanning and OCR\n\n
\\{emacspeak-ocr-mode-map}"
  (progn
    (setq emacspeak-ocr-current-page-number 0
          emacspeak-ocr-last-page-number 0
          emacspeak-ocr-page-positions
          (make-vector 25 nil))
    (emacspeak-ocr-update-mode-line)
    (emacspeak-keymap-remove-emacspeak-edit-commands emacspeak-ocr-mode-map)))

(define-key emacspeak-ocr-mode-map "q" 'bury-buffer)
(define-key emacspeak-ocr-mode-map "w" 'emacspeak-ocr-write-document)
(define-key emacspeak-ocr-mode-map "\C-m"  'emacspeak-ocr-scan-and-recognize)
(define-key emacspeak-ocr-mode-map "i" 'emacspeak-ocr-scan-image)
(define-key emacspeak-ocr-mode-map "o" 'emacspeak-ocr-recognize-image)
(define-key emacspeak-ocr-mode-map "n" 'emacspeak-ocr-name-document)
(define-key emacspeak-ocr-mode-map "d" 'emacspeak-ocr-open-working-directory)
(define-key emacspeak-ocr-mode-map "[" 'emacspeak-ocr-backward-page)
(define-key emacspeak-ocr-mode-map "]"'emacspeak-ocr-forward-page)
(define-key emacspeak-ocr-mode-map "p" 'emacspeak-ocr-page)
(define-key emacspeak-ocr-mode-map "s" 'emacspeak-ocr-save-current-page)
(define-key emacspeak-ocr-mode-map " "
  'emacspeak-ocr-read-current-page)

(loop for i from 1 to 9
      do
      (define-key emacspeak-ocr-mode-map
        (format "%s" i)
        'emacspeak-ocr-page))

;;}}}
;;{{{ interactive commands

(defun emacspeak-ocr ()
  "OCR front-end for Emacspeak desktop.  
Page image is acquired
using user space tools from the SANE package.  The acquired
image is run through the OCR engine if one is available, and
the results placed in a buffer that is suitable for browsing the results."
  (interactive)
  (declare (special emacspeak-ocr-working-directory
                    buffer-read-only))
  (let  ((buffer (emacspeak-ocr-get-buffer )))
    (save-excursion
      (set-buffer buffer)
      (emacspeak-ocr-mode)
      (when (file-exists-p emacspeak-ocr-working-directory)
        (cd emacspeak-ocr-working-directory))
      (switch-to-buffer buffer)
      (setq buffer-read-only t)
      (emacspeak-ocr-name-document "untitled")
      (emacspeak-auditory-icon 'open-object)
      (emacspeak-speak-mode-line))))

(defvar emacspeak-ocr-document-name nil
  "Names document being scanned.
This name will be used as the prefix for naming image and
text files produced in this scan.")

(make-variable-buffer-local 'emacspeak-ocr-document-name)

(defun emacspeak-ocr-name-document (name)
  "Name document being scanned in the current OCR buffer.
Pick a short but meaningful name."
  (interactive
   (list
    (read-from-minibuffer "Document name: ")))
  (declare (special emacspeak-ocr-document-name
                    mode-line-format))
  (setq emacspeak-ocr-document-name name)
  (rename-buffer
   (format "*%s-ocr*" name)
   'unique)
  (emacspeak-ocr-update-mode-line)
  (emacspeak-auditory-icon 'select-object)
  (emacspeak-speak-mode-line))

(defun emacspeak-ocr-scan-image ()
  "Acquire page image."
  (interactive)
  (declare (special emacspeak-speak-messages 
                    emacspeak-ocr-scan-image
                    emacspeak-ocr-scan-image-options
                    emacspeak-ocr-compress-image
                    emacspeak-ocr-compress-image-options
                    emacspeak-ocr-document-name))
  (let ((image-name (emacspeak-ocr-get-image-name)))
    (let ((emacspeak-speak-messages nil))
      (shell-command
       (concat
        (format "%s %s > temp.tiff;\n"
                emacspeak-ocr-scan-image
                emacspeak-ocr-scan-image-options )
        (format "%s %s  temp.tiff %s ;\n"
                emacspeak-ocr-compress-image
                emacspeak-ocr-compress-image-options 
                image-name)
        (format "rm -f temp.tiff"))))
    (message "Acquired  image to file %s"
             image-name)))

(defvar emacspeak-ocr-process nil
  "Handle to OCR process.")

(defun emacspeak-ocr-write-document ()
  "Writes out recognized text from all pages in current document."
  (interactive)
  (cond
   ((= 0 emacspeak-ocr-current-page-number)
    (message "No pages in current document."))
  (t (write-region
      (point-min)
          (point-max)
     (emacspeak-ocr-get-text-name))
(emacspeak-auditory-icon 'save-object))))

(defun emacspeak-ocr-save-current-page ()
  "Writes out recognized text from current page
to an appropriately named file."
  (interactive)
  (declare (special emacspeak-ocr-current-page-number
                    emacspeak-ocr-page-positions))
  (cond
   ((= 0 emacspeak-ocr-current-page-number)
    (message "No pages in current document."))
  (t (write-region
      (aref emacspeak-ocr-page-positions
            emacspeak-ocr-current-page-number)
      (if (= emacspeak-ocr-current-page-number
             emacspeak-ocr-last-page-number)
          (point-max)
        (aref emacspeak-ocr-page-positions (1+
                                            emacspeak-ocr-current-page-number)))
     (emacspeak-ocr-get-page-name))
(emacspeak-auditory-icon 'save-object))))

(defun emacspeak-ocr-process-sentinel  (process state)
  "Alert user when OCR is complete."
  (declare (special emacspeak-ocr-page-positions
                    emacspeak-ocr-last-page-number
                    emacspeak-ocr-current-page-number))
  (setq emacspeak-ocr-current-page-number
        emacspeak-ocr-last-page-number)
  (emacspeak-auditory-icon 'task-done)
  (goto-char (aref emacspeak-ocr-page-positions
                   emacspeak-ocr-current-page-number))
  (emacspeak-ocr-save-current-page)
  (emacspeak-ocr-update-mode-line)
  (emacspeak-speak-line))


(defun emacspeak-ocr-recognize-image ()
  "Run OCR engine on current image.
Prompts for image file if file corresponding to the expected
`current page' is not found."
  (interactive)
  (declare (special emacspeak-ocr-engine
                    emacspeak-ocr-engine-options
                    emacspeak-ocr-process
                    emacspeak-ocr-last-page-number
                    emacspeak-ocr-page-positions))
  (let ((inhibit-read-only t)
        (image-name
         (if (file-exists-p (emacspeak-ocr-get-image-name))
             (emacspeak-ocr-get-image-name)
           (expand-file-name 
           (read-file-name "Image file to recognize: ")))))
    (goto-char (point-max))
    (setq emacspeak-ocr-last-page-number
          (1+ emacspeak-ocr-last-page-number))
    (aset emacspeak-ocr-page-positions
          emacspeak-ocr-last-page-number
          (+ 3 (point)))
    (insert
     (format "\n%c\nPage %s\n" 12
             emacspeak-ocr-last-page-number))
    (message "%s %s"
emacspeak-ocr-engine
           image-name)
    (setq emacspeak-ocr-process
          (start-process 
           "ocr"
           (current-buffer)
           emacspeak-ocr-engine
           image-name))
    (set-process-sentinel emacspeak-ocr-process
                          'emacspeak-ocr-process-sentinel)
    (message "Launched OCR engine.")))


(defun emacspeak-ocr-scan-and-recognize ()
  "Scan in a page and run OCR engine on it.
Use this command once you've verified that the separate
steps of acquiring an image and running the OCR engine work
corectly by themselves."
  (interactive)
  (emacspeak-ocr-scan-image)
  (emacspeak-ocr-recognize-image))


(defun emacspeak-ocr-toggle-read-only ()
  "Toggle read-only state of OCR buffer."
  (interactive)
  (declare (special buffer-read-only))
  (setq buffer-read-only
        (not buffer-read-only))
  (emacspeak-auditory-icon 'button)
  (emacspeak-speak-mode-line))

(defun emacspeak-ocr-open-working-directory ()
  "Launch dired on OCR workng directory."
  (interactive)
  (declare (special emacspeak-ocr-working-directory))
  (switch-to-buffer
   (dired-noselect emacspeak-ocr-working-directory))
  (emacspeak-auditory-icon 'open-object)
  (emacspeak-speak-mode-line))

(defun emacspeak-ocr-forward-page (&optional count-ignored)
  "Like forward page, but tracks page number of current document."
  (interactive "p")
  (declare (special emacspeak-ocr-page-positions
                    emacspeak-ocr-last-page-number
                    emacspeak-ocr-current-page-number))
  (cond
   ((= 0 emacspeak-ocr-current-page-number)
    (message "No pages in current document."))
   ((= emacspeak-ocr-last-page-number
       emacspeak-ocr-current-page-number)
    (goto-char
     (point-max))
    (emacspeak-auditory-icon 'select-object)
    (message "This is the last page."))
   (t (setq emacspeak-ocr-current-page-number
            (1+ emacspeak-ocr-current-page-number))
      (goto-char (aref emacspeak-ocr-page-positions
                       emacspeak-ocr-current-page-number))
      (emacspeak-ocr-update-mode-line)
      (emacspeak-speak-line)
      (emacspeak-auditory-icon 'large-movement))))

(defun emacspeak-ocr-backward-page (&optional count-ignored)
  "Like backward page, but tracks page number of current document."
  (interactive "p")
  (declare (special emacspeak-ocr-page-positions
                    emacspeak-ocr-current-page-number))
  (cond
   ((= 0 emacspeak-ocr-current-page-number)
    (message "No pages in current document."))
   ((= 1
       emacspeak-ocr-current-page-number)
    (goto-char
     (aref emacspeak-ocr-page-positions
           emacspeak-ocr-current-page-number))
    (emacspeak-auditory-icon 'select-object)
    (message "This is the first page."))
   (t (setq emacspeak-ocr-current-page-number
            (1- emacspeak-ocr-current-page-number))
      (emacspeak-ocr-update-mode-line)
      (goto-char (aref emacspeak-ocr-page-positions
                       emacspeak-ocr-current-page-number))
      (emacspeak-speak-line)
      (emacspeak-auditory-icon 'large-movement))))


(defsubst emacspeak-ocr-goto-page (page)
  "Move to specified page."
  (declare (special emacspeak-ocr-page-positions))
  (goto-char
   (aref emacspeak-ocr-page-positions page))
  (emacspeak-ocr-update-mode-line)
  (emacspeak-auditory-icon 'large-movement)
  (emacspeak-speak-line)
  )

(defun emacspeak-ocr-page ()
  "Move to specified page."
  (interactive )
  (when (= 0 emacspeak-ocr-last-page-number)
    (error "No pages in current document."))
  (let ((page
         (condition-case nil
             (read (format "%c" last-input-event ))
           (error nil ))))
    (or (numberp page)
        (setq page
              (read-minibuffer
               (format "Page number between 1 and %s: "
                       emacspeak-ocr-last-page-number))))
    (cond
     ((> page emacspeak-ocr-last-page-number)
      (message "Not that many pages in document."))
     (t 
      (emacspeak-ocr-goto-page page)))))

(defun emacspeak-ocr-read-current-page ()
  "Speaks current page."
  (interactive)
  (declare (special emacspeak-ocr-page-positions
                    emacspeak-ocr-current-page-number
                    emacspeak-ocr-last-page-number))
  (cond
   ((= emacspeak-ocr-current-page-number
       emacspeak-ocr-last-page-number)
    (emacspeak-speak-region
     (aref emacspeak-ocr-page-positions
           emacspeak-ocr-current-page-number)
     (point-max)))
   (t (emacspeak-speak-region
       (aref emacspeak-ocr-page-positions
             emacspeak-ocr-current-page-number)
       (aref emacspeak-ocr-page-positions
             (1+ emacspeak-ocr-current-page-number))))))

;;}}}
(provide 'emacspeak-ocr)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
