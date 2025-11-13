fc = 0.2;
N  = 31;

function [coeffs] = fir_window_coeffs(N, fc, w)
    m = -(N-1)/2 : (N-1)/2;
    hd = 2 * fc * sinc(2 * fc * m);
    coeffs = hd(:) .* w(:);
end

w = hamming(N+1);
% coeffs = fir_window_coeffs(N, fc, w);

coeffs = fir1(N, fc, "low", w);
[h, w] = freqz(coeffs, 1, 4096);

figure;
title("Fir1 hamming window magnitude response")
plot(w/pi, abs(h));
saveas(gcf, "../Bilder/1e_fir1_hamming_win_mag.png")
