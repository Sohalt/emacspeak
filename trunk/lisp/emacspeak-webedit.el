;;; emacspeak-webedit.el --- Transform Web Pages Using XSLT
;;; $Id: emacspeak-webmarks.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Edit/Transform Web Pages using XSLT
;;; Keywords: Emacspeak,  Audio Desktop Web, XSLT
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
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:

;;; Invoke XSLT to edit/transform Web pages before they get rendered.
;;; Code:

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'emacspeak-xslt)
(require 'emacspeak-webutils)

;;}}}
;;{{{ Helpers:

(defsubst emacspeak-webedit-read-url ()
  "Return URL of current page,
or URL read from minibuffer."
  (if (fboundp  emacspeak-webutils-current-url)
      (funcall emacspeak-webutils-current-url)
    (read-from-minibuffer "URL: "
                          (or (browse-url-url-at-point)
                              "http://"))))

;;}}}
;;{{{ applying XSL transforms before displaying

(define-prefix-command 'emacspeak-webedit-xsl-map )

(defvar emacspeak-webedit-xsl-filter
  (emacspeak-xslt-get "xpath-filter.xsl")
  "XSL to extract  elements matching a specified XPath locator.")


(defvar emacspeak-webedit-xsl-junk
  (emacspeak-xslt-get "xpath-junk.xsl")
  "XSL to junk  elements matching a specified XPath locator.")

;;;###autoload
(defcustom emacspeak-webedit-xsl-p nil
  "T means we apply XSL before displaying HTML."
  :type 'boolean
  :group 'emacspeak-webedit)

;;;###autoload
(defcustom emacspeak-w3-xsl-transform nil
  "Specifies transform to use before displaying a page.
Nil means no transform is used. "
  :type  '(choice
           (file :tag "XSL")
           (const :tag "none" nil))
  :group 'emacspeak-w3)

;;;###autoload
(defvar emacspeak-webedit-xsl-params nil
  "XSL params if any to pass to emacspeak-xslt-region.")

;;; Note that emacspeak-w3-xsl-transform, emacspeak-webedit-xsl-params
;;; and emacspeak-webedit-xsl-p
;;; need to be set at top-levle since the page-rendering code is
;;; called asynchronously.

;;;###autoload
(defcustom emacspeak-w3-cleanup-bogus-quotes t
  "Clean up bogus Unicode chars for magic quotes."
  :type 'boolean
  :group 'emacspeak-w3)

;;;###autoload
(defvar emacspeak-webutils-unescape-charent nil
  "Set to T to unescape charents.")

(defadvice  w3-parse-buffer (before emacspeak pre act comp)
  "Apply requested XSL transform if any before displaying the
HTML."
  (when emacspeak-w3-cleanup-bogus-quotes
    (goto-char (point-min))
    (while (search-forward "&\#147\;" nil t)
      (replace-match "\""))
    (goto-char (point-min))
    (while (search-forward "&\#148\;" nil t)
      (replace-match "\""))
    (goto-char (point-min))
    (while (search-forward "&\#180\;" nil t)
      (replace-match "\'")))
  (unless (string-match "temp"
                        (buffer-name))
  (emacspeak-w3-build-id-cache)
  (emacspeak-w3-build-class-cache))
  (when (and emacspeak-webedit-xsl-p
             emacspeak-w3-xsl-transform
             (not  (string-match "temp" (buffer-name))))
    (emacspeak-xslt-region
     emacspeak-w3-xsl-transform
     (point-min)
     (point-max)
     emacspeak-webedit-xsl-params)
    (when emacspeak-w3-xsl-keep-result
      (clone-buffer
       (format "__xslt-%s"
               (buffer-name))))))


;;;###autoload
(defun emacspeak-w3-xslt-apply (xsl)
  "Apply specified transformation to current page."
  (interactive
   (list
    (expand-file-name
     (read-file-name "XSL Transformation: "
                     emacspeak-xslt-directory))))
  (declare (special major-mode))
  (unless (eq major-mode 'w3-mode)
    (error "Not in a W3 buffer."))
  (let ((url (url-view-url t))
        (w3-reuse-buffers 'no))
    (emacspeak-webutils-with-xsl
     xsl
     (browse-url url))))

;;;###autoload
(defun emacspeak-w3-xslt-select (xsl)
  "Select XSL transformation applied to WWW pages before they are displayed ."
  (interactive
   (list
    (expand-file-name
     (read-file-name "XSL Transformation: "
                     emacspeak-xslt-directory))))
  (declare (special emacspeak-w3-xsl-transform))
  (setq emacspeak-w3-xsl-transform xsl)
  (message "Will apply %s before displaying HTML pages."
           (file-name-sans-extension
            (file-name-nondirectory xsl)))
  (emacspeak-auditory-icon 'select-object))

;;;###autoload
(defun emacspeak-w3-xsl-toggle ()
  "Toggle  application of XSL transformations.
This uses XSLT Processor xsltproc available as part of the
libxslt package."
  (interactive)
  (declare (special emacspeak-webedit-xsl-p))
  (setq emacspeak-webedit-xsl-p
        (not emacspeak-webedit-xsl-p))
  (emacspeak-auditory-icon
   (if emacspeak-webedit-xsl-p 'on 'off))
  (message "Turned %s XSL"
           (if emacspeak-webedit-xsl-p 'on 'off)))

;;;###autoload
(defun emacspeak-w3-count-matches (url locator)
  "Count matches for locator  in HTML."
  (interactive
   (list
    (if (eq major-mode 'w3-mode)
        (url-view-url 'no-show)
      (read-from-minibuffer "URL: "))
    (read-from-minibuffer "XPath locator: ")))
  (read
   (emacspeak-xslt-url
    (emacspeak-xslt-get "count-matches.xsl")
    url
    (list
     (cons "locator"
           (format "'%s'"
                   locator ))))))

;;;###autoload
(defun emacspeak-w3-count-nested-tables (url)
  "Count nested tables in HTML."
  (interactive
   (list
    (if (eq major-mode 'w3-mode)
        (url-view-url 'no-show)
      (read-from-minibuffer "URL: "))))
  (emacspeak-w3-count-matches url "'//table//table'" ))

;;;###autoload
(defun emacspeak-w3-count-tables (url)
  "Count  tables in HTML."
  (interactive
   (list
    (if (eq major-mode 'w3-mode)
        (url-view-url 'no-show)
      (read-from-minibuffer "URL: "))))
  (emacspeak-w3-count-matches url "//table"))

;;;###autoload
(defvar emacspeak-w3-xsl-keep-result nil
  "Toggle via command \\[emacspeak-w3-toggle-xsl-keep-result].")


;;;###autoload
(defun emacspeak-w3-toggle-xsl-keep-result ()
  "Toggle xsl keep result flag."
  (interactive)
  (declare (special emacspeak-w3-xsl-keep-result))
  (setq emacspeak-w3-xsl-keep-result
        (not emacspeak-w3-xsl-keep-result))
  (when (interactive-p)
    (emacspeak-auditory-icon
     (if emacspeak-w3-xsl-keep-result
         'on 'off))
    (message "Turned %s xslt keep results."
             (if emacspeak-w3-xsl-keep-result
                 'on 'off))))

;;;  Helper: rename result buffer
(defsubst emacspeak-w3-rename-buffer (key)
  "Setup emacspeak-w3-post-process-hook  to rename result buffer"
  (add-hook
   'emacspeak-w3-post-process-hook
   (eval
    `(function
      (lambda nil
        (rename-buffer
         (format "%s %s"
                 ,key (buffer-name))
         'unique))))))

;;;###autoload
(defun emacspeak-w3-xslt-filter (path    url  &optional speak)
  "Extract elements matching specified XPath path locator
from Web page -- default is the current page being viewed."
  (interactive
   (list
    (read-from-minibuffer "XPath: ")
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    current-prefix-arg))
  (declare (special emacspeak-w3-xsl-filter ))
  (let ((w3-reuse-buffers 'no)
        (params (emacspeak-xslt-params-from-xpath  path url)))
    (emacspeak-w3-rename-buffer (format "Filtered %s" path))
    (when speak
      (emacspeak-webutils-autospeak))
    (emacspeak-webutils-with-xsl-environment
     emacspeak-w3-xsl-filter
     params
     emacspeak-xslt-options ;options
     (browse-url url))))

;;;###autoload
(defun emacspeak-w3-xslt-junk (path    url &optional speak)
  "Junk elements matching specified locator."
  (interactive
   (list
    (read-from-minibuffer "XPath: ")
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    current-prefix-arg))
  (declare (special emacspeak-w3-xsl-junk ))
  (let ((w3-reuse-buffers 'no)
        (params (emacspeak-xslt-params-from-xpath  path url)))
    (emacspeak-w3-rename-buffer
     (format "Filtered %s" path))
    (when speak
      (add-hook 'emacspeak-w3-post-process-hook
                'emacspeak-speak-buffer))
    (emacspeak-webutils-with-xsl-environment
     emacspeak-w3-xsl-junk
     params
     emacspeak-xslt-options
     (browse-url url))))

;;;###autoload
(defcustom emacspeak-w3-media-stream-suffixes
  (list
   ".ram"
   ".rm"
   ".ra"
   ".pls"
   ".asf"
   ".asx"
   ".mp3"
   ".m3u"
   ".m4v"
   ".wma"
   ".wmv"
   ".avi"
   ".mpg")
  "Suffixes to look for in detecting URLs that point to media
streams."
  :type  '(repeat
           (string :tag "Extension Suffix"))
  :group 'emacspeak-w3)

;;;###autoload
(defun emacspeak-w3-extract-media-streams (url &optional speak)
  "Extract links to media streams.
operate on current web page when in a W3 buffer; otherwise prompt for url.
 Optional arg `speak' specifies if the result should be
spoken automatically."
  (interactive
   (list
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p) current-prefix-arg)))
  (declare (special emacspeak-w3-media-stream-suffixes))
  (let ((filter "//a[%s]")
        (predicate
         (mapconcat
          #'(lambda (suffix)
              (format "contains(@href,\"%s\")"
                      suffix))
          emacspeak-w3-media-stream-suffixes
          " or ")))
    (emacspeak-w3-xslt-filter
     (format filter predicate )
     url speak)))

;;;###autoload
(defun emacspeak-w3-extract-print-streams (url &optional speak)
  "Extract links to printable  streams.
operate on current web page when in a W3 buffer; otherwise prompt for url.
 Optional arg `speak' specifies if the result should be
spoken automatically."
  (interactive
   (list
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p) current-prefix-arg)))
  (let ((filter "//a[contains(@href,\"print\")]"))
    (emacspeak-w3-xslt-filter filter url speak)))

;;;###autoload
(defun emacspeak-w3-extract-media-streams-under-point ()
  "In W3 mode buffers, extract media streams from url under point."
  (interactive)
  (cond
   ((and (eq major-mode 'w3-mode)
         (w3-view-this-url 'no-show))
    (emacspeak-w3-extract-media-streams (w3-view-this-url 'no-show)
                                        'speak))
   (t (error "Not on a link in a W3 buffer."))))

;;;###autoload
(defun emacspeak-w3-extract-matching-urls (pattern url &optional speak)
  "Extracts links whose URL matches pattern."
  (interactive
   (list
    (read-from-minibuffer "Pattern: ")
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (let ((filter
         (format
          "//a[contains(@href,\"%s\")]"
          pattern)))
    (emacspeak-w3-xslt-filter
     filter
     url
     speak)))

;;;###autoload
(defun emacspeak-w3-extract-nested-table (index   url &optional speak)
  "Extract nested table specified by `table-index'. Default is to
operate on current web page when in a W3 buffer; otherwise
prompt for URL. Optional arg `speak' specifies if the result should be
spoken automatically."
  (interactive
   (list
    (read-from-minibuffer "Table Index: ")
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p) current-prefix-arg)))
  (emacspeak-w3-xslt-filter
   (format "(//table//table)[%s]" index)
   url
   speak))

(defsubst  emacspeak-w3-get-table-list (&optional bound)
  "Collect a list of numbers less than bound
 by prompting repeatedly in the
minibuffer.
Empty value finishes the list."
  (let ((result nil)
        (i nil)
        (done nil))
    (while (not done)
      (setq i
            (read-from-minibuffer
             (format "Index%s"
                     (if bound
                         (format " less than  %s" bound)
                       ":"))))
      (if (> (length i) 0)
          (push i result)
        (setq done t)))
    result))

(defsubst  emacspeak-w3-get-table-match-list ()
  "Collect a list of matches by prompting repeatedly in the
minibuffer.
Empty value finishes the list."
  (let ((result nil)
        (i nil)
        (done nil))
    (while (not done)
      (setq i
            (read-from-minibuffer "Match: "))
      (if (> (length i) 0)
          (push i result)
        (setq done t)))
    result))

;;;###autoload
(defun emacspeak-w3-extract-nested-table-list (tables url &optional speak)
  "Extract specified list of tables from a WWW page."
  (interactive
   (list
    (emacspeak-w3-get-table-list)
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (let ((filter
         (mapconcat
          #'(lambda  (i)
              (format "((//table//table)[%s])" i))
          tables
          " | ")))
    (emacspeak-w3-xslt-filter filter url speak)))

;;;###autoload
(defun emacspeak-w3-extract-table-by-position (position   url
                                                          &optional speak)
  "Extract table at specified position.
Default is to extract from current page."
  (interactive
   (list
    (read-from-minibuffer "Extract Table: ")
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (emacspeak-w3-xslt-filter
   (format "/descendant::table[%s]"
           position)
   url
   speak))

;;;###autoload
(defun emacspeak-w3-extract-tables-by-position-list (positions url &optional speak)
  "Extract specified list of nested tables from a WWW page.
Tables are specified by their position in the list
 of nested tables found in the page."
  (interactive
   (list
    (emacspeak-w3-get-table-list)
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (let ((filter
         (mapconcat
          #'(lambda  (i)
              (format "(/descendant::table[%s])" i))
          positions
          " | ")))
    (emacspeak-w3-xslt-filter
     filter
     url
     speak)))

;;;###autoload
(defun emacspeak-w3-extract-table-by-match (match   url &optional speak)
  "Extract table containing  specified match.
 Optional arg url specifies the page to extract content from."
  (interactive
   (list
    (read-from-minibuffer "Tables Matching: ")
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (emacspeak-w3-xslt-filter
   (format "(/descendant::table[contains(., \"%s\")])[last()]"
           match)
   url
   speak))

;;;###autoload
(defun emacspeak-w3-extract-tables-by-match-list (match-list
                                                  url &optional speak)
  "Extract specified  tables from a WWW page.
Tables are specified by containing  match pattern
 found in the match list."
  (interactive
   (list
    (emacspeak-w3-get-table-match-list)
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (let ((filter
         (mapconcat
          #'(lambda  (i)
              (format "((/descendant::table[contains(.,\"%s\")])[last()])" i))
          match-list
          " | ")))
    (emacspeak-w3-xslt-filter
     filter
     url
     speak)))

(defvar emacspeak-w3-buffer-class-cache nil
  "Caches class attribute values for current buffer.")

(make-variable-buffer-local 'emacspeak-w3-buffer-class-cache)

(defun emacspeak-w3-build-class-cache ()
  "Build class cache and forward it to rendered page."
  (let ((values nil)
        (content (clone-buffer
                  (format "__class-%s" (buffer-name)))))
    (save-excursion
      (set-buffer content)
      (setq buffer-undo-list t)
      (emacspeak-xslt-region
       (emacspeak-xslt-get "class-values.xsl")
       (point-min) (point-max)
       nil                              ;params
       'no-comment)
      (shell-command-on-region (point-min) (point-max)
                               "sort  -u"
                               (current-buffer))
      (setq values
            (split-string (buffer-string))))
    (add-hook
     'emacspeak-w3-post-process-hook
     (eval
      `(function
        (lambda nil
          (declare (special  emacspeak-w3-buffer-class-cache))
          (setq emacspeak-w3-buffer-class-cache
                ',(mapcar
                   #'(lambda (v)
                       (cons v v ))
                   values))))))))

(defvar emacspeak-w3-buffer-id-cache nil
  "Caches id attribute values for current buffer.")

(make-variable-buffer-local 'emacspeak-w3-buffer-id-cache)

(defun emacspeak-w3-build-id-cache ()
  "Build id cache and forward it to rendered page."
  (let ((values nil)
        (content (clone-buffer
                  (format "__id-%s" (buffer-name)))))
    (save-excursion
      (set-buffer content)
      (setq buffer-undo-list t)
      (emacspeak-xslt-region
       (emacspeak-xslt-get "id-values.xsl")
       (point-min) (point-max)
       nil ;params
       'no-comment)
      (setq values
            (split-string (buffer-string))))
    (add-hook
     'emacspeak-w3-post-process-hook
     (eval
      `(function
        (lambda nil
          (declare (special  emacspeak-w3-buffer-id-cache))
          (setq emacspeak-w3-buffer-id-cache
                ',(mapcar
                  #'(lambda (v)
                      (cons v v ))
                  values))))))))

;;;###autoload
(defun emacspeak-w3-extract-by-class (class    url &optional speak)
  "Extract elements having specified class attribute from HTML. Extracts
specified elements from current WWW page and displays it in a separate
buffer. Interactive use provides list of class values as completion."
  (interactive
   (list
    (completing-read "Class: "
                     emacspeak-w3-buffer-class-cache)
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p) current-prefix-arg)))
  (let ((filter (format "//*[@class=\"%s\"]" class)))
    (message "filter:%s" filter)
    (emacspeak-w3-xslt-filter filter
                              url
                              'speak)))

(defsubst  emacspeak-w3-get-id-list ()
  "Collect a list of ids by prompting repeatedly in the
minibuffer.
Empty value finishes the list."
  (let ((ids (emacspeak-w3-id-cache))
        (result nil)
        (c nil)
        (done nil))
    (while (not done)
      (setq c
            (completing-read "Id: "
                             ids
                             nil 'must-match))
      (if (> (length c) 0)
          (push c result)
        (setq done t)))
    result))

(defsubst  emacspeak-w3-css-get-class-list ()
  "Collect a list of classes by prompting repeatedly in the
minibuffer.
Empty value finishes the list."
  (let ((classes (emacspeak-w3-css-class-cache))
        (result nil)
        (c nil)
        (done nil))
    (while (not done)
      (setq c
            (completing-read "Class: "
                             classes
                             nil 'must-match))
      (if (> (length c) 0)
          (push c result)
        (setq done t)))
    result))

;;;###autoload
(defun emacspeak-w3-extract-by-class-list(classes   url &optional
                                                    speak)
  "Extract elements having class specified in list `classes' from HTML.
Extracts specified elements from current WWW page and displays it
in a separate buffer.  Interactive use provides list of class
values as completion. "
  (interactive
   (list
    (emacspeak-w3-css-get-class-list)
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (let ((filter
         (mapconcat
          #'(lambda  (c)
              (format "(@class=\"%s\")" c))
          classes
          " or ")))
    (emacspeak-w3-xslt-filter
     (format "//*[%s]" filter)
     url
     (or (interactive-p) speak))))

;;;###autoload
(defun emacspeak-w3-extract-by-id (id   url &optional speak)
  "Extract elements having specified id attribute from HTML. Extracts
specified elements from current WWW page and displays it in a separate
buffer.
Interactive use provides list of id values as completion."
  (interactive
   (list
    (completing-read "Id: "
                     emacspeak-w3-buffer-id-cache)
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (emacspeak-w3-xslt-filter
   (format "//*[@id=\"%s\"]"
           id)
   url
   speak))

;;;###autoload
(defun emacspeak-w3-extract-by-id-list(ids   url &optional speak)
  "Extract elements having id specified in list `ids' from HTML.
Extracts specified elements from current WWW page and displays it in a
separate buffer. Interactive use provides list of id values as completion. "
  (interactive
   (list
    (emacspeak-w3-get-id-list)
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (let ((filter
         (mapconcat
          #'(lambda  (c)
              (format "(@id=\"%s\")" c))
          ids
          " or ")))
    (emacspeak-w3-xslt-filter
     (format "//*[%s]" filter)
     url
     speak)))

;;;###autoload
(defun emacspeak-w3-junk-by-class-list(classes   url &optional speak)
  "Junk elements having class specified in list `classes' from HTML.
Extracts specified elements from current WWW page and displays it in a
separate buffer.
 Interactive use provides list of class values as
completion. "
  (interactive
   (list
    (emacspeak-w3-css-get-class-list)
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (let ((filter
         (mapconcat
          #'(lambda  (c)
              (format "(@class=\"%s\")" c))
          classes
          " or ")))
    (emacspeak-w3-xslt-junk
     (format "//*[%s]" filter)
     url
     speak)))

(defvar emacspeak-w3-class-filter nil
  "Buffer local class filter.")

(make-variable-buffer-local 'emacspeak-w3-class-filter)

;;;###autoload
(defun emacspeak-w3-class-filter-and-follow (class url)
  "Follow url and point, and filter the result by specified class.
Class can be set locally for a buffer, and overridden with an
interactive prefix arg. If there is a known rewrite url rule, that is
used as well."
  (interactive
   (list
    (or emacspeak-w3-class-filter
        (setq emacspeak-w3-class-filter
              (read-from-minibuffer "Class: ")))
    (if (eq major-mode 'w3-mode)
        (w3-view-this-url t)
      (read-from-minibuffer "URL: "))))
  (declare (special emacspeak-w3-class-filter
                    emacspeak-w3-url-rewrite-rule))
  (let ((redirect nil))
    (when emacspeak-w3-url-rewrite-rule
      (setq redirect
            (replace-regexp-in-string
             (first emacspeak-w3-url-rewrite-rule)
             (second emacspeak-w3-url-rewrite-rule)
             url)))
    (emacspeak-w3-extract-by-class
     emacspeak-w3-class-filter
     (or redirect url)
     'speak)
    (emacspeak-auditory-icon 'open-object)))


(defvar emacspeak-w3-id-filter nil
  "Buffer local id filter.")

(make-variable-buffer-local 'emacspeak-w3-id-filter)


;;;###autoload
(defun emacspeak-w3-follow-and-filter-by-id (id)
  "Follow url and point, and filter the result by specified id.
Id can be set locally for a buffer, and overridden with an
interactive prefix arg. If there is a known rewrite url rule, that is
used as well."
  (interactive
   (list
    (or emacspeak-w3-id-filter
        (setq emacspeak-w3-id-filter
              (read-from-minibuffer "Id: ")))))
  (declare (special emacspeak-w3-id-filter
                    emacspeak-w3-url-rewrite-rule))
  (unless (eq major-mode 'w3-mode)
    (error "This command is only useful in W3 buffers."))
  (let ((url (w3-view-this-url t))
        (redirect nil))
    (unless url
      (error "Not on a link."))
    (when emacspeak-w3-url-rewrite-rule
      (setq redirect
            (replace-regexp-in-string
             (first emacspeak-w3-url-rewrite-rule)
             (second emacspeak-w3-url-rewrite-rule)
             url)))
    (emacspeak-w3-extract-by-id
     emacspeak-w3-id-filter
     (or redirect url)
     'speak)))

;;;###autoload
(defun emacspeak-w3-style-filter (style   url &optional speak )
  "Extract elements matching specified style
from HTML.  Extracts specified elements from current WWW
page and displays it in a separate buffer.  Optional arg url
specifies the page to extract contents  from."
  (interactive
   (list
    (read-from-minibuffer "Style: ")
    (if (eq major-mode 'w3-mode)
        (url-view-url t)
      (read-from-minibuffer "URL: " "http://www."))
    (or (interactive-p)
        current-prefix-arg)))
  (emacspeak-w3-xslt-filter
   (format "//*[contains(@style,  \"%s\")]" style)
   url speak))

;;}}}
;;{{{ xpath  filter

(defvar emacspeak-w3-xpath-filter nil
  "Buffer local variable specifying a XPath filter for following
urls.")

(make-variable-buffer-local 'emacspeak-w3-xpath-filter)
(defcustom emacspeak-w3-most-recent-xpath-filter
  "//p|ol|ul|dl|h1|h2|h3|h4|h5|h6|blockquote|div"
  "Caches most recently used xpath filter.
Can be customized to set up initial default."
  :type 'string
  :group 'emacspeak-w3)

;;;###autoload
(defun emacspeak-w3-xpath-filter-and-follow (&optional prompt)
  "Follow url and point, and filter the result by specified xpath.
XPath can be set locally for a buffer, and overridden with an
interactive prefix arg. If there is a known rewrite url rule, that is
used as well."
  (interactive "P")
  (declare (special emacspeak-w3-xpath-filter
                    emacspeak-w3-most-recent-xpath-filter
                    emacspeak-w3-url-rewrite-rule))
  (unless (eq major-mode 'w3-mode)
    (error "This command is only useful in W3 buffers."))
  (let ((url (w3-view-this-url t))
        (redirect nil))
    (unless url (error "Not on a link."))
    (when emacspeak-w3-url-rewrite-rule
      (setq redirect
            (replace-regexp-in-string
             (first emacspeak-w3-url-rewrite-rule)
             (second emacspeak-w3-url-rewrite-rule)
             url)))
    (when (or prompt (null emacspeak-w3-xpath-filter))
      (setq emacspeak-w3-xpath-filter
            (read-from-minibuffer  "Specify XPath: "
                                   emacspeak-w3-most-recent-xpath-filter))
      (setq emacspeak-w3-most-recent-xpath-filter
            emacspeak-w3-xpath-filter))
    (emacspeak-w3-xslt-filter emacspeak-w3-xpath-filter
                              (or redirect url)
                              'speak)))

(defvar emacspeak-w3-xpath-junk nil
  "Records XPath pattern used to junk elements.")

(make-variable-buffer-local 'emacspeak-w3-xpath-junk)

(defvar emacspeak-w3-most-recent-xpath-junk
  nil
  "Caches last XPath used to junk elements.")
;;;###autoload
(defun emacspeak-w3-xpath-junk-and-follow (&optional prompt)
  "Follow url and point, and filter the result by junking
elements specified by xpath.
XPath can be set locally for a buffer, and overridden with an
interactive prefix arg. If there is a known rewrite url rule, that is
used as well."
  (interactive "P")
  (declare (special emacspeak-w3-xpath-junk
                    emacspeak-w3-xsl-junk
                    emacspeak-w3-most-recent-xpath-junk
                    emacspeak-w3-url-rewrite-rule))
  (unless (eq major-mode 'w3-mode)
    (error "This command is only useful in W3 buffers."))
  (let ((url (w3-view-this-url t))
        (redirect nil))
    (unless url
      (error "Not on a link."))
    (when emacspeak-w3-url-rewrite-rule
      (setq redirect
            (replace-regexp-in-string
             (first emacspeak-w3-url-rewrite-rule)
             (second emacspeak-w3-url-rewrite-rule)
             url)))
    (when (or prompt
              (null emacspeak-w3-xpath-junk))
      (setq emacspeak-w3-xpath-junk
            (read-from-minibuffer  "Specify XPath: "
                                   emacspeak-w3-most-recent-xpath-junk))
      (setq emacspeak-w3-most-recent-xpath-junk
            emacspeak-w3-xpath-junk))
    (emacspeak-w3-xslt-junk
     emacspeak-w3-xpath-junk
     (or redirect url)
     'speak)))

;;}}}
;;{{{  xsl keymap

(declaim (special emacspeak-w3-xsl-map))

(loop for binding in
      '(
        ("C" emacspeak-w3-extract-by-class-list)
        ("M" emacspeak-w3-extract-tables-by-match-list)
        ("P" emacspeak-w3-extract-print-streams)
        ("R" emacspeak-w3-extract-media-streams-under-point)
        ("T" emacspeak-w3-extract-tables-by-position-list)
        ("X" emacspeak-w3-extract-nested-table-list)
        ("\C-c" emacspeak-w3-junk-by-class-list)
        ("\C-f" emacspeak-w3-count-matches)
        ("\C-p" emacspeak-w3-xpath-junk-and-follow)
        ("\C-t" emacspeak-w3-count-tables)
        ("\C-x" emacspeak-w3-count-nested-tables)
        ("a" emacspeak-w3-xslt-apply)
        ("c" emacspeak-w3-extract-by-class)
        ("e" emacspeak-w3-url-expand-and-execute)
        ("f" emacspeak-w3-xslt-filter)
        ("i" emacspeak-w3-extract-by-id)
        ("I" emacspeak-w3-extract-by-id-list)
        ("j" emacspeak-w3-xslt-junk)
        ("k" emacspeak-w3-set-xsl-keep-result)
        ("m" emacspeak-w3-extract-table-by-match)
        ("o" emacspeak-w3-xsl-toggle)
        ("p" emacspeak-w3-xpath-filter-and-follow)
        ("r" emacspeak-w3-extract-media-streams)
        ("S" emacspeak-w3-style-filter)
        ("s" emacspeak-w3-xslt-select)
        ("t" emacspeak-w3-extract-table-by-position)
        ("u" emacspeak-w3-extract-matching-urls)
        ("x" emacspeak-w3-extract-nested-table)
        ("b" emacspeak-w3-follow-and-filter-by-id)
        ("y" emacspeak-w3-class-filter-and-follow)
        )
      do
      (emacspeak-keymap-update emacspeak-w3-xsl-map binding))

;;}}}
(provide 'emacspeak-webedit)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
