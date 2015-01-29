<CsoundSynthesizer>
<CsOptions>
-o select-object.wav
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 1
nchnls = 2
0dbfs = 1   

gasig  init 0   
gidel  = 0.05		;delay time in seconds

instr 1
ain  pluck .5, 440, 1000, 0, 1
     outs ain, ain

vincr gasig, ain	;send to global delay
endin

instr 2	

ifeedback = p4	

abuf2	delayr	gidel
adelL 	deltapn	44100		;first tap (on left channel)
adelM 	deltapn	44100		;second tap (on middle channel)
	delayw	gasig + (adelL * ifeedback)

abuf3	delayr	gidel
kdel	line    50, p3, 1	;vary delay time
adelR 	deltapn  100 * kdel	;one pitch changing tap (on the right chn.)
	delayw	gasig + (adelR * ifeedback)*0.5
;make a mix of all deayed signals	
	outs	adelL + adelM, adelR + adelM

clear	gasig
endin

</CsInstruments>
<CsScore>
i 1 0 0.25
i 2 0.01 0.26
e
</CsScore>
</CsoundSynthesizer>
