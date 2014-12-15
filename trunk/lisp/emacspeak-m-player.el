;;; emacspeak-m-player.el --- Control mplayer from Emacs
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description: Controlling mplayer from emacs 
;;; Keywords: Emacspeak, m-player streaming media 
;;{{{  LCD Archive entry: 

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2008-06-29 17:58:19 -0700 (Sun, 29 Jun 2008) $ |
;;;  $Revision: 4532 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;; Copyright (c) 1995 -- 2011, T. V. Raman
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

;;{{{ Introduction:

;;; Commentary:

;;; Defines a simple derived mode for interacting with mplayer.
;;; mplayer  is a versatile media player capable of playing many
;;; streaming formats  and is especially useful for playing windows
;;; media (WMA) and streaming windows media (ASF) files.
;;;mplayer is available  on the WWW:
;;; RPM package
;;;http://mirrors.sctpc.com/dominik/linux/pkgs/mplayer/i586/mplayer-0.90pre5-2.i586.rpm
;;;You may need the  win32 codecs which can be downloaded from 
;;;http://ftp.lug.udel.edu/MPlayer/releases/w32codec-0.60.tar.bz2
;;;Mplayer FAQ at
;;;http://www.mplayerhq.hu/DOCS/faq.html
;;; Mplayer docs at 
;;; http://www.mplayerhq.hu/DOCS/
;;; Code:

;;}}}
;;{{{  Required modules

(require 'emacspeak-preamble)
(require 'emacspeak-amark)
(require 'emacspeak-webutils)
(require 'dired)
(require 'comint)

;;}}}
;;{{{ define a derived mode for m-player interaction 
(defvar emacspeak-media-shortcuts-directory 
  (expand-file-name "realaudio/" emacspeak-directory)
  "*Directory where we organize  mp3  libraries and media shortcuts. ")

(defvar emacspeak-m-player-process nil
  "Process handle to m-player." )
(defsubst emacspeak-m-player-dispatch (command)
  "Dispatch command to m-player."
  (declare (special emacspeak-m-player-process))
  (with-current-buffer (process-buffer emacspeak-m-player-process)
    (erase-buffer)
    (process-send-string
     emacspeak-m-player-process
     (format "pausing_keep %s\n" command))
    (accept-process-output emacspeak-m-player-process 0.1)
    (unless (zerop (buffer-size))
      (buffer-substring-no-properties (point-min) (1-  (point-max))))))
(defvar emacspeak-m-player-current-directory nil
  "Records current directory of media being played.
This is set to nil when playing Internet  streams.")

(defsubst emacspeak-m-player-mode-line ()
  "Meaningful mode-line."
  (let ((info (emacspeak-m-player-get-position)))
    (format "%s: %s"
            (first info)
            (second info))))

(defun emacspeak-m-player-speak-mode-line ()
  "Speak mode line"
  (interactive)
  (tts-with-punctuations
   'all
   (dtk-speak (emacspeak-m-player-mode-line))))

(define-derived-mode emacspeak-m-player-mode comint-mode 
  "M-Player Interaction"
  "Major mode for m-player interaction. \n\n
\\{emacspeak-m-player-mode-map}"
  (progn
    (setq buffer-undo-list t)
    (ansi-color-for-comint-mode-on)
    (setq emacspeak-m-player-process (get-buffer-process (current-buffer)))))

;;}}}
;;{{{ emacspeak-m-player

;;;###autoload

(defgroup emacspeak-m-player nil
  "Emacspeak media player settings."
  :group 'emacspeak)

(defcustom emacspeak-m-player-program "mplayer"
  "Media player program."
  :type 'string
  :set  #'(lambda (sym val)
            (set-default sym
                         (executable-find val)))
  :group 'emacspeak-m-player)

(defvar emacspeak-m-player-default-options
  (list "-slave"  "-nortc""-softvol" "-softvol-max" "200" "-quiet")
  "Default options for MPlayer.")
(defcustom emacspeak-m-player-options 
  (copy-sequence emacspeak-m-player-default-options)
  "Options passed to mplayer."
  :type  '(repeat
           (string :tag "option"))
  :group 'emacspeak-m-player)
;;;###autoload
(defcustom emacspeak-media-location-bindings  nil
  "*Map specific key sequences to launching MPlayer accelerators 
on a specific directory."
  :group 'emacspeak-m-player
  :type '(repeat :tag "Emacspeak Media Locations"
                 (cons  :tag "KeyBinding"
                        (string :tag "Key")
                        (directory :tag "Directory")))
  :set #'(lambda (sym val)
           (mapc
            (lambda (binding)
              (let ((key (car binding))
                    (directory (cdr binding )))
                (when (string-match "\\[.+]" key)
                  (setq key (car (read-from-string key))))
                (emacspeak-m-player-bind-accelerator directory key)))
            val)
           (set-default sym val)))
(defvar emacspeak-media-directory-regexp
  (regexp-opt '("mp3" "audio"))
  "Pattern matching locations where we store media.")

;;;###autoload
(defun emacspeak-multimedia  ()
  "Start or control Emacspeak multimedia player."
  (interactive )
  (declare (special emacspeak-m-player-process))
  (cond
   ((and emacspeak-m-player-process
         (eq 'run (process-status emacspeak-m-player-process))
         (buffer-live-p (process-buffer emacspeak-m-player-process)))
    (with-current-buffer (process-buffer emacspeak-m-player-process)
      (call-interactively 'emacspeak-m-player-command)))
   (t
    (call-interactively 'emacspeak-m-player))))

(defun emacspeak-m-player-command (key)
  "Invoke MPlayer commands."
  (interactive (list (read-key-sequence "MPlayer Key: ")))
  (declare (special emacspeak-m-player-process))
  (cond
   ((and (stringp key) (string= ";" key))
    (pop-to-buffer (process-buffer emacspeak-m-player-process))
    (emacspeak-speak-mode-line))
   (t (call-interactively (lookup-key emacspeak-m-player-mode-map key)))))

(defvar  emacspeak-m-player-playlist-pattern
  (concat
   (regexp-opt
    (list ".m3u" ".asx" ".pls" ".rpm" ".ram"  ))
   "$")
  "Pattern for matching playlists.")

(defsubst emacspeak-m-player-playlist-p (resource)
  "Check if specified resource matches a playlist type."
  (declare (special emacspeak-m-player-playlist-pattern))
  (string-match emacspeak-m-player-playlist-pattern resource))
;;;###autoload
(defvar emacspeak-media-extensions
  (concat
   (regexp-opt
    (list ".wma"
          ".wmv"
          ".flv"
          ".m4a"
          ".m4b"
          ".flac"
          ".ogg"
          ".mp3"
          ".MP3"
          ".mp4")
    'parens)
   "$")
  "Extensions that match media files.")

;;;###autoload
(defun emacspeak-m-player-bind-accelerator (directory key)
  "Binds key to invoke m-player  on specified directory."
  (interactive
   (list
    (read-directory-name"Media Directory: ")
    (read-key-sequence "Key: ")))
  (let ((command
         (eval 
          `(defun 
               ,(intern (format "emacspeak-m-player-accelerator-%s" (gensym)))
               ()
             (interactive)
             (emacspeak-m-player-accelerator ,directory)))))
    (global-set-key key command)))

;;;###autoload
(defun emacspeak-m-player-accelerator (directory)
  "Launch MPlayer on specified directory and switch to it."
  (let ((emacspeak-media-shortcuts-directory (expand-file-name directory)))
    (call-interactively 'emacspeak-multimedia)
    (switch-to-buffer (process-buffer emacspeak-m-player-process))
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))
(defsubst emacspeak-m-player-guess-directory ()
  "Guess default directory."
  (declare (special emacspeak-media-directory-regexp))
  (if (string-match emacspeak-media-directory-regexp  default-directory)
      default-directory
    emacspeak-media-shortcuts-directory))

;;;###autoload 
(defun emacspeak-m-player-url (url)
  "Call emacspeak-m-player with specified URL."
  (interactive "sURL: ")
  (emacspeak-m-player url))
;;;###autoload

(defvar emacspeak-m-player-file-list nil
  "List  that records list of files being played.")
(make-variable-buffer-local 'emacspeak-m-player-file-list)
(defsubst emacspeak-m-player-directory-files (directory)
  "Return media files in directory.
Searches recursively if `directory-files-recursively' is available (Emacs 25)."
  (declare (special emacspeak-media-extensions))
  (cond
   ((fboundp 'directory-files-recursively)
    (directory-files-recursively directory emacspeak-media-extensions))
   (t (directory-files  directory 'full emacspeak-media-extensions))))

;;;###autoload
(defun emacspeak-m-player (resource &optional play-list)
  "Play specified resource using m-player.
Optional prefix argument play-list interprets resource as a play-list.
Resource is a media resource or playlist containing media resources.
The player is placed in a buffer in emacspeak-m-player-mode."
  (interactive
   (list
    (let ((completion-ignore-case t)
          (emacspeak-speak-messages nil)
          (read-file-name-completion-ignore-case t)
          (ido-work-directory-list
           (remove-if-not 
            #'(lambda (d)
                (string-match  emacspeak-media-directory-regexp  d))
            ido-work-directory-list)))
      (read-file-name
       "MP3 Resource: "
       (emacspeak-m-player-guess-directory)
       (when (eq major-mode 'dired-mode) (dired-get-filename))))
    current-prefix-arg))
  (declare (special  default-directory
                     emacspeak-m-player-file-list emacspeak-m-player-current-directory
                     ido-work-directory-list emacspeak-media-directory-regexp
                     emacspeak-media-shortcuts-directory emacspeak-m-player-process
                     emacspeak-m-player-program emacspeak-m-player-options))
  (when (and emacspeak-m-player-process
             (eq 'run (process-status emacspeak-m-player-process))
             (y-or-n-p "Stop currently playing music? "))
    (emacspeak-m-player-quit)
    (setq emacspeak-m-player-process nil))
  (let ((buffer (get-buffer-create "*M-Player*"))
        (process-connection-type nil)
        (playlist-p
         (or play-list
             (emacspeak-m-player-playlist-p resource)))
        (options (copy-sequence emacspeak-m-player-options))
        (file-list nil))
    (unless (string-match "^[a-z]+:"  resource) ; not a URL
    (setq resource (expand-file-name resource))
    (setq emacspeak-m-player-current-directory (file-name-directory resource)))
    (when (file-directory-p resource)
      (setq file-list (emacspeak-m-player-directory-files resource)))
    (when (getenv "ALSA_DEFAULT")
      (setq options
            (nconc options
                   (list "-ao"
                         (format "alsa:device=%s"
                                 (getenv "ALSA_DEFAULT"))))))
    (setq options
          (cond
           (playlist-p
            (nconc options (list "-playlist" resource)))
           (file-list (nconc options file-list))
           (t
            (nconc options (list resource)))))
    (with-current-buffer buffer
      (setq emacspeak-m-player-process
            (apply 'start-process "MPLayer" buffer
                   emacspeak-m-player-program options))
      (when emacspeak-m-player-current-directory (cd emacspeak-m-player-current-directory))
      (emacspeak-m-player-mode)
      (emacspeak-amark-load)
      (setq  emacspeak-m-player-file-list file-list)
      (message "MPlayer opened  %s" resource))))

;;;###autoload
(defun emacspeak-m-player-shuffle ()
  "Launch M-Player with shuffle turned on."
  (interactive)
  (declare (special emacspeak-m-player-options))
  (let ((emacspeak-m-player-options (append emacspeak-m-player-options (list "-shuffle"))))
    (call-interactively 'emacspeak-m-player)))

;;;###autoload

(defun emacspeak-m-player-load (resource  &optional append)
  "Load specified resource into a running  m-player.
Interactive prefix arg appends the new resource to what is playing."
  (interactive
   (list
    (let ((completion-ignore-case t)
          (emacspeak-speak-messages nil)
          (read-file-name-completion-ignore-case t))
      (read-file-name
       "MP3 Resource: "
       (if
           (string-match "\\(mp3\\)\\|\\(audio\\)"
                         (expand-file-name default-directory))
           default-directory
         emacspeak-media-shortcuts-directory)
       (when (eq major-mode 'dired-mode)
         (dired-get-filename))))
    current-prefix-arg))
  (declare (special emacspeak-media-extensions
                    emacspeak-media-shortcuts-directory))
  (unless (string-match "^[a-z]+:"  resource)
    (setq resource (expand-file-name resource)))
  (emacspeak-m-player-dispatch 
   (format "loadfile %s %s" resource
           (if append 1 ""))))

;;}}}
;;{{{ Table of slave commands:

(defvar emacspeak-m-player-command-list nil
  "Cache of MPlayer slave commands.")

(defun emacspeak-m-player-command-list ()
  "Return MPlayer slave command table, populating it if
necessary."
  (declare (special emacspeak-m-player-command-list))
  (cond
   (emacspeak-m-player-command-list emacspeak-m-player-command-list)
   (t
    (let ((commands
           (split-string 
            (shell-command-to-string
             (format "%s -input cmdlist"
                     emacspeak-m-player-program))
            "\n" 'omit-nulls)))
      (setq emacspeak-m-player-command-list
            (loop  for c in commands
                   collect
                   (split-string c " " 'omit-nulls)))))))

;;}}}
;;{{{ commands 

(defsubst emacspeak-m-player-current-filename ()
  "Return filename of currently playing track."
  (second
   (split-string
    (emacspeak-m-player-dispatch "get_file_name\n")
    "=")))

(defun emacspeak-m-player-scale-speed (factor)
  "Scale speed by specified factor."
  (interactive "nFactor:")
  (emacspeak-m-player-dispatch
   (format "speed_mult %f" factor)))

(defun emacspeak-m-player-slower ()
  "Slow down playback."
  (interactive)
  (emacspeak-m-player-scale-speed 0.9091))

(defun emacspeak-m-player-faster ()
  "Speed up  playback."
  (interactive)
  (emacspeak-m-player-scale-speed 1.1))

(defun emacspeak-m-player-half-speed ()
  "Scale speed by 0.5."
  (interactive)
  (emacspeak-m-player-scale-speed 0.5))

(defun emacspeak-m-player-double-speed()
  "Scale speed by 2.0"
  (interactive)
  (emacspeak-m-player-scale-speed 2.0))

(defun emacspeak-m-player-reset-speed ()
  "Reset playing speed to normal."
  (interactive)
  (emacspeak-m-player-dispatch
   "speed_set 1.0"))

(defun emacspeak-m-player-play-tracks-jump (step)
  "Move within the play tree."
  (interactive"nSkip Tracks:")
  (emacspeak-m-player-dispatch
   (format "pt_step %d" step)))

(defun emacspeak-m-player-previous-track ()
  "Move to previous track."
  (interactive)
  (emacspeak-m-player-play-tracks-jump -1))

(defun emacspeak-m-player-next-track ()
  "Move to next track."
  (interactive)
  (emacspeak-m-player-play-tracks-jump 1))

(defun emacspeak-m-player-play-tree-up (step)
  "Move within the play tree."
  (interactive
   (list
    (read-from-minibuffer "Move by: ")))
  (emacspeak-m-player-dispatch
   (format "pt_up %s" step)))

(defun emacspeak-m-player-alt-src-step (step)
  "Move within an ASF playlist."
  (interactive
   (list
    (read-from-minibuffer "Move by: ")))
  (emacspeak-m-player-dispatch
   (format "alt_src_step %s" step)))

(defun emacspeak-m-player-seek-relative (offset)
  "Seek  by offset into stream from current position."
  (interactive
   (list
    (read-from-minibuffer "Offset: ")))
  (emacspeak-m-player-dispatch
   (format "seek %s" offset)))

(defun emacspeak-m-player-seek-absolute (position)
  "Seek  to absolute specified position."
  (interactive
   (list
    (read-from-minibuffer "Seek to percentage: ")))
  (emacspeak-m-player-dispatch
   (format "seek %s 1" position )))

(defun emacspeak-m-player-beginning-of-track()
  "Move to beginning of track."
  (interactive)
  (emacspeak-m-player-seek-absolute "0"))

(defun emacspeak-m-player-end-of-track()
  "Move to beginning of track."
  (interactive)
  (emacspeak-m-player-seek-absolute "99"))

(defun emacspeak-m-player-backward-10s ()
  "Move back by 10 seconds."
  (interactive)
  (emacspeak-m-player-seek-relative "-10"))

(defun emacspeak-m-player-forward-10s ()
  "Move forward by 10 seconds."
  (interactive)
  (emacspeak-m-player-seek-relative "10"))

(defun emacspeak-m-player-backward-1min ()
  "Move back by 1 minute."
  (interactive)
  (emacspeak-m-player-seek-relative "-60"))

(defun emacspeak-m-player-forward-1min ()
  "Move forward by 1 minute."
  (interactive)
  (emacspeak-m-player-seek-relative "60"))

(defun emacspeak-m-player-backward-10min ()
  "Move backward by ten minutes."
  (interactive)
  (emacspeak-m-player-seek-relative "-600"))

(defun emacspeak-m-player-forward-10min ()
  "Move forward by ten minutes."
  (interactive)
  (emacspeak-m-player-seek-relative "600"))

(defun emacspeak-m-player-pause ()
  "Pause or unpause media player."
  (interactive)
  (emacspeak-m-player-dispatch "pause"))

(defun emacspeak-m-player-quit ()
  "Quit media player."
  (interactive)
  (declare (special emacspeak-amark-list emacspeak-m-player-recent-amark-name))
  (let ((kill-buffer-query-functions nil))
    (when (eq (process-status emacspeak-m-player-process) 'run)
      (let ((buffer (process-buffer emacspeak-m-player-process)))
        (when emacspeak-amark-list
          (emacspeak-m-player-amark-add emacspeak-m-player-recent-amark-name)
          (emacspeak-amark-save))
        (emacspeak-m-player-dispatch "quit")
        (emacspeak-auditory-icon 'close-object)
        (and (buffer-live-p buffer)
             (kill-buffer buffer))))
    (unless (eq (process-status emacspeak-m-player-process) 'exit)
      (delete-process  emacspeak-m-player-process))
    (emacspeak-speak-mode-line)))

;;;###autoload
(defun emacspeak-m-player-volume-up ()
  "Increase volume."
  (interactive)
  (emacspeak-m-player-dispatch "volume 1"))

;;;###autoload
(defun emacspeak-m-player-volume-down ()
  "Decrease volume."
  (interactive)
  (emacspeak-m-player-dispatch "volume -1"))
;;;###autoload
(defun emacspeak-m-player-volume-change (offset)
  "Change volume.
A value of <number> changes volume by specified offset.
A string of the form `<number> 1' sets volume as an absolute."
  (interactive"sChange Volume By:")
  (emacspeak-m-player-dispatch
   (format "volume %s" offset)))

;;;###autoload
(defun emacspeak-m-player-balance ()
  "Set left/right balance."
  (interactive)
  (emacspeak-m-player-dispatch
   (format "balance %s"
           (read-from-minibuffer "Balance: "))))

;;;###autoload
(defun emacspeak-m-player-slave-command ()
  "Dispatch slave command read from minibuffer."
  (interactive)
  (with-current-buffer (process-buffer emacspeak-m-player-process)
    (let* ((command (completing-read "Slave Command: " (emacspeak-m-player-command-list)))
           (args
            (when (cdr (assoc command emacspeak-m-player-command-list))
              (read-from-minibuffer
               (mapconcat #'identity
                          (cdr (assoc command emacspeak-m-player-command-list))
                          " ")))))
      (message  "%s"
                (emacspeak-m-player-dispatch (format "%s %s" command args))))))

;;;###autoload
(defun emacspeak-m-player-get-length ()
  "Display length of track in seconds."
  (interactive)
  (emacspeak-m-player-dispatch "get_time_length")
  (accept-process-output))

(defsubst emacspeak-m-player-get-position ()
  "Return list suitable to use as an amark. --- see emacspeak-amark.el."
  (declare (special emacspeak-m-player-process))
  (emacspeak-m-player-dispatch "get_time_pos\nget_file_name\n")
  (with-current-buffer (process-buffer emacspeak-m-player-process)
    (let* ((output  (buffer-substring-no-properties (point-min) (point-max)))
           (lines (split-string output "\n" 'omit-nulls))
           (fields 
            (loop 
             for l in lines 
             collect (second (split-string l "=")))))
      (list 
       (format "%s" (first fields))     ; position 
       (if (second fields)
           (substring (second  fields) 1 -1)
         "")))))

(defun emacspeak-m-player-display-position ()
  "Display current position in track and its length."
  (interactive)
  (emacspeak-m-player-dispatch
   "get_time_pos\nget_percent_pos\nget_time_length\nget_file_name\n")
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'select-object)))

(defun emacspeak-m-player-load-file(f)
  "Load specified file."
  (interactive "fMedia File:")
  (emacspeak-m-player-dispatch
   (format "loadfile %s"
           (expand-file-name f))))

(defun emacspeak-m-player-load-playlist(f)
  "Load specified playlist file."
  (interactive "fPlaylist File:")
  (emacspeak-m-player-dispatch
   (format "loadlist %s"
           (expand-file-name f))))

(defvar emacspeak-m-player-filters
  '(("hrtf" . "hrtf")
    ("sweep". "sweep")
    ("extrastereo" . "extrastereo")
    ("volnorm" . "volnorm")
    ("surround" . "surround"))
  "Table of useful MPlayer filters.")

(defun emacspeak-m-player-add-filter ()
  "Adds specified filter  to use for the next invocation of MPlayer."
  (interactive)
  (let ((filter-name
         (completing-read "Filter:"
                          emacspeak-m-player-filters)))
    (setq emacspeak-m-player-options
          (append emacspeak-m-player-options
                  (list "-af" filter-name)))))

(defun emacspeak-m-player-customize-options ()
  "Use Customize to manipulate MPlayer options."
  (interactive)
  (customize-variable 'emacspeak-m-player-options)
  (goto-char (point-min))
  (search-forward "INS"))

;;}}}
;;{{{ equalizer 

(defvar emacspeak-m-player-equalizer (make-vector 10 12)
  "Vector holding equalizer settings.")

(defun emacspeak-m-player-equalizer-control (v)
  "Manipulate values in specified vector using minibuffer."
  (interactive)
  (let ((column 0)
        (key nil)
        (continue t))
    (while  continue
      (setq key  (read-key-sequence
                  (format "G%s:%s" column (aref v column))))
      (cond
       ((equal key [left])
        (setq column (% (+ 9  column) 10)))
       ((equal key [right])
        (setq column (% (1+ column) 10)))
       ((equal key [up])
        (aset v   column
              (min 12 (1+ (aref v column)))))
       ((equal key [down])
        (aset v   column
              (max -12 (1- (aref v column)))))
       ((equal key [prior])
        (aset v   column
              (min 12 (+ 4  (aref v column)))))
       ((equal key [next])
        (aset v   column
              (max -12 (- (aref v column)  4))))
       ((equal key [home])
        (aset v   column 12))
       ((equal key [end])
        (aset v   column -12))
       ((equal key "\C-g") (error "Did not change equalizer."))
       ((equal key "\C-m")
        (setq continue nil))))
    (mapconcat
     #'(lambda (value) (format "%d" value))
     v  ":")))

(defun emacspeak-m-player-add-equalizer ()
  "Add equalizer for next MPlayer invocation.

Use arrow keys, page-up, page-down, home and end keys to
  manipulate the values.
Hit enter to finish setting the equalizer values.

The Mplayer equalizer provides 10 bands, G0 -- G9, see the
  MPlayer man page for details."
  (interactive)
  (declare (special emacspeak-m-player-equalizer
                    emacspeak-m-player-options))
  (setq emacspeak-m-player-options
        (append emacspeak-m-player-options
                (list "-af"
                      (format "equalizer=%s"
                              (emacspeak-m-player-equalizer-control emacspeak-m-player-equalizer))))))
(defun emacspeak-m-player-reset-options ()
  "Reset MPlayer options to initial defaults."
  (interactive)
  (declare (special emacspeak-m-player-default-options
                    emacspeak-m-player-options))
  (setq emacspeak-m-player-options
        emacspeak-m-player-default-options)
  (message "Reset options."))

;;}}}
;;{{{ keys

(declaim (special emacspeak-m-player-mode-map))
(loop for k in 
      '(
        (" " emacspeak-m-player-pause)
        ("+" emacspeak-m-player-volume-up)
        ("," emacspeak-m-player-backward-10s)
        ("-" emacspeak-m-player-volume-down)
        ("." emacspeak-m-player-forward-10s)
        ("<" emacspeak-m-player-backward-1min)
        ("=" emacspeak-m-player-volume-up)
        (">" emacspeak-m-player-forward-1min)
        ("?" emacspeak-m-player-display-position)
        ("L" emacspeak-m-player-load-file)
        ("O" emacspeak-m-player-reset-options)
        ("Q" emacspeak-m-player-quit)
        ("S" emacspeak-amark-save)
        ("[" emacspeak-m-player-slower)
        ("\C-em" emacspeak-m-player-speak-mode-line)
        ("\C-m" emacspeak-m-player-load)
        ("\M-l" emacspeak-m-player-load-playlist)
        ("\d" emacspeak-m-player-reset-speed)
        ("]" emacspeak-m-player-faster)
        ("a" emacspeak-m-player-amark-add)
        ("b" emacspeak-m-player-balance)
        ("c" emacspeak-m-player-slave-command)
        ("e" emacspeak-m-player-add-equalizer)
        ("f" emacspeak-m-player-add-filter)
        ("g" emacspeak-m-player-seek-absolute)
        ("j" emacspeak-m-player-amark-jump)
        ("k"emacspeak-m-player-bind-accelerator)
        ("l" emacspeak-m-player-get-length)
        ("m" emacspeak-m-player-speak-mode-line)
        ("n" emacspeak-m-player-next-track)
        ("o" emacspeak-m-player-customize-options)
        ("p" emacspeak-m-player-previous-track)
        ("q" bury-buffer)
        ("r" emacspeak-m-player-seek-relative)
        ("s" emacspeak-m-player-scale-speed)
        ("t" emacspeak-m-player-play-tracks-jump)
        ("v" emacspeak-m-player-volume-change)
        ("{" emacspeak-m-player-half-speed)
        ("}" emacspeak-m-player-double-speed)
        ([down] emacspeak-m-player-forward-1min)
        ([end] emacspeak-m-player-end-of-track)
        ([home] emacspeak-m-player-beginning-of-track)
        ([left] emacspeak-m-player-backward-10s)
        ([next] emacspeak-m-player-forward-10min)
        ([prior] emacspeak-m-player-backward-10min)
        ([right] emacspeak-m-player-forward-10s)
        ([up] emacspeak-m-player-backward-1min)
        )
      do
      (emacspeak-keymap-update  emacspeak-m-player-mode-map k))

;;}}}
;;{{{ YouTube Player

(defcustom emacspeak-m-player-youtube-dl
  "/usr/local/bin/youtube-dl"
  "YouTube download tool"
  :type 'string
  :group 'emacspeak-m-player)

;;;###autoload

(defun emacspeak-m-player-youtube-player (url)
  "Use youtube-dl and mplayer to stream YouTube content."
  (interactive
   (list
    (emacspeak-webutils-read-this-url)))
  (declare (special emacspeak-m-player-youtube-dl))
  (unless (file-executable-p emacspeak-m-player-youtube-dl)
    (error "Please install youtube-dl first."))
  (emacspeak-m-player
   (substring
    (shell-command-to-string
     (format "%s -g '%s'"
             emacspeak-m-player-youtube-dl
             url))
    0
    -1)))

;;}}}
;;{{{ pause/resume 

;;;###autoload
(defun emacspeak-m-player-pause-or-resume ()
  "Pause/resume if m-player is running. For use  in
emacspeak-silence-hook."
  (declare (special emacspeak-m-player-process))
  (when (and emacspeak-m-player-process
             (eq 'run (process-status emacspeak-m-player-process)))
    (emacspeak-m-player-pause)))
(add-hook 'emacspeak-silence-hook 'emacspeak-m-player-pause-or-resume)

;;}}}
;;{{{ AMarks:

(defcustom emacspeak-m-player-recent-amark-name "LastStopped"
  "Name used to  mark position where we quit a stream."
  :type 'string
  :group 'emacspeak-m-player)

;;;###autoload
(defun emacspeak-m-player-amark-add (name &optional prompt-position)
  "Set AMark `name' at current position in current audio stream.
Interactive prefix arg prompts for position.
As the default, use current position."
  (interactive "sAMark Name:\nP")
  (let ((position (emacspeak-m-player-get-position)))
    (emacspeak-amark-add
     (second position) ;file-name
     name; mark name
     (cond
      (prompt-position (read-number "Position: "))
      (t (first position))))
    (message "Added Amark %s" name)))

(defsubst ems-file-index (name file-list)
  "Return index of name in file-list."
  (position (expand-file-name name) file-list :test #'string=))

;;;###autoload
(defun emacspeak-m-player-amark-jump ()
  "Jump to specified AMark."
  (interactive)
  (declare (special emacspeak-m-player-file-list))
  (with-current-buffer (process-buffer emacspeak-m-player-process)
    (let* ((amark (call-interactively 'emacspeak-amark-find))
           (files emacspeak-m-player-file-list)
           (current
            (ems-file-index (second (emacspeak-m-player-get-position)) files))
           (new (ems-file-index (emacspeak-amark-path  amark) files)))
      (cond ; move to marked file if found, otherwise load
       ((and current new) ;skip in current play list 
        (emacspeak-m-player-play-tracks-jump (- new current)))
       (t (emacspeak-m-player-dispatch 
           (format "loadfile \"%s\""
                   (shell-quote-argument 
                    (expand-file-name (emacspeak-amark-path amark)))))))
                                        ; now jump to marked position 
      (emacspeak-m-player-seek-absolute (emacspeak-amark-position amark)))))

;;}}}
(provide 'emacspeak-m-player)
;;{{{ end of file 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end: 

;;}}}
