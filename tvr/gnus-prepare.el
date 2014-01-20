;;;  Gnus Setup For GMail imap:
;;{{{  News Source etc 
;;; Example: http://www.google.com/url?q=http://blogs.openaether.org/data/gnus.example.el&sa=U&ei=R1DdUuLMCYiDogTV0YHYDg&ved=0CCkQFjAC&usg=AFQjCNF4T3kHZQ8CDmpFbzJeJcXbdTYOXw
(setq
 gnus-gmail-plain-method 
 '(nnimap "gmail"
          (nnimap-address "imap.gmail.com")
          (nnimap-server-port 993)
          (nnimap-stream ssl)))

(setq gnus-select-method gnus-gmail-plain-method)

;;; split out mailing lists:
;;; Mail split per Info manual:

(setq nnimap-inbox "[Gmail]/Important")

(setq nnimap-split-methods 'gnus-group-split  )
(setq nnmail-split-methods 'gnus-group-split)
(gnus-group-split-setup 'AUTO-UPDATE 'CATCH-ALL)

(setq
 message-send-mail-function 'smtpmail-send-it
 smtpmail-starttls-credentials '(("smtp.gmail.com" 587 nil nil))
 smtpmail-auth-credentials '(("smtp.gmail.com" 587 user-mail-address nil))
 smtpmail-default-smtp-server "smtp.gmail.com"
 smtpmail-smtp-server "smtp.gmail.com"
 smtpmail-smtp-service 587)
(setq
 gnus-ignored-newsgroups "^to\\.\\|^[0-9. ]+\\( \\|$\\)\\|^[\"]\"[#'()]")
(setq gnus-agent nil)

;;}}}
;;{{{  gnus mode hooks 

(add-hook
 'gnus-summary-mode-hook
 #'(lambda ()
     (define-key gnus-summary-mode-map "\C-t" 'gnus-summary-toggle-header)
     (define-key gnus-summary-mode-map "\M-h" 'gnus-summary-hide-all-threads)
     (define-key gnus-summary-mode-map "T" 'gnus-summary-hide-all-headers )
     (define-key gnus-summary-mode-map "t" 'gnus-summary-show-some-headers)
     (define-key gnus-summary-mode-map '[left] 'gnus-summary-catchup-and-exit)
     (define-key gnus-summary-mode-map '[right] 'gnus-summary-show-article)))

(add-hook
 'gnus-select-group-hook
 #'(lambda ()
             (gnus-summary-hide-all-threads)))

(add-hook
 'gnus-group-mode-hook
 #'(lambda ()
     (define-key gnus-group-mode-map '[right] 'gnus-group-read-group)))

;;}}}
;(setq gnus-summary-line-format "%t%U%R%-20,20a %s \n")
;(setq gnus-group-line-format "%M%S%p%P%5y: %(%G%)%l \n")
