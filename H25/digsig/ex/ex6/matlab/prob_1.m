N = 28;
n = 0:N-1;
x = 0.9.^(0:N-1);

% DTFT
f_dense      = linspace(0, 1, 4000); 
E            = exp(-1j*2*pi*(n.').*f_dense);
X_dtft       = x * E;

% Shift frequencies so that the last half is the negative frequencies
Xs = fftshift(X_dtft);
fs = fftshift(f_dense);
fs(fs >= 0.5) = fs(fs >= 0.5) - 1;  % map to [-0.5, 0.5)

fft_points = [N/4, N/2, N, 2*N];
figure;
for i = 1:length(fft_points)
    X = fft(x, fft_points(i));
    X_shifted = fftshift(X);
    f = (-fft_points(i)/2 : fft_points(i)/2 - 1) / fft_points(i);
    
    subplot(2, 2, i);
    plot(fs, abs(Xs)); hold on; grid on;
    stem(f, abs(X_shifted));
    xlim([-0.5 0.5]);
end