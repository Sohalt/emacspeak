<CsoundSynthesizer>
<CsOptions>
  -o ellipses.wav
</CsOptions>
<CsInstruments>
sr		=		44100
;
ksmps=10
nchnls	=		2

gi init 90
		instr 2
kelev line  gi, p3, gi-30
kampenv 	expseg 	.0001, .01, p4, .04, .01
asig 	rand 	kampenv
afilt 	reson 	asig, 1000, 100
aout 	balance 	afilt, asig
aleft,aright hrtfmove2 8*aout, 315,kelev, "hrtf-44100-left.dat","hrtf-44100-right.dat"
		outs 	aleft, aright
        gi = gi -20
		endin

</CsInstruments>
<CsScore>
t 0 150 ; tempo

 i2 0 0.2 4800 
i2 + 0.175 4600 
i2 + 0.125 4500 
i2 + 0.1 4000 
i2 + 0.09 3000 
i2 + 0.06 2000 
</CsScore>
</CsoundSynthesizer>
