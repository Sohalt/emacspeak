(augment-load-path "emacs-jabber")
(load-library "jabber")
(load-library "ssl")
(load-library "nm")
(add-hook 'nm-connected-hook 'jabber-connect-all)
(add-hook 'nm-disconnected-hook 'jabber-disconnect)
(nm-enable)






