% Load sound file
[x, fs] = audioread("pianoise.wav");

% Load minimum order filter
num = minimum_order_num;

% Filter
y = filter(minimum_order_num, 1, x);
sound(y, fs);
pause(1.5);