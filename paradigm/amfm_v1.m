function y = amfm(fs,fc,fm,len)

ac = 1; %amplitude of carrier wave with frequency fc
da = 1; %amount of amplitude modulation
df = 0.25; %amount of frequency modulation
sf = 1.1; %downscale factor

Ts = 1/fs;                     % sampling period
t = 0:Ts:len-Ts;               % time vector

beta = (df*fc)/(2*fm); %modulation index of FM
theta = 0; %phase shift of FM relative to AM
phi = theta*pi/180;

y = zeros(length(t),1);
y(:) = ac.*(1 + da*cos(2*pi*fm*t)) .* (cos(2*pi*fc*t + beta*sin(2*pi*fm*t + phi))) / sqrt(1 + (da^2)/2);
y = y ./ (max(abs(y)) * sf);