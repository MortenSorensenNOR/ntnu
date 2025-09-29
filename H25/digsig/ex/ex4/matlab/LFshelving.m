clear all
alpha=0.9;
K=3;
wavfile='pluto.wav';

[x,fs]=audioread(wavfile);
fs

B(1)= (K/2)*(1-alpha)+(1/2)*(1+alpha);
B(2)= (K/2)*(1-alpha)-(1/2)*(1+alpha);
A = [1, -alpha];

y = filter(B,A,x);
%disp('Playing *original* sound clip')
%soundsc(x,fs);  % play original sound
%input('Press a key to continue...')
%disp('Playing *filtered* sound clip')
%soundsc(y,fs);  % play filtered sound
%fs

figure
[H,W]=freqz(B,A,1024);
normFreq = [0:1/(length(H)-1):1];
plot(normFreq,20*log10(abs(real(H))));
title(['Frequency response, alpha=',num2str(alpha), ' K=',num2str(K)]);
xlabel('Normalized frequency');
ylabel('Magnitude [dB]');
saveas(gcf, '../Bilder/3c.png');   % saves current figure as PNG