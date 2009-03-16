;;; emacspeak-amark.el --- BookMarks For Audio Content
;;; $Id: acss-structure.el 5798 2008-08-22 17:35:01Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description: Bookmarks for audio content like mp3
;;; Keywords:emacspeak, audio interface to emacs MP3
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-08-25 18:28:19 -0700 (Sat, 25 Aug 2007) $ |
;;;  $Revision: 4532 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;;Copyright (C) 1995 -- 2007, T. V. Raman 
;;; Copyright (c) 1996 by T. V. Raman
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

;;; Commentary:

;;; Structure emacspeak-amark holds a bookmark into an mp3 file
;;; path: fully qualified pathname  to file being marked
;;; name: Bookmark tag
;;; Position: time offset from start 

;;;; This library will be used from emacspeak-m-player,
;;emacspeak-alsaplayer and friends to set and jump to bookmarks.

;;}}}
;;{{{  Required modules

;;; Code:
(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))

;;}}}
;;{{{ Structure:

(defstruct emacspeak-amark
  path ; fully qualified pathname
  name ; Bookmark tag
  position ; Offset in ms from start
)

;;}}}

(provide  'emacspeak-amark)
;;{{{  emacs local variables

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
