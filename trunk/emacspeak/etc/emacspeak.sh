#!/bin/sh
# emacspeak - execute emacs with speech enhancements
#$Id$
    if [ -f /etc/emacspeak.conf ]
    then
    . /etc/emacspeak.conf
fi

if [ -e $HOME/.emacs ]
then
	INITSTR="-l $HOME/.emacs"
fi

CL_ALL=""
for CL in $* ; do
	if [ "$CL" = "-o" ]; then
		DTK_PROGRAM=outloud
		export DTK_PROGRAM
	elif [ "$CL" = "-m" ]; then
		DTK_PROGRAM=mbrola
		export DTK_PROGRAM
	elif [ "$CL" = "-q" ]; then
		INITSTR=""
	else
		CL_ALL="$CL_ALL $CL"
	fi
done


EMACS_UNIBYTE=1
export EMACS_UNIBYTE
exec emacs -q -l /home/tvraman/emacs/lisp/emacspeak/lisp/emacspeak-setup.el $INITSTR $CL_ALL
