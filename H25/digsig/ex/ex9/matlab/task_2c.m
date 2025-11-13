num = [0.245  0.245];
den = [1    -0.51];
[h, w] = freqz(num, den, 4096);

figure;
plot(w/pi, 20*log10(abs(h)));
hold on; grid on;

wc = 0.2;
cutoff_db = -3;
plot([0 1], [cutoff_db cutoff_db], 'k--', 'LineWidth', 1);
plot([wc wc], [-80 5], 'k--', 'LineWidth', 1);

ylim([-10 1]);
xlim([0 1]);

xlabel('\omega / \pi');
ylabel('Magnitude (dB)');
title('Magnitude Response of the Digital Lowpass Filter');
saveas(gcf, "../Bilder/2c_mag.png")
