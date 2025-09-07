B     = fircls1(8,0.3,0.02,0.008);
A     = [1];
[H,W] = freqz(B,A); plot(W/pi,abs(H));

% zplane(B,A);