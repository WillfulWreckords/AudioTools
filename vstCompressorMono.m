classdef vstCompressorMono < audioPlugin
    properties
        threshold = -6.0;
        ratio = 5;
        attack = 0;
        release = 0;
        inputGain = 0;
        outputGain = 0;
        autoMakeUp = true;
        kneeWidth = 1;
    end
    
    properties (Constant)
        PluginInterface = audioPluginInterface(...
            audioPluginParameter('inputGain', ...
                'DisplayName', 'Input Giain', ...
                'Label', '(dB)', ...
                'Mapping', {'lin',-120.0,20.0}),...
            audioPluginParameter('threshold', ...
                'DisplayName', 'Threshold', ...
                'Label', '(dB)', ...
                'Mapping', {'lin',-30.0,0.0}),...
            audioPluginParameter('ratio', ...
                'DisplayName', 'Ratio', ...
                'Label', '(input/output)', ...
                'Mapping', {'log',1,1000}),...
            audioPluginParameter('attack', ...
                'DisplayName', 'Attack', ...
                'Label', '(ms)', ...
                'Mapping', {'lin',0,500}),...
            audioPluginParameter('release', ...
                'DisplayName', 'Release', ...
                'Label', '(ms)', ...
                'Mapping', {'lin',0,500}),...
            audioPluginParameter('kneeWidth', ...
                'DisplayName', 'Knee Width', ...
                'Label', '(dB)', ...
                'Mapping', {'lin',0.0,15.0}),...
            audioPluginParameter('outputGain', ...
                'DisplayName', 'Output Gain', ...
                'Label', '(dB)', ...
                'Mapping', {'lin',-120.0,20.0}),...
            audioPluginParameter('autoMakeUp', ...
                'DisplayName', 'Auto Makeup Gain', ...
                'Mapping', {'enum','off','on'}),...
            'PluginName','Compressor (Mono)',...
            'VendorName','Willful Wreckords, LLC',...
            'VendorVersion','1.0.0',...
            'UniqueId','c001',...
            'InputChannels',1,...
            'OutputChannels',1);
    end
    
    properties (Access = private)
        lgain = 1;
    end
    methods
        function out = process(plugin,in)
            
            ig = 10^(plugin.inputGain/20);
            
            tmindB = plugin.threshold-plugin.kneeWidth/2;
            tmaxdB = plugin.threshold+plugin.kneeWidth/2;
            tmin = 10^(tmindB/20);
            tmax = 10^(tmaxdB/20);
            
            % attack and release "per sample decay"
            tatt = plugin.attack * .001;
            trel = plugin.release * .001;
            
            fs = getSampleRate(plugin);
            if tatt==0
                att=0;
            else
                att = exp(-1.0/(fs*tatt));
            end
            if trel==0
                rel=0;
            else
                rel = exp(-1.0/(fs*trel));
            end
            
            %Compute the envelope activation function
            %  This is where we could add some look-ahead/behind if desired
            %  by performing shift on the rms vector
            % 
            %  Also for multi-channel audio we can either compute the mono
            %  rms signal or use each channel independently.
            rms = abs(mean(in,2));
            env = rms;
            
            %Find where the envelope signal is greater than the minimum
            idx = find(env>=tmin);
            cgain = ones(size(in));
            if numel(idx) > 0
                dbe = 20*log10(env(idx));
                s = (1-1/plugin.ratio)*ones(size(dbe));
                ev = (tmindB-dbe);
                if plugin.kneeWidth > 0
                    sidx = (dbe<=tmaxdB);
                    if sum(sidx)>0
                        s(sidx) = s(sidx).*(dbe(sidx)-tmindB)/plugin.kneeWidth/2;
                        ev(~sidx) = plugin.threshold-dbe(~sidx);
                    end
                end
                g = s.*ev;
                for j=1:size(cgain,2)
                    cgain(idx,j) = 10.^(g/20);
                end
            end
           
            %Smooth the computed gain
            if att~=0 || rel~=0
                sgain = cgain;
                if(cgain(1)>plugin.lgain)
                    a = att;
                else
                    a = rel;
                end
                sgain(1) = (1-a)*cgain(1)+a*plugin.lgain;
                
                for i=2:length(rms)
                    if(cgain(i)>cgain(i-1))
                        a = att;
                    else
                        a = rel;
                    end
                    sgain(i) = (1-a)*cgain(i)+a*cgain(i-1);
                end
                cgain = sgain;
            end
            
            %Output gain factor
            if plugin.autoMakeUp
                og = 1/(10.^((1-1/plugin.ratio)*plugin.threshold/40)); 
            else
                og = 10.^(plugin.outputGain/20);
            end
            out = in.*cgain.*ig.*og;
            
            plugin.lgain = cgain(end);
        end
        
        function set.inputGain(plugin, val)
            plugin.inputGain = val;
        end
        
        function set.kneeWidth(plugin, val)
            plugin.kneeWidth = val;
        end
        
        function set.outputGain(plugin, val)
            plugin.outputGain = val;
        end
        
        function set.threshold(plugin, val)
            plugin.threshold = val;
        end
        
        function set.attack(plugin, val)
            plugin.attack = val;
        end
        
        function set.autoMakeUp(plugin, val)
            plugin.autoMakeUp = val;
        end
        
        function set.release(plugin, val)
            plugin.release = val;
        end
        
        %function reset(plugin)
        %    plugin.threshold = -6.0;
        %    plugin.ratio = 5;
        %    plugin.attack = 0;
        %    plugin.release = 0;
        %    plugin.inputGain = 0;
        %    plugin.outputGain = 0;
        %    plugin.autoMakeUp = true;
        %    plugin.kneeWidth = 1;
        %end
    end
end