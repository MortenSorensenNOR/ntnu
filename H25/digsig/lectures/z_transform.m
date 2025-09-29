B     = fircls1(0.9);
A     = [1];
[H,W] = freqz(B,A); plot(W/pi,abs(H));

% zplane(B,A);