function Y = plotfft(y,Fs,xlim,ylim)
L = length(y);

Y = fft(y);
Y = 2*abs(Y(1:L/2+1))/L;

f = Fs/2*linspace(0,1,L/2+1);

if exist('xlim','var') || exist('ylim','var')
    figure;
    plot(f,Y,'LineWidth',2);
    title('FFT');
    xlabel('Frequency (Hz)');
    ylabel('|Y(f)|');
    if ~isempty(xlim)
        set(gca,'XLim',xlim);
    end
    if ~isempty(ylim)
        set(gca,'YLim',ylim);
    end
end
box on
grid on