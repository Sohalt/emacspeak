;;; emacspeak-epub.el --- epubs Front-end for emacspeak desktop
;;; $Id: emacspeak-epub.el 5798 2008-08-22 17:35:01Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Emacspeak front-end for EPUBS Talking Books
;;; Keywords: Emacspeak, epubs Digital Talking Books
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2008-06-21 10:50:41 -0700 (Sat, 21 Jun 2008) $ |
;;;  $Revision: 4541 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;; Copyright (C) 1999, 2011 T. V. Raman <raman@cs.cornell.edu>
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
;;; In celebration of a million books and more to read from
;;; Google Books
;;; The EPubs format is slightly simpler than full Daisy ---
;;; (see) emacspeak-daisy.el
;;; Since it only needs one level of indirection (no audio,
;;; therefore no smil). This module is consequently simpler than
;;; emacspeak-daisy.el.
;;; This module will eventually  implement the Google Books GData API
;;; --- probably by invoking the yet-to-be-written gbooks.el in emacs-g-client
;;; As we move to epub-3, this module will bring back audio layers etc., perhaps via a simplified smil implementation.
;;; Code:

;;}}}
;;{{{ Required Modules:

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'emacspeak-xslt)
(require 'derived)
(require 'find-lisp)

;;}}}
;;{{{  Customization variables

(defgroup emacspeak-epub nil
  "Epubs Digital  Books  for the Emacspeak desktop."
  :group 'emacspeak)

(defcustom emacspeak-epub-library-directory
  (expand-file-name "~/epubs/")
  "Directory under which we store Epubs."
  :type 'directory
  :group 'emacspeak-epub)


(defcustom emacspeak-epub-zip-extract
  (cond ((executable-find "unzip")   '("unzip" "-qq" "-c"))
	((executable-find "7z")      '("7z" "x" "-so"))
	((executable-find "pkunzip") '("pkunzip" "-e" "-o-"))
	(t                           '("unzip" "-qq" "-c")))
  "Program and its options to run in order to extract a zip file member.
Extraction should happen to standard output.  Archive and member name will
be added."
  :type '(list (string :tag "Program")
	       (repeat :tag "Options"
		       :inline t
		       (string :format "%v")))
  :group 'emacspeak-epub)

;;}}}
;;{{{ Epub Mode:

(define-derived-mode emacspeak-epub-mode special-mode
  "EPub Interaction On The Emacspeak Audio Desktop"
  "An EPub Front-end."
  (let ((inhibit-read-only t)
        (start (point)))
    (goto-char (point-min))
    (insert "Browse And Read EPub Materials\n\n")
    (put-text-property start (point)
                       'face font-lock-doc-face)
    (setq header-line-format "EPub Library")
    (cd-absolute emacspeak-epub-library-directory)))

;;}}}
;;{{{ EPub Implementation:
(defvar emacspeak-epub-toc-path-pattern
  ".ncx$"
  "Pattern match for path component  to table of contents in an Epub.")

(defvar emacspeak-epub-toc-command
  (format "zipinfo -1 %%s | grep %s" emacspeak-epub-toc-path-pattern)
  "Command that returns location of .ncx file in an epub archive.")

(defsubst emacspeak-epub-get-toc (file)
  "Return location of .ncx file within epub archive."
  (declare (special emacspeak-epub-toc-command))
  (substring 
         (shell-command-to-string (format emacspeak-epub-toc-command file )) 0 -1)))
(defvar emacspeak-epub-ls-command
  (format "zipinfo -1 %%s ")
  "Shell command that returns list of files in an epub archive.")

(defsubst emacspeak-epub-get-ls (file)
  "Return list of files in an epub archive."
  (declare (special emacspeak-epub-ls-command))
  (split-string
   (shell-command-to-string (format emacspeak-epub-ls-command file ))))

(defstruct emacspeak-epub
  path ; path to .epub file
  toc ; path to .ncx file in archive
  ls ; list of files in archive
)

(defun emacspeak-epub-make-epub  (epub-file)
  "Construct an epub object given an epub filename."
  (let ((epub
         (make-emacspeak-epub
          :path epub-file
          :toc (emacspeak-epub-get-toc epub-file)
          :ls (emacspeak-epub-get-ls epub-file))))
    epub))

;;}}}
;;{{{ Interactive Commands:

(defvar emacspeak-epub-interaction-buffer "*EPub*"
  "Buffer for EPub interaction.")

;;;###autoload
(defun emacspeak-epub ()
  "EPub  Interaction."
  (interactive)
  (declare (special emacspeak-epub-interaction-buffer))
  (let ((buffer (get-buffer emacspeak-epub-interaction-buffer)))
    (cond
     ((buffer-live-p buffer) (switch-to-buffer buffer))
     (t
      (with-current-buffer (get-buffer-create emacspeak-epub-interaction-buffer)
        (erase-buffer)
        (setq buffer-undo-list t)
        (emacspeak-epub-mode)
        (setq buffer-read-only t))
      (switch-to-buffer emacspeak-epub-interaction-buffer)))
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

(declaim (special emacspeak-epub-mode-map))
(loop for k in
      '(
        ("o" emacspeak-epub-open)
        ("g" emacspeak-epub-google)
        )
      do
      (emacspeak-keymap-update emacspeak-epub-mode-map k))



(defvar emacspeak-epub-toc-transform
  (expand-file-name "epub-toc.xsl" emacspeak-xslt-directory)
  "XSLT  Transform that maps epub-toc to HTML.")

;;;###autoload
(defun emacspeak-epub-open (toc)
  "Open specified Epub.
`toc' is the pathname to an EPubs table of contents."
  (interactive
   (list
    (emacspeak-epub-get-toc-path)))
  (declare (special emacspeak-epub-toc-transform))
  (emacspeak-webutils-autospeak)
  (emacspeak-xslt-view-file emacspeak-epub-toc-transform toc))

(defvar emacspeak-epub-google-search-template
  "http://books.google.com/books/feeds/volumes?min-viewability=full&epub=epub&q=%s"
  "REST  end-point for performing Google Books Search to find Epubs  having full viewability.")

;;;###autoload
(defun emacspeak-epub-google (query)
  "Search for Epubs from Gooble Books."
  (interactive "sGoogle Books Query: ")
  (declare (special emacspeak-epub-google-search-template))
  (emacspeak-webutils-atom-display
   (format emacspeak-epub-google-search-template
           (emacspeak-url-encode query))))

;;}}}

(provide 'emacspeak-epub)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
