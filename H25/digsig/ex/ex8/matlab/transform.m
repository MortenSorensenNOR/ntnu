% Parameters
Fs  = 8000;
p   = 10;
NFFT = 4096;

% Load data
matFile = 'vowels.mat';
S = load(matFile);
vowelCell = [];
for fn = fieldnames(S).'
    v = S.(fn{1});
    if iscell(v) && isequal(size(v), [1 9])
        vowelCell = v; break;
    end
end
x_dst = vowelCell{3}(:);

% Load my vowel
x_src = vowelCell{1}(:);

% LPC envelope of 
[a_src,g_src] = lpc(x_src, p);
[a_dst,g_dst] = lpc(x_dst, p);

% inverse-filter source
vowel_flat = filter(a_src, 1, x_src) / sqrt(g_src);

% Synthesize with dst envelope
y = filter(1, a_dst, vowel_flat*sqrt(g_dst));

% Listen
sound(x_src, Fs);
pause(0.5);
sound(x_dst, Fs);
pause(0.5);
sound(y, Fs);
% audiowrite('transformed_vowel.wav', y, Fs);