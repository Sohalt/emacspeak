;;;$Id$
;;; emacspeak-finder-inf.el --- keyword-to-package mapping
;; Keywords: help
;;; Commentary:
;;; Don't edit this file.  It's generated by
;;; function emacspeak-finder-compile-keywords
;;; Code:
(require 'cl)

(setq emacspeak-finder-package-info '(
    ("acss-structure.el"
        "CSS -- Cascaded Speech Style structure"
        (emacspeak  audio interface to emacs css))
    ("cd-tool.el"
        "Play  CDs from Emacs"
        nil)
    ("dectalk-voices.el"
        "Define various device independent voices in terms of Dectalk codes."
        (voice  personality  dectalk))
    ("dtk-interp.el"
        "Language specific (e.g. TCL) interface to speech server"
        (tts  dectalk  speech server))
    ("dtk-speak.el"
        "Provides Emacs Lisp interface to speech server"
        (dectalk emacs elisp))
    ("emacspeak-actions.el"
        "Emacspeak actions -- callbacks that can be associated with portions of a buffer"
        (emacspeak  audio interface to emacs actions))
    ("emacspeak-add-log.el"
        "Speech-enable add-log"
        (emacspeak   audio desktop changelogs))
    ("emacspeak-advice.el"
        "Advice all core Emacs functionality to speak intelligently"
        (emacspeak  speech  advice  spoken  output))
    ("emacspeak-alsaplayer.el"
        "Control alsaplayer from Emacs"
        (emacspeak  alsaplayer))
    ("emacspeak-amphetadesk.el"
        "Emacspeak News Portal Interface"
        (emacspeak   audio desktop rss))
    ("emacspeak-analog.el"
        "Speech-enable"
        (emacspeak  analog ))
    ("emacspeak-ansi-color.el"
        "Voiceify ansi-color "
        (emacspeak  ansi-color))
    ("emacspeak-arc.el"
        "Speech enable archive-mode -- a  Emacs interface to zip and friends"
        (emacspeak  speak  spoken output  archive))
    ("emacspeak-atom-blogger.el"
        "Speech-enable atom-blogger"
        (emacspeak   audio desktop atom  blogger))
    ("emacspeak-atom.el"
        "Emacspeak ATOM Wizard"
        (emacspeak   audio desktop atom))
    ("emacspeak-auctex.el"
        "Speech enable AucTeX -- a powerful TeX/LaTeX authoring environment"
        (emacspeak  audio interface to emacs auctex))
    ("emacspeak-aumix.el"
        "Setting Audio Mixer"
        (emacspeak  audio desktop))
    ("emacspeak-autoload.el"
        "Emacspeak Autoload Generator"
        (emacspeak   audio desktop rss))
    ("emacspeak-babel.el"
        "Speech-enable BabelFish"
        (emacspeak  www interaction))
    ("emacspeak-bbdb.el"
        "Speech enable BBDB -- a powerful address manager"
        (emacspeak  audio interface to emacs bbdb ))
    ("emacspeak-bibtex.el"
        "Speech enable bibtex -- Supports maintaining bibliographies in bibtex format"
        (emacspeak  audio interface to emacs  bibtex))
    ("emacspeak-bookmark.el"
        "Speech enable Emacs' builtin bookmarks"
        (emacspeak  speak  spoken output  bookmark))
    ("emacspeak-browse-kill-ring.el"
        "browse-kill-ring  for emacspeak desktop"
        (emacspeak  browse-kill-ring))
    ("emacspeak-bs.el"
        "speech-enable bs buffer selection"
        (emacspeak  audio desktop))
    ("emacspeak-buff-menu.el"
        "Speech enable Buffer Menu Mode -- used to manage buffers"
        (emacspeak  speak  spoken output  buff-menu))
    ("emacspeak-buff-sel.el"
        "Speech enable buf-sel -- an alternative technique for switching buffers"
        (emacspeak  audio interface to emacs interactive buffer selection))
    ("emacspeak-c.el"
        "Speech enable CC-mode and friends -- supports C, C++, Java "
        (emacspeak  audio interface to emacs c  c++))
    ("emacspeak-calc.el"
        "Speech enable the Emacs Calculator -- a powerful symbolic algebra system"
        nil)
    ("emacspeak-calculator.el"
        "Speech enable  desktop calculator"
        (emacspeak  audio desktop))
    ("emacspeak-calendar.el"
        "Speech enable Emacs Calendar -- maintain a diary and appointments"
        (emacspeak  calendar  spoken output))
    ("emacspeak-cedet.el"
        "Speech enable CEDET"
        (emacspeak  speak  spoken output  cedet))
    ("emacspeak-checkdoc.el"
        "Speech-enable checkdoc"
        (emacspeak  speak  spoken output  maintain code ))
    ("emacspeak-cmuscheme.el"
        "Scheme support for emacspeak"
        (emacspeak  cmuscheme))
    ("emacspeak-compile.el"
        "Speech enable  navigation of  compile errors, grep matches"
        (emacspeak compile))
    ("emacspeak-cperl.el"
        "Speech enable CPerl Mode "
        (emacspeak  audio interface to emacs cperl))
    ("emacspeak-cus-load.el"
        "automatically extracted custom dependencies"
        nil)
    ("emacspeak-custom.el"
        "Speech enable interactive Emacs customization "
        (emacspeak  speak  spoken output  custom))
    ("emacspeak-daisy.el"
        "daisy Front-end for emacspeak desktop"
        (emacspeak  daisy digital talking books))
    ("emacspeak-damlite.el"
        "Speech-enable damlite"
        (emacspeak  damlite ))
    ("emacspeak-desktop.el"
        "Speech-enable Emacspeak  desktop "
        (emacspeak   audio desktop  desktop))
    ("emacspeak-dictation.el"
        "Speech enable dictation -- Dictation Interface"
        (emacspeak  speak  spoken output  dictation))
    ("emacspeak-dictionary.el"
        "speech-enable dictionaries "
        (emacspeak  audio desktop))
    ("emacspeak-dired.el"
        "Speech enable Dired Mode -- A powerful File Manager"
        (emacspeak  dired  spoken output))
    ("emacspeak-dismal.el"
        "Speech enable Dismal -- An Emacs Spreadsheet program"
        (emacspeak  audio interface to emacs spread sheets))
    ("emacspeak-dmacro.el"
        "Speech enable DMacro -- Dynamic  Macros "
        (emacspeak  audio interface to emacs dmacro))
    ("emacspeak-ecb.el"
        "speech-enable Emacs Class Browser"
        (emacspeak  ecb))
    ("emacspeak-ediary.el"
        "Speech-enable ediary"
        (emacspeak  diary))
    ("emacspeak-ediff.el"
        "Speech enable Emacs interface to diff and merge"
        (emacspeak  audio interface to emacs  comparing files ))
    ("emacspeak-emms.el"
        "Speech-enable EMMS"
        (emacspeak  multimedia))
    ("emacspeak-enriched.el"
        "Audio Formatting for Emacs' WYSIWYG RichText  mode"
        (emacspeak  audio interface to emacs rich text))
    ("emacspeak-entertain.el"
        "Speech enable misc games"
        (emacspeak  speak  spoken output  games))
    ("emacspeak-eperiodic.el"
        "Speech-enable Periodic Table"
        (emacspeak  periodic  table))
    ("emacspeak-erc.el"
        "speech-enable erc irc client"
        (emacspeak  erc))
    ("emacspeak-eshell.el"
        "Speech-enable EShell - Emacs Shell"
        (emacspeak  audio desktop))
    ("emacspeak-eterm.el"
        "Speech enable eterm -- Emacs' terminal emulator  term.el"
        (emacspeak  eterm  terminal emulation  spoken output))
    ("emacspeak-eudc.el"
        "Speech enable  directory client "
        (emacspeak  audio desktop))
    ("emacspeak-facemenu.el"
        "Map default Emacs faces like bold to appropriate speech personalities "
        (emacspeak  audio interface to emacs rich text))
    ("emacspeak-filtertext.el"
        "Utilities to filter text"
        (emacspeak  audio desktop))
    ("emacspeak-find-dired.el"
        "Speech enable  find-dired"
        (emacspeak  audio desktop))
    ("emacspeak-find-func.el"
        "Speech enable emacs' code finder"
        (emacspeak  find-func))
    ("emacspeak-finder-inf.el"
        nil
        (help))
    ("emacspeak-finder.el"
        "Generate a database of keywords and descriptions for all Emacspeak  packages"
        (emacspeak  finder))
    ("emacspeak-fix-interactive.el"
        "Tools to make  Emacs' builtin prompts   speak"
        (emacspeak  advice  automatic advice  interactive))
    ("emacspeak-flyspell.el"
        "Speech enable Ispell -- Emacs' interactive spell checker"
        (emacspeak  ispell  spoken output  fly spell checking))
    ("emacspeak-folding.el"
        "Speech enable Folding Mode -- enables structured editting"
        (emacspeak  audio interface to emacs folding editor))
    ("emacspeak-forms.el"
        "Speech enable Emacs' forms mode  -- provides  a convenient database interface"
        (emacspeak  audio interface to emacs forms ))
    ("emacspeak-freeamp.el"
        "Control freeamp from Emacs"
        (emacspeak  freeamp))
    ("emacspeak-generic.el"
        "Speech enable  generic modes"
        (emacspeak  audio desktop))
    ("emacspeak-gnuplot.el"
        "speech-enable gnuplot mode"
        (emacspeak  www interaction))
    ("emacspeak-gnus.el"
        "Speech enable GNUS -- Fluent spoken access to usenet"
        (emacspeak  gnus  advice  spoken output  news))
    ("emacspeak-gomoku.el"
        "Speech enable the game of Gomoku"
        (emacspeak  speak  spoken output  gomoku))
    ("emacspeak-gridtext.el"
        "gridtext"
        (emacspeak  gridtext))
    ("emacspeak-gud.el"
        "Speech enable Emacs' debugger interface --covers GDB, JDB, and PerlDB"
        (emacspeak  audio interface to emacs debuggers ))
    ("emacspeak-hide.el"
        "Provides user commands for hiding and exposing blocks of text"
        (emacspeak  speak  spoken output  hide))
    ("emacspeak-hideshow.el"
        "speech-enable hideshow"
        (emacspeak  audio desktop))
    ("emacspeak-hyperbole.el"
        "Speech enable Hyperbole -- A Powerful Information Manager"
        (emacspeak  speech access  hyperbole))
    ("emacspeak-ibuffer.el"
        "speech-enable ibuffer buffer selection"
        (emacspeak  audio desktop))
    ("emacspeak-ido.el"
        "speech-enable ido"
        (emacspeak  audio desktop))
    ("emacspeak-imcom.el"
        "Emacspeak interface to IMCom/Jabber"
        (emacspeak   audio desktop imcom))
    ("emacspeak-imenu.el"
        "Speech enable Imenu -- produce buffer-specific table of contents"
        (emacspeak  speak  spoken output  indices))
    ("emacspeak-info.el"
        "Speech enable Info -- Emacs' online documentation viewer"
        (emacspeak  audio interface to emacs))
    ("emacspeak-ispell.el"
        "Speech enable Ispell -- Emacs' interactive spell checker"
        (emacspeak  ispell  spoken output  ispell version 2.30))
    ("emacspeak-iswitchb.el"
        "speech-enable iswitchb buffer selection"
        (emacspeak  audio desktop))
    ("emacspeak-jabber.el"
        "Speech-Enable jabber "
        (emacspeak  jabber))
    ("emacspeak-jde.el"
        "Speech enable JDE -- An integrated Java Development Environment"
        (emacspeak  speak  spoken output  java))
    ("emacspeak-keymap.el"
        "Setup all keymaps and keybindings provided by Emacspeak"
        (emacspeak))
    ("emacspeak-kmacro.el"
        "Speech-enable kbd macro interface"
        (emacspeak  kmacro ))
    ("emacspeak-kotl.el"
        "Speech enable KOtl -- Hyperbole's outlining editor"
        (emacspeak  speech access  hyperbole  outliner))
    ("emacspeak-load-path.el"
        "Setup Emacs load-path for compiling Emacspeak"
        (emacspeak  speech extension for emacs))
    ("emacspeak-loaddefs.el"
        nil
        nil)
    ("emacspeak-m-player.el"
        "Control mplayer from Emacs"
        (emacspeak  m-player streaming media ))
    ("emacspeak-madplay.el"
        "Control madplay from Emacs"
        (emacspeak  madplay))
    ("emacspeak-make-mode.el"
        "Speech enable make-mode"
        (emacspeak  make))
    ("emacspeak-man.el"
        "Speech enable Man mode -- Use this for UNIX Man pages"
        (emacspeak  audio interface to emacs man ))
    ("emacspeak-message.el"
        "Speech enable Message -- Used to compose news postings and replies"
        (emacspeak  audio interface to emacs posting messages))
    ("emacspeak-metapost.el"
        "speech-enable metapost mode"
        (emacspeak  metapost))
    ("emacspeak-midge.el"
        "Speech-enable MIDI editor"
        (emacspeak  midi ))
    ("emacspeak-mpg123.el"
        "Speech enable MP3 Player"
        (emacspeak  www interaction))
    ("emacspeak-mspools.el"
        "Speech enable MSpools -- Monitor multiple mail drops"
        (emacspeak  speak  spoken output  mspools))
    ("emacspeak-muse.el"
        "Speech-enable Muse"
        (emacspeak   audio desktop muse))
    ("emacspeak-nero.el"
        "Speech-Enable nero (interface to lynx)"
        (emacspeak  nero))
    ("emacspeak-net-utils.el"
        "Speech enable net-utils"
        (emacspeak  network utilities ))
    ("emacspeak-newsticker.el"
        "Speech-enable newsticker"
        (emacspeak  newsticker ))
    ("emacspeak-nxml.el"
        "Speech enable nxml mode"
        (emacspeak  nxml streaming media ))
    ("emacspeak-ocr.el"
        "ocr Front-end for emacspeak desktop"
        (emacspeak  ocr))
    ("emacspeak-oo-browser.el"
        "Speech enable OO Browser -- For Browsing large OO Systems"
        (emacspeak  speech access  browsing source code.))
    ("emacspeak-org.el"
        "Speech-enable org "
        (emacspeak  org ))
    ("emacspeak-outline.el"
        "Speech enable Outline --   Browsing  Structured Documents"
        (emacspeak  audio interface to emacs outlines))
    ("emacspeak-pcl-cvs.el"
        "Speech enabled CVS access "
        (emacspeak  cvs  audio desktop))
    ("emacspeak-perl.el"
        "Speech enable Perl Mode "
        (emacspeak  audio interface to emacs perl))
    ("emacspeak-personality.el"
        nil
        (emacspeak   spoken output  audio formatting))
    ("emacspeak-php-mode.el"
        "Speech-Enable php-mode "
        (emacspeak  php))
    ("emacspeak-preamble.el"
        "standard  include for Emacspeak modules"
        (emacspeak  audio interface to emacs auctex))
    ("emacspeak-pronounce.el"
        "Implements Emacspeak pronunciation dictionaries"
        (emacspeak  audio interface to emacs customized pronunciation))
    ("emacspeak-psgml.el"
        "Speech enable psgml package"
        (emacspeak  audio interface to emacs psgml))
    ("emacspeak-python.el"
        "Speech enable Python development environment"
        (emacspeak  speak  spoken output  python))
    ("emacspeak-re-builder.el"
        "speech-enable re-builder"
        (emacspeak  audio desktop))
    ("emacspeak-realaudio.el"
        "Play realaudio from Emacs"
        (emacspeak  realaudio))
    ("emacspeak-redefine.el"
        "Redefines some key Emacs builtins to speak"
        (emacspeak  redefine  spoken output))
    ("emacspeak-reftex.el"
        "speech enable reftex"
        (emacspeak  reftex))
    ("emacspeak-remote.el"
        "Enables running remote Emacspeak sessions"
        (emacspeak  speak  spoken output  remote server))
    ("emacspeak-replace.el"
        "Speech enable interactive search and replace"
        (emacspeak  speech feedback  query replace (replace.el)))
    ("emacspeak-rmail.el"
        "Speech enable RMail -- Emacs' default mail agent"
        (emacspeak  audio interface to emacs mail))
    ("emacspeak-rpm-spec.el"
        "Speech enable rpm spec editor"
        (emacspeak  rpm-spec streaming media ))
    ("emacspeak-rpm.el"
        "speech-enable RPM"
        (emacspeak  rpm  red hat package manager))
    ("emacspeak-rss.el"
        "Emacspeak RSS Wizard"
        (emacspeak   audio desktop rss))
    ("emacspeak-ruby.el"
        "Speech enable Ruby Mode "
        (emacspeak  audio interface to emacs ruby))
    ("emacspeak-sawfish.el"
        "speech-enable sawfish mode"
        (emacspeak  sawfish interaction ))
    ("emacspeak-ses.el"
        "Speech-enable ses spread-sheet"
        (emacspeak  ses ))
    ("emacspeak-setup.el"
        "Setup Emacspeak environment --loaded to start Emacspeak"
        (emacspeak  setup  spoken output))
    ("emacspeak-sgml-mode.el"
        "Speech enable SGML mode"
        (emacspeak  audio interface to emacs sgml ))
    ("emacspeak-sh-script.el"
        "Speech enable  sh-script mode"
        (emacspeak  audio desktop))
    ("emacspeak-sigbegone.el"
        "Speech-enable sigbegone"
        (emacspeak  sigbegone ))
    ("emacspeak-solitaire.el"
        "Speech enable Solitaire game"
        (emacspeak  speak  spoken output  solitaire))
    ("emacspeak-sounds.el"
        "Defines Emacspeak auditory icons"
        (emacspeak  audio interface to emacs  auditory icons))
    ("emacspeak-speak.el"
        "Implements Emacspeak's core speech services"
        (emacspeak   spoken output))
    ("emacspeak-speedbar.el"
        "Speech enable speedbar -- Tool for context-sensitive navigation"
        (emacspeak  speedbar))
    ("emacspeak-sql.el"
        "Speech enable sql-mode"
        (emacspeak  database interaction))
    ("emacspeak-sudoku.el"
        "Play SuDoku "
        nil)
    ("emacspeak-supercite.el"
        "Speech enable supercite"
        (emacspeak  supercite  mail))
    ("emacspeak-swbuff.el"
        "speech-enable swbuff mode"
        (emacspeak  swbuff))
    ("emacspeak-table-ui.el"
        "Emacspeak's current notion of an ideal table UI"
        (emacspeak  audio interface to emacs tables are structured))
    ("emacspeak-table.el"
        "Implements data model for table browsing"
        (emacspeak  audio interface to emacs tables are structured))
    ("emacspeak-tabulate.el"
        "Interpret tabulated information as a table"
        (emacspeak  tabulated data   visual layout gives structure))
    ("emacspeak-tapestry.el"
        "Speak information about current layout of windows"
        (emacspeak  audio interface to emacs tapestry))
    ("emacspeak-tar.el"
        "Speech enable Tar Mode -- Manipulate tar archives from Emacs"
        (emacspeak  speak  spoken output  tar))
    ("emacspeak-tcl.el"
        "Speech enable TCL development environment"
        (emacspeak  audio interface to emacs tcl))
    ("emacspeak-tdtd.el"
        "Speech enable  DTD authoring "
        (emacspeak  audio desktop))
    ("emacspeak-tempo.el"
        "Speech enable tempo -- template library used for Java and HTML authoring"
        (emacspeak  spoken feedback  template filling  html editing))
    ("emacspeak-tetris.el"
        "Speech enable game of Tetris"
        (emacspeak  speak  spoken output  tetris))
    ("emacspeak-texinfo.el"
        "Speech enable texinfo mode"
        (emacspeak  texinfo))
    ("emacspeak-tnt.el"
        "Instant Messenger "
        (emacspeak  instant messaging ))
    ("emacspeak-todo-mode.el"
        "speech-enable todo-mode"
        (emacspeak  todo-mode ))
    ("emacspeak-url-template.el"
        "Create library of URI templates"
        (emacspeak  audio desktop))
    ("emacspeak-view-process.el"
        "Speech enable View Processes -- A powerful task manager"
        (emacspeak  audio interface to emacs administering processes))
    ("emacspeak-view.el"
        "Speech enable View mode -- Efficient browsing of read-only content"
        (emacspeak  audio interface to emacs  view-mode))
    ("emacspeak-vm.el"
        "Speech enable VM -- A powerful mail agent (and the one I use)"
        (emacspeak  vm  email  spoken output  voice annotations))
    ("emacspeak-w3.el"
        "Speech enable W3 WWW browser -- includes ACSS Support"
        (emacspeak  w3  www))
    ("emacspeak-w3m.el"
        nil
        (emacspeak  w3m))
    ("emacspeak-wdired.el"
        "Speech-enable wdired"
        (emacspeak  multimedia))
    ("emacspeak-websearch.el"
        "search utilities"
        (emacspeak  www interaction))
    ("emacspeak-widget.el"
        "Speech enable Emacs' native GUI widget library"
        (emacspeak  audio interface to emacs customized widgets))
    ("emacspeak-windmove.el"
        "speech-enable windmove "
        (emacspeak  windmove))
    ("emacspeak-winring.el"
        "Speech enable WinRing -- Manage multiple Emacs window configurations"
        (emacspeak  speak  spoken output  winring))
    ("emacspeak-wizards.el"
        "Implements Emacspeak  convenience wizards"
        (emacspeak   audio desktop wizards))
    ("emacspeak-wrolo.el"
        "Speech enable hyperbole's Rolodex"
        (emacspeak  rolodex  spoken output))
    ("emacspeak-xml-shell.el"
        "Implements a simple XML browser"
        (emacspeak   audio desktop xml-shell))
    ("emacspeak-xslide.el"
        "Speech enable  XSL authoring "
        (emacspeak  audio desktop))
    ("emacspeak-xslt-process.el"
        "speech-enable xslt-process "
        (emacspeak  xslt-process))
    ("emacspeak-xslt.el"
        "Implements Emacspeak  xslt transform engine"
        (emacspeak   audio desktop xslt))
    ("emacspeak.el"
        "Emacspeak -- The Complete Audio Desktop"
        (emacspeak  speech  dectalk ))
    ("flite-voices.el"
        "Emacspeak FLite"
        (emacspeak   audio desktop flite))
    ("html-outline.el"
        "Extends html-helper-mode to provide outline and imenu support"
        nil)
    ("outloud-voices.el"
        "Define various device independent voices in terms of OutLoud tags"
        (voice  personality  ibm viavoice outloud))
    ("stack-f.el"
        nil
        (extensions  lisp))
    ("string.el"
        nil
        (extensions  lisp))
    ("tapestry.el"
        nil
        nil)
    ("voice-setup.el"
        "Setup voices for voice-lock"
        nil)
    ("xml-parse.el"
        "code to efficiently read/write XML data with Elisp"
        (convenience languages lisp xml parse data))
    ("xml-sexp.el"
        "Convert XML to S-Expressions"
        (emacspeak  xml ))
))

(loop for l  in (reverse emacspeak-finder-package-info) do
 (push l finder-package-info))
(provide 'emacspeak-finder-inf)

;;; emacspeak-finder-inf.el ends here
