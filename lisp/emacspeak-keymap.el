;;; emacspeak-keymap.el --- Setup  keymaps and keybindings provided by Emacspeak
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description:  Module for setting up emacspeak keybindings
;;; Keywords: Emacspeak
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2008-06-21 10:50:41 -0700 (Sat, 21 Jun 2008) $ |
;;;  $Revision: 4544 $ |
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
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;{{{  Introduction:

;;;Commentary:

;;; This module defines the emacspeak keybindings.

;;; Code:

;;}}}
;;{{{ requires

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'wid-edit)

;;}}}
;;{{{ Custom Widget Types:

;;;###autoload
(defun emacspeak-keymap-command-p (s)
  "Check if `s' is suitable to be bound to a key."
  (or (commandp s) (keymapp s)))

;;;###autoload
(defun emacspeak-keymap-update (keymap binding)
  "Update keymap with specified binding."
  (define-key keymap  (kbd (first binding)) (second binding)))

(defun emacspeak-keymap-bindings-update (keymap bindings)
  "Update keymap with specified list of bindings."
  (loop
   for binding in bindings
   do
   (define-key keymap (kbd (car binding)) (cdr binding))))

(define-widget 'ems-interactive-command 'restricted-sexp
  "An interactive command."
  :completions
  (apply-partially #'completion-table-with-predicate
                   obarray 'emacspeak-keymap-command-p 'strict)
  :prompt-value 'widget-field-prompt-value
  :prompt-internal 'widget-symbol-prompt-internal
  :prompt-match 'emacspeak-keymap-command-p
  :prompt-history 'widget-function-prompt-value-history
  :action 'widget-field-action
  :match-alternatives '(emacspeak-keymap-command-p)
  :validate (lambda (widget)
              (unless (emacspeak-keymap-command-p (widget-value widget))
                (widget-put widget :error
                            (format "Invalid interactive command : %S"
                                    (widget-value widget)))
                widget))
  :value 'ignore
  :tag "Interactive Command")

;;;###autoload

;;}}}
;;{{{  variables:

(defvar emacspeak-prefix (kbd "C-e")
  "Default prefix key used for emacspeak. ")
;;;###autoload
(defvar emacspeak-keymap nil
  "Primary keymap used by emacspeak. ")

(defvar emacspeak-dtk-submap nil
  "Submap used for DTK commands. ")

;;}}}
;;{{{   Binding keymap and submap

(define-prefix-command 'emacspeak-prefix-command 'emacspeak-keymap )

(define-prefix-command  'emacspeak-dtk-submap-command
  'emacspeak-dtk-submap )
(global-set-key emacspeak-prefix 'emacspeak-prefix-command)

(define-key emacspeak-keymap "d"  'emacspeak-dtk-submap-command)

;;; fix what we just broke:-
(define-key emacspeak-keymap "e" 'end-of-line)
(define-key emacspeak-keymap (kbd "C-e") 'end-of-line)

;;}}}
;;{{{  The Emacspeak key  bindings.

;;; help map additions:

(loop for binding in
      '(
        ( "B" customize-browse)
        ( "G" customize-group)
        ( "M" emacspeak-speak-popup-messages)
        ( "M-F" find-function-at-point)
        ( "M-V" find-variable-at-point)
        ( "M-f" find-function)
        ( "M-k" find-function-on-key)
        ( "M-v" find-variable)
        ( "V" customize-variable)
        ("C-e"   emacspeak-describe-emacspeak)
        ("C-l" emacspeak-learn-emacs-mode)
        ("C-m" man)
        ("C-s" customize-saved)
        ("C-r" info-display-manual)
        ("SPC" customize-group)
        ("TAB" emacspeak-info-wizard)
        )
      do
      (emacspeak-keymap-update help-map binding))

;;; emacspeak-keymap bindings:
(loop for binding in
      '(
        (  "C-a" emacspeak-toggle-auditory-icons )
        ( "M-f" emacspeak-frame-label-or-switch-to-labelled-frame )
        ("!" emacspeak-speak-run-shell-command)
        ("#" emacspeak-gridtext)
        ("%" emacspeak-speak-current-percentage)
        ("&" emacspeak-wizards-shell-command-on-current-file)
        ("'" emacspeak-pianobar )
        ("(" emacspeak-audio-setup)
        (")" emacspeak-sounds-select-theme)
        ("," emacspeak-speak-browse-buffer )
        ("." emacspeak-speak-current-field)
        ("/" emacspeak-speak-this-buffer-other-window-display)
        (":" emacspeak-m-player-shuffle)
        (";" emacspeak-multimedia)
        ("<" emacspeak-speak-previous-field)
        ("<(deletechar>" emacspeak-ssh-tts-restart)
        ("<C-<left>" emacspeak-select-this-buffer-previous-display)
        ("<C-<right>" emacspeak-select-this-buffer-next-display)
        ("<delete>" emacspeak-ssh-tts-restart)
        ("<down>" emacspeak-read-next-line)
        ("<f11>" emacspeak-wizards-shell-toggle)
        ("<f1>" emacspeak-learn-emacs-mode)
        ("<insert>" emacspeak-emergency-tts-restart)
        ("<left>" emacspeak-speak-this-buffer-previous-display)
        ("<right>" emacspeak-speak-this-buffer-next-display)
        ("<up>"  emacspeak-read-previous-line)
        ("=" emacspeak-speak-current-column)
        (">"  emacspeak-speak-next-field)
        ("?" emacspeak-websearch-dispatch )
        ("@" emacspeak-speak-message-at-time)
        ("A" emacspeak-appt-repeat-announcement)
        ("B" emacspeak-speak-buffer-interactively)
        ("C" emacspeak-customize)
        ("C-@" emacspeak-speak-current-mark )
        ("C-b" emacspeak-bookshare)
        ("C-c" emacspeak-clipboard-copy)
        ("C-d" emacspeak-toggle-show-point)
        ("C-i" emacspeak-table-display-table-in-region)
        ("C-j" emacspeak-hide-speak-block-sans-prefix)
        ("C-l" emacspeak-speak-line-number)
        ("C-m"  emacspeak-speak-continuously)
        ("C-n" emacspeak-speak-next-window )
        ("C-o" emacspeak-ocr )
        ("C-p" emacspeak-speak-previous-window)
        ("C-q" emacspeak-toggle-comint-autospeak)
        ("C-s" tts-restart )
        ("C-t" emacspeak-table-find-file)
        ("C-u" emacspeak-feeds-browse)
        ("C-v" view-mode)
        ("C-w" emacspeak-speak-window-information)
        ("C-y" emacspeak-clipboard-paste)
        ("DEL" cd-tool)
        ("F" emacspeak-view-emacspeak-faq)
        ("I"  emacspeak-speak-show-active-network-interfaces)
        ("L" emacspeak-speak-line-interactively)
        ("M" emacspeak-speak-minor-mode-line)
        ("M-%" emacspeak-goto-percent)
        ("M-;" emacspeak-webutils-play-media-at-point )
        ("M-C-@" emacspeak-speak-spaces-at-point)
        ("M-C-b" emacspeak-submit-bug )
        ("M-C-k" kill-emacs)
        ("M-a" emacspeak-set-auditory-icon-player)
        ("M-b" emacspeak-speak-other-buffer)
        ("M-c" emacspeak-copy-current-file)
        ("M-d" emacspeak-pronounce-dispatch)
        ("M-h" emacspeak-speak-hostname)
        ("M-l" emacspeak-link-current-file)
        ("M-m" emacspeak-toggle-mail-alert)
        ("M-q" voice-setup-toggle-silence-personality)
        ("M-r" emacspeak-remote-connect-to-server)
        ("M-s" emacspeak-symlink-current-file)
        ("M-t" emacspeak-tapestry-describe-tapestry)
        ("M-u" emacspeak-feeds-add-feed)
        ("M-v" emacspeak-show-personality-at-point)
        ("M-w" emacspeak-toggle-which-function)
        ("N" emacspeak-view-emacspeak-news)
        ("P" emacspeak-speak-paragraph-interactively)
        ("R" emacspeak-speak-rectangle)
        ("SPC" emacspeak-speak-header-line)
        ("T" emacspeak-view-emacspeak-tips )
        ("U" emacspeak-websearch-usenet)
        ("V" emacspeak-speak-version)
        ("W" emacspeak-tapestry-select-window-by-name)
        ("[" emacspeak-speak-page)
        ("\"" emacspeak-speak-sexp-interactively)
        ("\\" emacspeak-toggle-speak-line-invert-filter)
        ("]" emacspeak-speak-page-interactively)
        ("^" emacspeak-filtertext)
        ("a" emacspeak-speak-message-again )
        ("b" emacspeak-speak-buffer)
        ("c" emacspeak-speak-char)
        ("f" emacspeak-speak-buffer-filename )
        ("g" emacspeak-epub)
        ("h" emacspeak-speak-help)
        ("i" emacspeak-tabulate-region)
        ("j" emacspeak-hide-or-expose-block)
        ("k" emacspeak-speak-current-kill )
        ("l" emacspeak-speak-line)
        ("m" emacspeak-speak-mode-line)
        ("n" emacspeak-speak-rest-of-buffer)
        ("o" emacspeak-toggle-comint-output-monitor)
        ("p" emacspeak-speak-paragraph)
        ("q" emacspeak-toggle-speak-messages)
        ("r" emacspeak-speak-region)
        ("s" dtk-stop)
        ("t" emacspeak-speak-time )
        ("u" emacspeak-url-template-fetch)
        ("v" view-register)
        ("w" emacspeak-speak-word)
        ("{" emacspeak-speak-paragraph)
        ("|" emacspeak-speak-line-set-column-filter)
        )
      do
      (emacspeak-keymap-update emacspeak-keymap binding))

(dotimes (i 10)
  (define-key emacspeak-keymap   (format "%s" i )
    'emacspeak-speak-predefined-window ))

(loop for binding in
      '(
        ("," dtk-toggle-punctuation-mode)
        ("A" dtk-async-server)
        ("C" dtk-toggle-allcaps-beep)
        ("L" dtk-local-server)
        ("M-C-b" tts-show-debug-buffer)
        ("N" dtk-set-next-language)
        ("P" dtk-set-previous-language)
        ("R" dtk-reset-state)
        ("S" dtk-set-language)
        ("SPC" dtk-toggle-splitting-on-white-space)
        ("V" tts-speak-version)
        ("\C-d" dectalk)
        ("\C-e" espeak)
        ("\C-m" dtk-set-chunk-separator-syntax)
        ("\C-o" outloud)
        ("\C-v" outloud-32)
        ("a" dtk-add-cleanup-pattern)
        ("b" dtk-toggle-debug)
        ("c" dtk-toggle-capitalization)
        ("d" dtk-select-server)
        ("f" dtk-set-character-scale)
        ("i" emacspeak-toggle-audio-indentation )
        ("k" emacspeak-toggle-character-echo)
        ("l" emacspeak-toggle-line-echo)
        ("m"emacspeak-speak-set-mode-punctuations)
        ("n" dtk-toggle-speak-nonprinting-chars)
        ("o" dtk-toggle-strip-octals)
        ("p" dtk-set-punctuations)
        ("q" dtk-toggle-quiet )
        ("r" dtk-set-rate)
        ("s" dtk-toggle-split-caps)
        ("t" emacspeak-dial-dtk)
        ("v" voice-lock-mode)
        ("w" emacspeak-toggle-word-echo)
        ("z" emacspeak-zap-tts)
        )
      do
      (emacspeak-keymap-update emacspeak-dtk-submap binding))

(dotimes (i 10)
  (define-key emacspeak-dtk-submap
    (format "%s" i )   'dtk-set-predefined-speech-rate ))

;;; Put these in the global map:
(global-set-key [(shift left)] 'previous-buffer)
(global-set-key [(shift right)] 'next-buffer)
(global-set-key [(control left)] 'emacspeak-previous-frame-or-buffer)
(global-set-key [(control right)] 'emacspeak-next-frame-or-buffer)
(global-set-key [(control down)] 'pop-to-mark-command)
(global-set-key [(control up)] 'emacspeak-mark-backward-mark)
(global-set-key [(shift up)] 'emacspeak-skip-blank-lines-backward)
(global-set-key [(shift down)] 'emacspeak-skip-blank-lines-forward)
(global-set-key [27 up]  'emacspeak-owindow-previous-line)
(global-set-key  [27 down]  'emacspeak-owindow-next-line)
(global-set-key  [27 prior]  'emacspeak-owindow-scroll-down)
(global-set-key  [27 next]  'emacspeak-owindow-scroll-up)
(global-set-key  [27 select]  'emacspeak-owindow-speak-line)
(define-key esc-map "\M-:" 'emacspeak-wizards-show-eval-result)
;;}}}
;;{{{ emacspeak under X windows

;;; Get hyper, alt and super like on the console:
(global-set-key (kbd "C-,") 'emacspeak-alt-keymap)
(global-set-key  (kbd "C-'") 'emacspeak-super-keymap)
(global-set-key  (kbd "C-;") 'emacspeak-hyper-keymap)
;;; Our very own silence key on the console
;;; I use the Windows key.
(global-set-key '[silence] 'emacspeak-silence)
(global-set-key '[search] 'emacspeak-search)
;;}}}
;;{{{ Interactively switching the emacspeak-prefix
;;;###autoload
(defun emacspeak-keymap-choose-new-emacspeak-prefix (prefix-key)
  "Interactively select a new prefix key to use for all emacspeak
commands.  The default is to use `C-e'  This command
lets you switch the prefix to something else.  This is a useful thing
to do if you run emacspeak on a remote machine from inside a terminal
that is running inside a local emacspeak session.  You can have the
remote emacspeak use a different control key to give your fingers some
relief."
  (interactive "kPress the key you would like to use as the emacspeak prefix")
  (declare (special emacspeak-prefix))
  (let ((current-use (lookup-key  global-map prefix-key)))
    (global-set-key prefix-key 'emacspeak-prefix-command)
    (unless (eq  current-use 'emacspeak-prefix-command)
      (global-set-key (concat prefix-key prefix-key) current-use)
      (message "Use %s %s to execute %s since %s is now the emacspeak prefix"
               prefix-key prefix-key current-use
               prefix-key))))

;;}}}
;;{{{  removing emacspeak-self-insert-command in non-edit modes.
;;;###autoload
(defun emacspeak-keymap-remove-emacspeak-edit-commands
    (keymap)
  "We define keys that invoke editing commands to be undefined"
  (loop for k in
        (where-is-internal 'emacspeak-self-insert-command
                           (list keymap))
        do
        (define-key keymap k 'undefined )
        ))

(defun emacspeak-keymap-refresh ()
  "Load emacspeak-keymap module."
  (load-library "emacspeak-keymap"))

;;}}}
;;{{{ Create a personal keymap for c-e x

;;; Adding keys using custom:
(defvar  emacspeak-personal-keymap nil
  "Emacspeak personal keymap")

(define-prefix-command 'emacspeak-personal-keymap   'emacspeak-personal-keymap)

(defcustom emacspeak-personal-keys nil
  "*Specifies personal key bindings for the audio desktop.
Bindings specified here are available on prefix key C-e x
for example, if you bind
`s' to command emacspeak-emergency-tts-restart
then that command will be available on key C-e x s.

KEYS should be a string constant in the format used for saving
keyboard macros (see `edmacro-mode').

Command is an interactive command or a prefix-command that can be
bound to a key. 

The value of this variable is an association list. The car of
each element specifies a key sequence. The cdr specifies an
interactive command that the key sequence executes."
  :group 'emacspeak
  :type '(repeat
          :tag "Emacspeak Personal Keymap"
          (cons
           :tag "Key Binding"
           (key-sequence :tag "Key")
           (ems-interactive-command :tag "Command")))
  :set #'(lambda (sym val)
           (emacspeak-keymap-bindings-update emacspeak-personal-keymap val)
           (set-default sym
                        (sort
                         val
                         #'(lambda (a b) (string-lessp (car a) (car b)))))))

(define-key  emacspeak-keymap "x" 'emacspeak-personal-keymap)
(define-key  emacspeak-keymap "\C-x" 'emacspeak-personal-ctlx-keymap)
;;}}}
;;{{{ Create personal ctl-x map 

(defvar  emacspeak-personal-ctlx-keymap nil
  "Emacspeak personal-ctlx keymap")

(define-prefix-command 'emacspeak-personal-ctlx-keymap
  'emacspeak-personal-ctlx-keymap)

(defcustom emacspeak-personal-ctlx-keys nil
  "*Specifies personal-ctlx key bindings for use with C-e C-x for
the audio desktop. Bindings specified here are available on
prefix key C-e C-x for example, if you bind `C-s' to command
emacspeak-emergency-tts-restart then that command will be
available on key C-e C-x C-s. KEYS should be a string constant in
the format used for saving keyboard macros (see `edmacro-mode').

Command is an interactive command or a prefix-command that can be
bound to a key.

The value of this variable is an association list. The car of
each element specifies a key sequence. The cdr specifies an
interactive command that the key sequence executes."
  :group 'emacspeak
  :type '(repeat
          :tag "Emacspeak Personal-Ctlx Keymap"
          (cons
           :tag "Key Binding"
           (key-sequence :tag "Key")
           (ems-interactive-command :tag "Command")))
  :set #'(lambda (sym val)
           (emacspeak-keymap-bindings-update emacspeak-personal-ctlx-keymap val)
           (set-default sym
                        (sort
                         val
                         #'(lambda (a b) (string-lessp (car a) (car b)))))))

;;}}}
;;{{{ Create a super keymap that users can put personal commands

;;; I use the right windows menu key for super
;;on
;;; Adding keys using custom:
(defvar  emacspeak-super-keymap nil
  "Emacspeak super keymap")

(define-prefix-command 'emacspeak-super-keymap   'emacspeak-super-keymap)

(defcustom emacspeak-super-keys nil
  "*Specifies super key bindings for the audio desktop. You can
turn the right `windows menu' keys on your Linux PC keyboard into
a `super' key on Linux by having it emit the sequence `C-x@s'.

Bindings specified here are available on prefix key `super' for
example, if you bind `s' to command
emacspeak-emergency-tts-restart then that command will be
available on key `super s'. KEYS should be a string constant in
the format used for saving keyboard macros (see `edmacro-mode').

Command is an interactive command or a prefix-command that can be
bound to a key.

The value of this variable is an association list. The car of
each element specifies a key sequence. The cdr specifies an
interactive command that the key sequence executes."

  :group 'emacspeak
  :type '(repeat
          :tag "Emacspeak Super Keymap"
          (cons
           :tag "Key Binding"
           (key-sequence :tag "Key")
           (ems-interactive-command :tag "Command")))
  :set #'(lambda (sym val)
           (emacspeak-keymap-bindings-update emacspeak-super-keymap  val)
           (set-default sym
                        (sort
                         val
                         #'(lambda (a b) (string-lessp (car a) (car b)))))))

(global-set-key "\C-x@s"
                'emacspeak-super-keymap)

;;}}}
;;{{{ Create a alt keymap that users can put personal commands

;;; I use the "pause" key to produce C-x@a -- which gives alt-
;;on
;;; Adding keys using custom:
(defvar  emacspeak-alt-keymap nil
  "Emacspeak alt keymap")

(define-prefix-command 'emacspeak-alt-keymap   'emacspeak-alt-keymap)

(defcustom emacspeak-alt-keys nil
  "*Specifies alt key bindings for the audio desktop.
You can turn the `Pause' key  on your Linux PC keyboard into a `alt' key
on Linux by having it emit the sequence `C-x@a'.

Bindings specified here are available on prefix key `alt'
(not to be confused with alt==meta)
for example, if you bind
`s' to command emacspeak-emergency-tts-restart
then that command will be available on key `ALT  s'

KEYS should be a string constant in the format used for saving
keyboard macros (see `edmacro-mode').

Command is an interactive command or a prefix-command that can be
bound to a key. 

The value of this variable is an association list. The car of
each element specifies a key sequence. The cdr specifies an
interactive command that the key sequence executes."
  :group 'emacspeak
  :type '(repeat
          :tag "Emacspeak Alt Keymap"
          (cons
           :tag "Key Binding"
           (key-sequence :tag "Key")
           (ems-interactive-command :tag "Command")))
  :set #'(lambda (sym val)
           (emacspeak-keymap-bindings-update emacspeak-alt-keymap val)
           (set-default sym
                        (sort
                         val
                         #'(lambda (a b) (string-lessp (car a) (car b)))))))

(global-set-key "\C-x@a"
                'emacspeak-alt-keymap)

;;}}}
;;{{{ Create a hyper keymap that users can put personal commands

;;; I use the windows key for hyper
;;on
;;; Adding keys using custom:
(defvar  emacspeak-hyper-keymap nil
  "Emacspeak hyper keymap")

(define-prefix-command 'emacspeak-hyper-keymap   'emacspeak-hyper-keymap)

(defcustom emacspeak-hyper-keys nil
  "*Specifies hyper key bindings for the audio desktop. Emacs can
use the `hyper' key as a modifier key. You can turn the `windows'
keys on your Linux PC keyboard into a `hyper' key on Linux by
having it emit the sequence `C-x@h'.

Bindings specified here are available on prefix key `hyper' for
example, if you bind `b' to command `bbdb ' then that command
will be available on key `hyper b'.

KEYS should be a string constant in the format used for saving
keyboard macros (see `edmacro-mode').

Command is an interactive command or a prefix-command that can be
bound to a key. 

The value of this variable is an association list. The car of
each element specifies a key sequence. The cdr specifies an
interactive command that the key sequence executes."
  :group 'emacspeak
  :type '(repeat
          :tag "Emacspeak Hyper Keys"
          (cons
           :tag "Key Binding"
           (key-sequence :tag "Key")
           (ems-interactive-command :tag "Command")))
  :set #'(lambda (sym val)
           (emacspeak-keymap-bindings-update emacspeak-hyper-keymap val)
           (set-default sym
                        (sort
                         val
                         #'(lambda (a b) (string-lessp (car a) (car b)))))))

(global-set-key "\C-x@h"
                'emacspeak-hyper-keymap)
(define-key emacspeak-hyper-keymap " " 'emacspeak-webspace)
;;}}}
(provide 'emacspeak-keymap)

;;{{{  emacs local variables

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
