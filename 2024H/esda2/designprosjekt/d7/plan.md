# Designprosjekt 7 -- Anti-aliasing filter

## Filter spesifikasjon
Filteret skal ha en dempning på 10dB ved fs/2, og knekkfrekvensen
fc skal være slik at fc >= 0.75 * fs/2, altså H(fc) = -3dB

Gitt spesifikasjon for fs = 9.1kHz.
Det gir fs/2 = 4.55kHz og fc >= 3.412kHz

## Prinsippiell løsning
Benytter et butterworth lavpassfilter med to andre ordens lavpass
Sallen Key's.

## Realisering
Første steg:
- R1 = 354 = 330 + 22
- R2 = 1.27k = 1.2k + 68 (+18)
- C1 = 22nF
- C2 = 220nF

Andre steg:
- R3 = 1.22k = 1.2k + 18 (+18)
- R4 = 2.69k = 2.2k + 390 + 100
- C3 = 22nF
- C4 = 30nF

Opampen som blir brukt er: LF353P
Datablad: https://www.ti.com/lit/ds/symlink/lf353.pdf?ts=1709921659081&ref_url=https%253A%252F%252Fwww.ti.com%252Fproduct%252FLF353


