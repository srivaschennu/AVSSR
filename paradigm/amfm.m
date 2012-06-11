function y = amfm(fs,fc_list,fm_list,len)

%fs - digital audio sampling frequency
%fc_list - carrier frequencies
%fm_list - modulation frequencies (matched one-to-one with carrier fc_list)
%len - duration of audio in seconds

ac = 1; %amplitude of carrier wave with frequency fc
da = 1; %amount of amplitude modulation
df = 0.25; %amount of frequency modulation
sf = 1.1; %amplitude scaling factor

Ts = 1/fs;                     % sampling period
t = 0:Ts:len-Ts;               % time vector

theta = 0; %phase shift of FM relative to AM
phi = theta*pi/180;

y = zeros(length(t),1);

for i = 1:length(fc_list)
    fc = fc_list(i);
    fm = fm_list(i);
    beta = (df*fc)/(2*fm); %modulation index of FM
    y_t = ac.*(1 + da*cos(2*pi*fm*t)) .* (cos(2*pi*fc*t + beta*sin(2*pi*fm*t + phi))) / sqrt(1 + (da^2)/2);
    y(:) = y(:) + y_t';
end
y = y ./ (max(abs(y)) * sf);

%fade-in and fade-out
fadelen = 0.01; %seconds
fadelen = round(fadelen * fs);
fadevec = linspace(0,1,fadelen)';
y(1:length(fadevec)) = y(1:length(fadevec)) .* fadevec;
y(end-length(fadevec)+1:end) = y(end-length(fadevec)+1:end) .* fadevec(end:-1:1);