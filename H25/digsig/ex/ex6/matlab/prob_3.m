f1 = 7/40;
f2 = 9/40;

N = 100;
n = 0:N-1;
x = sin(2*pi*f1*n) + sin(2*pi*f2*n);

figure;
fft_sizes = [256, 128];
for i = 1:length(fft_sizes)
    X = fft(x, fft_sizes(i));
    X = fftshift(X);
    f = (-fft_sizes(i)/2 : fft_sizes(i)/2-1) / fft_sizes(i);
    
    subplot(2, 1, i);
    plot(f, abs(X));
    xlim([0.0 0.5]);
end

