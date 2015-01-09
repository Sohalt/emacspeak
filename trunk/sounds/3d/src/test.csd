<CsoundSynthesizer>
<CsOptions>
-odac -L stdin 
</CsOptions>
<CsInstruments>sr = 44100
ksmps = 10
nchnls = 2
0dbfs = 1   

instr 1
; p4 is elevation 
kelev = p4 
;p45, p6 are  if1 and if2
; p7,p8 are attack and decay 
kenv  linen   .7, p7, p3, p8
kaz	expon 200, p3, 65		
  ain       pluck     kenv, p5, p6, 0, 3
aleft,aright hrtfmove2 ain, kaz, kelev, "hrtf-44100-left.dat","hrtf-44100-right.dat"	
outs aleft, aright
endin
</CsInstruments>
</CsoundSynthesizer>
