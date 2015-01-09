<CsoundSynthesizer>
<CsOptions>
-odac -L stdin 
</CsOptions>
<CsInstruments>sr = 44100
ksmps = 10
nchnls = 2
0dbfs = 1   

instr 1
kenv  linen   .7, p6, p3, p7
kp line p4, p3, p5
  ain       pluck     kenv,kp, 440, 0, 3
outs ain, ain 
endin
</CsInstruments>
</CsoundSynthesizer>
