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
(require 'xml-parse)
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

(defsubst emacspeak-bookshare-isbn-search (query)
  "Perform a Bookshare isbn search."
  (interactive "sISBN: ")
  (emacspeak-bookshare-api-call "book/isbn" query))
(defsubst emacspeak-bookshare-id-search (query)
  "Perform a Bookshare id search."
  (interactive "sId: ")
  (emacspeak-bookshare-api-call "book/id" query))

;;; Following Actions return book-list structures within a bookshare envelope.

(defsubst emacspeak-bookshare-author-search (query)
  "Perform a Bookshare author search."
  (interactive "sAuthor: ")
  (emacspeak-bookshare-api-call "book/searchFTS/author" query))

(defsubst emacspeak-bookshare-title-search (query)
  "Perform a Bookshare title search."
  (interactive "sTitle: ")
  (emacspeak-bookshare-api-call "book/searchFTS/title" query))

(defsubst emacspeak-bookshare-title/author-search (query)
  "Perform a Bookshare title/author  search."
  (interactive "sTitle/Author: ")
  (emacspeak-bookshare-api-call "book/searchTA" query))

(defsubst emacspeak-bookshare-fulltext-search (query)
  "Perform a Bookshare fulltext search."
  (interactive "sFulltext Search: ")
  (emacspeak-bookshare-api-call "book/searchFTS" query))


(defsubst emacspeak-bookshare-since-search (query)
  "Perform a Bookshare since  search."
  (interactive "sDate: ")
  (emacspeak-bookshare-api-call "book/since" query))

(defsubst emacspeak-bookshare-browse-latest()
  "Return latest books."
  (interactive)
  (emacspeak-bookshare-api-call "book/browse/latest" ""))

(defsubst emacspeak-bookshare-browse-popular()
  "Return popular books."
  (interactive)
  (emacspeak-bookshare-api-call "book/browse/popular" ""))

;;; Need to implement code to build a cache of categories and
;;; grades to enable complex searches.

;;}}}
;;{{{ Actions Table:

(defvar emacspeak-bookshare-action-table (make-hash-table :test #'equal)
  "Table mapping Bookshare actions to  handlers.")

(defsubst emacspeak-bookshare-action-set (action handler)
  "Set up action handler."
  (declare (special emacspeak-bookshare-action-table))
  (setf (gethash action emacspeak-bookshare-action-table)
        handler))

(defsubst emacspeak-bookshare-action-get (action)
  "Retrieve action handler."
  (declare (special emacspeak-bookshare-action-table))
  (or (gethash action emacspeak-bookshare-action-table)
      (error "No handler defined for action %s" action)))

  
(declaim (special emacspeak-bookshare-mode-map))

(loop for a in
      '(
        ("a" emacspeak-bookshare-author-search)
        ("t" emacspeak-bookshare-title-search)
        ("s" emacspeak-bookshare-fulltext-search)
        ("A" emacspeak-bookshare-title/author-search)
        ("d" emacspeak-bookshare-since-search)
        ("i" emacspeak-bookshare-isbn-search)
        ("I" emacspeak-bookshare-id-search)
        ("p" emacspeak-bookshare-browse-popular)
        ("l" emacspeak-bookshare-browse-latest)
        )
      do
      (progn
      (emacspeak-bookshare-action-set (first a) (second a))
      (define-key emacspeak-bookshare-mode-map (first a) 'emacspeak-bookshare-action)))

;;}}}
;;{{{ Bookshare XML  handlers:

(defvar emacspeak-bookshare-handler-table  (make-hash-table :test
                                                            #'equal)
  "Table of handlers for processing various Bookshare response
elements.")

(defsubst emacspeak-bookshare-handler-set (element handler)
  "Set up element handler."
  (declare (special emacspeak-bookshare-handler-table))
  (setf (gethash element emacspeak-bookshare-handler-table) handler))

(defsubst emacspeak-bookshare-handler-get (element)
  "Retrieve action handler."
  (declare (special emacspeak-bookshare-handler-table))
  (or (fboundp (gethash element emacspeak-bookshare-handler-table))
      'emacspeak-bookshare-recurse))

(defvar emacspeak-bookshare-response-elements
  '("bookshare"
    "version"
    "messages"
    "string"
    "book"
    "list"
    "page"
    "num-pages"
    "limit"
    "result")
  "Bookshare response elements for which we have explicit
  handlers.")

(loop for e in emacspeak-bookshare-response-elements
      do
      (emacspeak-bookshare-handler-set e
                                   (intern
                                    (format
                                     "emacspeak-bookshare-%s-handler" e))))


(defsubst emacspeak-bookshare-apply-handler (element)
  "Lookup and apply installed handler."
  (let* ((tag (xml-tag-name element))
         (handler  (emacspeak-bookshare-handler-get tag)))
    (cond
     ((and handler (fboundp handler))
      (funcall handler element))
     (t (insert (format "Handler for %s not implemented yet.\n" tag))))))

(defun emacspeak-bookshare-bookshare-handler (response)
  "Handle Bookshare response."
  (unless (string-equal (xml-tag-name response) "bookshare")
    (error "Does not look like a Bookshare response."))
  (mapc 'emacspeak-bookshare-apply-handler (xml-tag-children response)))


(defalias 'emacspeak-bookshare-version-handler 'ignore)

(defun emacspeak-bookshare-recurse (tree)
  "Recurse down tree."
  (insert (format "Begin %s:\n" (xml-tag-name tree)))
  (mapc #'emacspeak-bookshare-apply-handler (xml-tag-children tree))
  (insert (format "End %s\n" (xml-tag-name tree))))

(defun emacspeak-bookshare-messages-handler (messages)
  "Handle messages element."
  (mapc #'insert(rest  (xml-tag-child messages "string")))
  (insert "\n"))

(defun emacspeak-bookshare-book-handler (book)
  "Handle book element in book list response."
  (emacspeak-bookshare-apply-handler (xml-tag-child book
                                                    "list")))
(defun emacspeak-bookshare-list-handler (list)
  "Handle list element in Bookshare book list response."
  (mapc #'emacspeak-bookshare-apply-handler
        (xml-tag-children list )))

(defun emacspeak-bookshare-page-handler (page)
  "Handle page element."
  (insert (format "Page: %s" (second page))))

(defun emacspeak-bookshare-limit-handler (limit)
  "Handle limit element."
  (insert (format "Limit: %s" (second limit))))

(defun emacspeak-bookshare-num-pages-handler (num-pages)
  "Handle num-pages element."
  (insert
   (format "Num-Pages: %s" (second num-pages))))

(defun emacspeak-bookshare-result-handler (result)
  "Handle result element in Bookshare response."
  (insert "\n")
  (let* ((children (xml-tag-children result))
        (start (point))
        (id (second (assoc "id" children)))
        (title (second (assoc "title" children)))
        (author (second (assoc "author" children))))
    (insert (format "Author:\t%s Title:%s" author title))
    (add-text-properties
     start (point)
                              (list 'author author 'title title 'id id))))

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
    (insert "Browse And Read Bookshare Materials\n\n")
    (setq header-line-format "Bookshare Library")))

(defun emacspeak-bookshare-define-keys ()
  "Define keys for  Bookshare Interaction."
  (declare (special emacspeak-bookshare-mode-map))
  (loop for k in 
      '(
        ("q" bury-buffer)
        )
      do
      (emacspeak-keymap-update  emacspeak-bookshare-mode-map k)))
  
(emacspeak-bookshare-define-keys)

(defvar emacspeak-bookshare-interaction-buffer "*Bookshare*"
  "Buffer for Bookshare interaction.")

;;;###autoload
(defun emacspeak-bookshare ()
  "Bookshare  Interaction."
  (interactive)
  (declare (special emacspeak-bookshare-interaction-buffer))
  (let ((buffer (get-buffer emacspeak-bookshare-interaction-buffer)))
    (cond
     ((buffer-live-p buffer)
      (switch-to-buffer buffer)
      (emacspeak-auditory-icon 'open-object)
      (emacspeak-speak-mode-line))
     (t
      (with-current-buffer (get-buffer-create emacspeak-bookshare-interaction-buffer)
        (erase-buffer)
        (emacspeak-bookshare-mode))
      (switch-to-buffer emacspeak-bookshare-interaction-buffer)
      (emacspeak-auditory-icon 'open-object)
      (emacspeak-speak-mode-line)))))


(defun emacspeak-bookshare-action  ()
  "Call action specified by  invoking key."
  (interactive)
  (insert "\n")
  (let* ((key (format "%c" last-input-event))
         (response (call-interactively (emacspeak-bookshare-action-get key)))
         (start (point)))
    (emacspeak-bookshare-bookshare-handler response)
    (emacspeak-auditory-icon 'task-done)
    (put-text-property start (point)
                       'action (emacspeak-bookshare-action-get key))
    (goto-char start)
    (emacspeak-speak-line)))

;;}}}
;;{{{ Book List Viewers:

;;}}}
(provide 'emacspeak-bookshare)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
