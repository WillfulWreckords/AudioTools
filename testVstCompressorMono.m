x = randn(1000,1); 
x = audioread('mesa_dual_recto_reference.wav');

cmp = vstCompressorMono();

cmp.kneeWidth = 0;
cmp.attack = 0;
cmp.release = 0;
cmp.threshold = -6;
cmp.inputGain = 0; 
cmp.outputGain = 0;
cmp.ratio = 10;
y = cmp.process(x);
 
cmp.kneeWidth = 6;
cmp.attack = 0;
cmp.release = 0;
cmp.threshold = -6;
cmp.inputGain = 0;
cmp.outputGain = 0;
cmp.ratio = 10;
y1 = cmp.process(x);

figure(1);
plot(20*log10(abs(x)),20*log10(abs(y)),'.');
hold on;
plot(20*log10(abs(x)),20*log10(abs(y1)),'r.');
hold off;
xlim([-20,0]); 
ylim([-20,0]); 
axis square; 
grid minor;
drawnow;

cmp.kneeWidth = 6;
cmp.attack = 0;
cmp.release = 0;
cmp.threshold = -10;
cmp.inputGain = 0;
cmp.outputGain = 0;
cmp.ratio = 1000;
y2 = cmp.process(x);

cmp.kneeWidth = 6;
cmp.attack = 3;
cmp.release = 30;
cmp.threshold = -10;
cmp.inputGain = 0;
cmp.outputGain = 0;
cmp.ratio = 1000;
y3 = cmp.process(x);

figure(2);
plot(x,'r');
hold on;
plot(y2,'g');
plot(y3,'b');
hold off;
legend('x','y2','y3');
drawnow;

%Validate the plugin
validateAudioPlugin vstCompressorMono

%generate the VST plugin
generateAudioPlugin vstCompressorMono

%Move to system plugin folder
copyfile('vstCompressorMono.vst','~/Library/Audio/Plug-Ins/VST/WWRKDS/vstCompressorMono.vst');
