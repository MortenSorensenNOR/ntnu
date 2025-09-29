a = 0.9;
K = 1;

a_coeff = [a -1];
b_coeff = [1 -a];
[H_A, w] = freqz(b_coeff, a_coeff);

H_upper = 1/2 * (1 + H_A);
H_lower = K/2 * (1 - H_A);

figure;
subplot(2,1,1);
plot(w/pi, abs(H_upper));
xlabel('Normalized Frequency (\times\pi rad/sample)');
ylabel('|H_{up}(e^{j\omega})|');
title('Upper branch magnitude (high-pass)');

subplot(2,1,2);
plot(w/pi, abs(H_lower));
xlabel('Normalized Frequency (\times\pi rad/sample)');
ylabel('|H_{low}(e^{j\omega})|');
title('Lower branch magnitude (low-pass)');
grid on;