;;; gsearch.el --- Google Search
;;;$Id: gcal.el,v 1.30 2006/09/28 17:47:44 raman Exp $
;;; $Author: raman $
;;; Description:  AJAX Search -> Lisp
;;; Keywords: Google   AJAX API
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; gcal| T. V. Raman |raman@cs.cornell.edu
;;; An emacs interface to Reader|
;;; $Date: 2006/09/28 17:47:44 $ |
;;;  $Revision: 1.30 $ |
;;; Location undetermined
;;; License: GPL
;;;

;;}}}
;;{{{ Copyright:

;;; Copyright (c) 2006 and later, Google Inc.
;;; All rights reserved.

;;; Redistribution and use in source and binary forms, with or without modification,
;;; are permitted provided that the following conditions are met:

;;;     * Redistributions of source code must retain the above copyright notice,
;;;       this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above copyright notice,
;;;       this list of conditions and the following disclaimer in the documentation
;;;       and/or other materials provided with the distribution.
;;;     * The name of the author may not be used to endorse or promote products
;;;       derived from this software without specific prior written permission.

;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
;;; STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
;;; WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;;; SUCH DAMAGE.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Commentary:
;;{{{  introduction

;;; Provide Google services --- such as search, search-based completion etc.
;;; For use from within Emacs tools.
;;; This is meant to be fast and efficient --- and uses WebAPIs as opposed to HTML  scraping.

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'g-utils)

;;}}}
;;{{{ Customizations

(defgroup gsearch nil
  "Google search"
  :group 'g)

;;}}}
;;{{{ Variables

(defvar gsearch-search-command
  "curl -s -e http://emacspeak.sf.net \
'http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=%s'"
  "URL template for Websearch command.")

;;}}}
;;{{{ Search Helpers
(defsubst gsearch-results (query)
  "Return results list."
  (declare (special gsearch-search-command))
  (let ((result nil)
        (buffer (get-buffer-create " *Google Results*"))
        (json-key-type 'string))
    (save-current-buffer
      (set-buffer buffer)
      (setq buffer-undo-list t)
      (erase-buffer)
      (shell-command
       (format gsearch-search-command (g-url-encode query))
       buffer)
      (goto-char (point-min))
      (setq result
      (g-json-lookup "responseData.results"
                     (json-read)))
      (bury-buffer buffer)
      result)))

;;}}}
;;{{{ google suggest helper:

;;; Get search completions from Google
;;; Inspired by code found on Emacs Wiki:
;;; http://www.emacswiki.org/cgi-bin/wiki/emacs-w3m#WThreeM

;;; csv version not used, but here for reference.

(defvar gsearch-suggest-command
  "curl -s\
 'http://www.google.com/complete/search?csv=true&qu=%s' \
 | head -2 | tail -1 \
| sed -e 's/\"//g'"
  "Command that gets suggestions from Google.")

(defvar gsearch-suggest-json
  "curl -s\
 'http://www.google.com/complete/search?json=true&qu=%s' "
  "URL  that gets suggestions from Google as JSON.")

(defsubst gsearch-suggest (input)
  "Get completion list from Google Suggest."
  (declare (special gsearch-suggest-json))
  (let ((buffer (get-buffer-create "*Google AutoComplete*")))
    (save-current-buffer
      (set-buffer buffer)
      (setq buffer-undo-list t)
      (erase-buffer)
      (shell-command
       (format gsearch-suggest-json
               (g-url-encode input))
       buffer)
      (goto-char (point-min))
      ;; A JSON array is a vector.
      ;; read it, filter the comma separators found as symbols.
      (delq'\,
       (append                          ; vector->list
        (aref (read (current-buffer)) 2)
        nil)))))

(defun gsearch-suggest-completer (string predicate mode)
  "Generate completions using Google Suggest. "
  (save-current-buffer 
    (set-buffer 
     (let ((window (minibuffer-selected-window))) 
       (if (window-live-p window) 
           (window-buffer window) 
         (current-buffer)))) 
    (complete-with-action mode 
                          (gsearch-suggest string) 
                          string predicate)))

(defsubst gsearch-google-autocomplete (&optional prompt)
  "Read user input using Google Suggest for auto-completion."
  (let ((minibuffer-completing-file-name t) ;; so we can type
        ;; spaces
        (completion-ignore-case t)
        (word (thing-at-point 'word)))
    (g-url-encode
     (completing-read
      (or prompt "Google: ")
      'gsearch-suggest-completer
      nil nil
      nil nil word))))

;;}}}
;;{{{ Interactive Commands:

;;; Need to be smarter about guessing default term 
;;; thing-at-point can return an empty string,
;;; and this is not a good thing for Google Suggest which will error out.

;;;###autoload
(defun gsearch-google-at-point (search-term &optional refresh)
  "Google for term at point, and display top result succinctly.
Attach URL at point so we can follow it later --- subsequent invocations of this command simply follow that URL.
Optional interactive prefix arg `refresh' forces this cached URL to be refreshed."
  (interactive
   (list
    (unless(and (not current-prefix-arg)
                (get-text-property (point) 'lucky-url))
      (let ((word (thing-at-point 'word)))
        (completing-read
         "Google: "
         (when word 
           (gsearch-suggest word))
         nil nil  word nil)))
    current-prefix-arg))
  (cond
   ((and (not refresh)
         (get-text-property (point) 'lucky-url))
    (browse-url (get-text-property (point) 'lucky-url)))
   (t 
    (let ((lucky (aref (gsearch-results (g-url-encode search-term)) 0))
          (inhibit-read-only t)
          (bounds (bounds-of-thing-at-point 'word))
          (modified-p (buffer-modified-p)))
      (when bounds 
      (add-text-properties   (car bounds) (cdr bounds)
                             (list 'lucky-url
                                   (g-json-get "url" lucky)
                                   'face 'highlight
                                   'front-sticky nil
                                   'rear-sticky nil)))
      (set-buffer-modified-p modified-p)
      (message "%s %s"
               (g-json-get "titleNoFormatting" lucky)
               (g-json-get "content" lucky))))))



;;}}}



(provide 'gsearch)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
