;;; gblogger.el ---  new Atom Blogger API client
;;; $Id:$
;;; $Author:$
;;; Description:  ATOM Blogger API
;;; Keywords: g-client, Blogger Atom API
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; g-client| T. V. Raman |raman@cs.cornell.edu
;;; An emacs interface to Google services|
;;; $Date: 2006-09-28 09:37:06 -0700 (Thu, 28 Sep 2006) $ |
;;;  $Revision$ |
;;; Location undetermined
;;; License: GPL
;;;

;;}}}
;;{{{ Copyright:

;;; Copyright (c) 2005--2006, Google Inc.
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

;;; Simple wrapper using Curl to post/edit Blogger.com Blogs
;;; posts are edited as XML
;;;nxml-mode is highly recommend and will be used if available.

;;;Usage:
;;; gblogger-blog -- Show feed of current user's blogs
;;; gblogger-new-entry -- Create a new post
;;; gblogger-edit-entry -- Edit previously posted entry
;;; gblogger-delete-entry -- Delete previously posted entry

;;; Commands prompt for the URI of the entry being manipulated ---
;;; this is the service.edit URI.
;;; You can customize things via custom.

;;}}}
;;{{{  Required modules

(require 'cl)
(require 'derived)
(require 'g-utils)
(require 'g-auth)
(require 'g-app)

;;}}}
;;{{{ customizations

(defgroup gblogger nil
  "Emacs client for posting to blogger."
  :group 'g)

(defcustom gblogger-user-email nil
  "Mail address that identifies blogger user."
  :type '(choice
          (const :tag "none" nil)
          (string :tag "username@gmail.com" ""))
  :group 'gblogger)

(defcustom gblogger-user-password nil
  "Password for authenticating to reader account."
  :type '(radio (const :tag "Prompt for password" nil)
                (string :tag "Save password in .emacs"))
  :group 'gblogger)

(defcustom gblogger-author (user-full-name)
  "Author name under which we post."
  :type 'string
  :group 'gblogger)

(defvar gblogger-generator-name "http://purl.org/net/emacs-gblogger/"
  "Name of this generator.")

(defvar gblogger-publish-action nil
  "This is set up by the various interactive comands to trigger
  the appropriate action when one is ready to publish.")

(defvar gblogger-new-entry-template
  "<entry xmlns='http://www.w3.org/2005/Atom'>
  <generator url=\"%s\">%s</generator>
  <author> <name>%s </name> </author>
  <title mode=\"escaped\" type=\"text/html\">%s </title>
  <content type='xhtml'>
    <div xmlns=\"http://www.w3.org/1999/xhtml\">
<!--content goes here -->
    </div>
  </content>
</entry>"
  "Template for new Blogger entries.")

;;}}}
;;{{{ constants:

(defconst gblogger-service-name "blogger"
  "Service name for accessing  Blogger.")

(defconst gblogger-base-url
  "http://www.blogger.com/feeds/default/blogs"
  "Base url for blogger access.")

(defsubst gblogger-p (service)
  "Check if this is blogger."
  (declare (special gblogger-service-name))
  (string-equal service gblogger-service-name))

;;}}}
;;{{{  blogger Authenticate

(defsubst make-gblogger-auth ()
  "Make a new gblogger auth handle."
  (declare (special gblogger-service-name
                    gblogger-user-email gblogger-user-password))
  (make-g-auth :service gblogger-service-name
               :email gblogger-user-email
               :password gblogger-user-password))
(defvar gblogger-auth-handle
  (make-gblogger-auth)
  "Gblogger auth handle.
Holds user's email address, password, and the auth token received
from the server.")

;;}}}
;;{{{ Interactive Commands:

;;;###autoload
(defun gblogger-blog ()
  "Retrieve and display feed of feeds after authenticating."
  (interactive)
  (declare (special gblogger-auth-handle))
  (g-app-view gblogger-auth-handle gblogger-base-url))

;;;###autoload
(defun gblogger-atom-display (url)
  "Retrieve and display specified feed after authenticating."
  (interactive
   (list
    (read-from-minibuffer "Feed: "
                          (browse-url-url-at-point))))
  (declare (special gblogger-auth-handle
                    g-atom-view-xsl
                    g-curl-program g-curl-common-options
                    g-cookie-options))
  (g-auth-ensure-token gblogger-auth-handle)
  (g-display-result
   (format
    "%s %s %s --location --header 'Authorization: GoogleLogin auth=%s' '%s' 2>/dev/null"
    g-curl-program g-curl-common-options g-cookie-options
    (g-cookie "Auth" gblogger-auth-handle)
    url)
   g-atom-view-xsl))

(defun gblogger-get-entry (url)
  "Retrieve specified entry.
`url' is the URL of the entry"
  (declare (special gblogger-auth-handle))
  (save-excursion
    (set-buffer  (g-app-get-entry gblogger-auth-handle url))
    (goto-char (point-min))
    (search-forward "<content" )
    (search-backward "<content")
    (mark-sexp)
    (g-html-unescape-region (point) (mark))
    (current-buffer)))

;;;###autoload
(defun gblogger-edit-entry (url)
  "Retrieve entry and prepare it for editting.
The retrieved entry is placed in a buffer ready for editing.
`url' is the URL of the entry."
  (interactive
   (list
    (read-from-minibuffer "Entry URL:")))
  (declare (special gblogger-auth-handle))
  (save-excursion
    (set-buffer (g-app-get-entry gblogger-auth-handle  url))
    (setq g-app-publish-action 'g-app-put-entry)
    (g-xsl-transform-region (point-min) (point-max)
                            g-atom-edit-filter))
  (goto-char (point-min))
  (flush-lines "^ *$")
  (goto-char (point-min))
  (search-forward "<content" nil t)
  (forward-line 1)
  (message
   (substitute-command-keys "Use \\[gblogger-publish] to publish your edits .")))

;;;###autoload
(defun gblogger-new-entry (url)
  "Create a new Blog post."
  (interactive
   (list
    (read-from-minibuffer "Post URL:")))
  (declare (special gblogger-auth-handle gblogger-new-entry-template
                    gblogger-generator-name gblogger-publish-action))
  (g-auth-ensure-token gblogger-auth-handle)
  (let* ((title (read-string "Title: "))
         (buffer (get-buffer-create title)))
    (save-excursion
      (set-buffer buffer)
      (erase-buffer)
      (g-app-mode)
      (setq g-app-this-url url
            g-app-auth-handle gblogger-auth-handle
            g-app-publish-action 'g-app-post-entry)      (goto-char (point-max))
      (insert
       (format gblogger-new-entry-template
               gblogger-generator-name gblogger-generator-name
               gblogger-author title)))
    (switch-to-buffer buffer)
    (search-backward "<div" nil t)
    (forward-line 1)
    (message
     (substitute-command-keys
      "Use \\[g-app-publish] to publish your edits ."))))

;;;###autoload
(defun gblogger-post-entry ()
  "Post buffer contents  as  updated entry."
  (interactive)
  (g-app-send-buffer "POST"))

;;;###autoload
(defun gblogger-publish ()
  "Publish current entry."
  (interactive)
  (declare (special gblogger-this-url gblogger-auth-handle
                    gblogger-publish-action))
  (unless (and (eq major-mode 'g-app-mode)
               gblogger-publish-action
               (commandp gblogger-publish-action)
               gblogger-this-url)
    (error "Not in a correctly initialized Atom Entry."))
  (call-interactively gblogger-publish-action)
  (message "Publishing  to %s" gblogger-this-url))

;;;### autoload
(defun gblogger-delete-entry (url)
  "Delete specified entry."
  (interactive
   (list
    (read-from-minibuffer "Entry URL:")))
  (declare (special gblogger-auth-handle))
  (g-auth-ensure-token gblogger-auth-handle)
  (shell-command
   (format "%s %s %s -X DELETE %s %s"
           g-curl-program g-curl-common-options
           (g-authorization gblogger-auth-handle)
           url
           (g-curl-debug))))

;;}}}
;;{{{ Reset auth handle:
;;;###autoload
(defun gblogger-sign-out()
  "Resets client so you can start with a different userid."
  (interactive)
  (declare (special gblogger-auth-handle
                    gblogger-user-email gblogger-user-password))
  (message "Signing out %s from blogger"
           (g-auth-email gblogger-auth-handle))
  (setq gblogger-user-email nil
        gblogger-user-password nil)
  (setq gblogger-auth-handle (make-gblogger-auth)))
;;;###autoload
(defun gblogger-sign-in()
  "Resets client so you can start with a different userid."
  (interactive)
  (declare (special gblogger-auth-handle gblogger-user-email ))
  (setq gblogger-user-email
        (read-from-minibuffer "User Email:"))
  (setq gblogger-auth-handle (make-gblogger-auth))
  (g-authenticate gblogger-auth-handle))

;;}}}
(provide 'gblogger)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
