;;; emacspeak-bookshare.el --- Speech-enabled  BOOKSHARE client
;;; $Id: emacspeak-bookshare.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable BOOKSHARE An Emacs Interface to bookshare
;;; Keywords: Emacspeak,  Audio Desktop bookshare
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
;;; MERCHANTABILITY or FITNBOOKSHARE FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:
;;; BOOKSHARE == http://www.bookshare.org provides book access to print-disabled users.
;;; It provides a simple Web  API http://developer.bookshare.org
;;; This module implements an Emacspeak Bookshare client.
;;; For now, users will need to get their own API key
;;; This might change once I get approval from Bookshare to embed the Emacspeak API  key in the Source code.

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)

;;}}}
;;{{{ Customizations

(defgroup emacspeak-bookshare nil
  "Bookshare Access on the Complete Audio Desktop."
  :group 'emacspeak)

(defcustom emacspeak-bookshare-api-key nil
  "Web API  key for this application."
  :type
  '(choice :tag "Key: "
           (const :tag "Unspecified" nil)
           (string :tag "API Key: "))
  :group 'emacspeak-bookshare)

(defcustom emacspeak-bookshare-user-id nil
  "Bookshare user Id."
  :type '(choice :tag "Bookshare User id"
                 (const :tag "None" nil)
                 (string :tag "Email"))
  :group 'emacspeak-bookshare)

(defcustom emacspeak-bookshare-downloads-directory (expand-file-name "~/")
  "Customize this to the root of where books are organized."
  :type 'directory
  :group 'emacspeak-bookshare)

;;}}}
;;{{{ Variables:

(defvar emacspeak-bookshare-curl-program (executable-find "curl")
  "Curl executable.")

(defvar emacspeak-bookshare-curl-common-options
  " --insecure "
  "Common Curl options for Bookshare. Includes --insecure  as per Bookshare docs.")

(defvar emacspeak-bookshare-api-base "https://api.bookshare.org"
  "Base end-point for Bookshare API  access.")

;;}}}
;;{{{ Helpers:

(defvar emacspeak-bookshare-md5-cached-token nil
  "Cache MD5 token for future use.")

(defsubst emacspeak-bookshare-user-password ()
  "User password.
Memoize token, and return token encoded using md5, and packaged
with X-password HTTP header for use with Curl."
  (declare (special emacspeak-bookshare-md5-cached-token))
  (or emacspeak-bookshare-md5-cached-token
      (setq emacspeak-bookshare-md5-cached-token
            (md5 (read-passwd (format "Bookshare password for %s: " emacspeak-bookshare-user-id)))))
  (format
   "-H 'X-password: %s'"
   emacspeak-bookshare-md5-cached-token))

(defsubst emacspeak-bookshare-rest-endpoint (operation operand)
  "Return  URL  end point for specified operation.
For now, we user-authenticate  all operations."

  (declare (special emacspeak-bookshare-api-base
                    emacspeak-bookshare-user-id))
  (format "%s/%s/%s/for/%s?api_key=%s"
          emacspeak-bookshare-api-base
          operation
          (emacspeak-url-encode operand)
          emacspeak-bookshare-user-id
          emacspeak-bookshare-api-key))

(defvar emacspeak-bookshare-scratch-buffer " *Bookshare Scratch* "
  "Scratch buffer for Bookshare operations.")

(defmacro emacspeak-bookshare-using-scratch(&rest body)
  "Evaluate forms in a  ready to use temporary buffer."
  `(let ((buffer (get-buffer-create emacspeak-bookshare-scratch-buffer))
         (default-process-coding-system (cons 'utf-8 'utf-8))
         (coding-system-for-read 'binary)
         (coding-system-for-write 'binary)
         (buffer-undo-list t))
     (save-excursion
       (set-buffer buffer)
       (kill-all-local-variables)
       (erase-buffer)
       (progn ,@body))))

(defsubst emacspeak-bookshare-get-result (command)
  "Run command and return its output."
  (declare (special shell-file-name shell-command-switch))
  (emacspeak-bookshare-using-scratch
   (call-process shell-file-name nil t
                 nil shell-command-switch
                 command)
   (goto-char (point-min))
   (read-xml)))

(defun emacspeak-bookshare-api-call (operation operand)
  "Make a Bookshare API  call and get the result."
  (emacspeak-bookshare-get-result
   (format
    "%s %s %s  %s 2>/dev/null"
    emacspeak-bookshare-curl-program emacspeak-bookshare-curl-common-options
    (emacspeak-bookshare-user-password)
    (emacspeak-bookshare-rest-endpoint operation operand))))

;;}}}
;;{{{ Book Actions:

;;;  Following actions return book metadata:
(defun emacspeak-bookshare-id-search (query)
  "Perform a Bookshare id search."
  (emacspeak-bookshare-api-call "book/id" query))



;;; Following Actions return book-list structures within a bookshare envelope.

(defun emacspeak-bookshare-author-search (query)
  "Perform a Bookshare author search."
  (emacspeak-bookshare-api-call "book/searchFTS/author" query))

(defun emacspeak-bookshare-title-search (query)
  "Perform a Bookshare title search."
  (emacspeak-bookshare-api-call "book/searchFTS/title" query))

(defun emacspeak-bookshare-isbn-search (query)
  "Perform a Bookshare isbn search."
  (emacspeak-bookshare-api-call "book/isbn" query))



(defun emacspeak-bookshare-title/author-search (query)
  "Perform a Bookshare title/author  search."
  (emacspeak-bookshare-api-call "book/searchTA" query))

(defun emacspeak-bookshare-since-search (query)
  "Perform a Bookshare since  search."
  (emacspeak-bookshare-api-call "book/since" query))

(defun emacspeak-bookshare-browse-latest()
  "Return latest books."
  (emacspeak-bookshare-api-call "book/browse/latest" ""))

(defun emacspeak-bookshare-browse-popular()
  "Return popular books."
  (emacspeak-bookshare-api-call "book/browse/popular" ""))



(defun emacspeak-bookshare-fulltext-search (query)
  "Perform a Bookshare fulltext search."
  (emacspeak-bookshare-api-call "book/searchFTS" query))
;;; Need to implement code to build a cache of categories and
;;; grades to enable complex searches.

;;}}}
;;{{{ Bookshare Mode:

(define-derived-mode emacspeak-bookshare-mode text-mode
  "Bookshare Library Of Accessible Books And Periodicals"
  "A Bookshare front-end for the Emacspeak desktop.

Pre-requisites:




The Emacspeak Bookshare front-end is launched by command
emacspeak-bookshare bound to \\[emacspeak-bookshare]

This command switches to a special buffer that has Bookshare
commands bounds to single keystrokes-- see the ke-binding
list at the end of this description.  Use Emacs online help
facility to look up help on these commands.

emacspeak-bookshare-mode provides the necessary functionality to
Search and download Bookshare material,
Manage a local library of downloaded Bookshare content,
And commands to easily read newer Daisy books from Bookshare.
For legacy Bookshare material, see command \\[emacspeak-daisy-open-book].

Here is a list of all emacspeak Bookshare commands along with their key-bindings:

\\{emacspeak-bookshare-mode-map}"
  (progn
    (goto-char (point-min))
    (insert "Browse And Read Bookshare Materials\n\n")Browse And Read Bookshare 
    (setq header-line-format "Bookshare Library")))



(defvar emacspeak-bookshare-interaction-buffer "*Bookshare*"
  "Buffer for Bookshare interaction.")

(defun emacspeak-bookshare ()
  "Bookshare  Interaction."
  (interactive)
  (declare (special emacspeak-bookshare-interaction-buffer))
  (let ((buffer (get-buffer-create emacspeak-bookshare-interaction-buffer)))
        (with-current-buffer buffer
          (erase-buffer)
          (emacspeak-bookshare-mode))
        (switch-to-buffer buffer)))
;;}}}
(provide 'emacspeak-bookshare)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
