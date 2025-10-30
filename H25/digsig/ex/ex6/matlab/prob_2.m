Nx = 28;
Nh = 9;
Ny = Nx + Nh - 1;

n  = 0:Nx-1;
x  = 0.9.^(0:Nx-1)';
X  = fft(x, Ny);

h  = ones(Nh, 1);
H  = fft(h, Ny);

y_baseline = conv(x, h); 

figure;
fft_sizes = [Ny/4, Ny/2, Ny, 2*Ny];
for i = 1:length(fft_sizes)
    X  = fft(x, fft_sizes(i));
    H  = fft(h, fft_sizes(i));
    
    subplot(2, 2, i);
    Y = X .* H;
    y = ifft(Y);
    plot(y_baseline); hold on; grid on;
    plot(y);
    legend({'Time convolution', sprintf('Frequency Ny * %d', fft_sizes(i)/Ny)});
end