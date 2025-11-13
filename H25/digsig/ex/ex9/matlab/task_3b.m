num = 1;
den = [1 sqrt(2) 1];

w = linspace(0, pi, 4096);
[h, w] = freqs(num, den, w);

