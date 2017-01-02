classdef vstCompressorMono < audioPlugin
    properties
        threshold = -6.0;
        ratio = 5;
        attack = 0;
        release = 0;
        inputGain = 0;
        outputGain = 0;
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
                'Mapping', {'lin',-120.0,0.0}),...
            audioPluginParameter('ratio', ...
                'DisplayName', 'Ratio', ...
                'Label', '(input/output)', ...
                'Mapping', {'log',1,100000}),...
            audioPluginParameter('attack', ...
                'DisplayName', 'Attack', ...
                'Label', '(ms)', ...
                'Mapping', {'lin',0,5000}),...
            audioPluginParameter('release', ...
                'DisplayName', 'Release', ...
                'Label', '(ms)', ...
                'Mapping', {'lin',0,5000}),...
            audioPluginParameter('kneeWidth', ...
                'DisplayName', 'Knee Width', ...
                'Label', '(dB)', ...
                'Mapping', {'lin',0.0,15.0}),...
            audioPluginParameter('outputGain', ...
                'DisplayName', 'Output Giain', ...
                'Label', '(dB)', ...
                'Mapping', {'lin',-120.0,20.0}),...
            'PluginName','Compressor (Mono)',...
            'VendorName','Willful Wreckords, LLC',...
            'VendorVersion','1.0.0',...
            'UniqueId','c001',...
            'InputChannels',1,...
            'OutputChannels',1);
    end
    methods
        function out = process(plugin,in)
            
            out = in*10^(plugin.inputGain/20);
            
            tdB = plugin.threshold;
            threshold = 10^(tdB/20);
            
            kneeWidth = plugin.kneeWidth;
            tmindB = tdB-kneeWidth/2;
            tmaxdB = tdB+kneeWidth/2;
            tmin = 10^(tmindB/20);
            tmax = 10^(tmaxdB/20);
            
            ratio = plugin.ratio;
            
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
            rms = abs(out);
            env = rms;
            if att~=0 || rel~=0
                for i=2:length(rms)
                        if(rms(i)>tmin)
                            a = att;
                        else
                            a = rel;
                        end
                    env(i) = (1-a)*rms(i)+a*env(i-1);
                end
            end

            %Find where the envelope signal is greater than the minimum
            idx = find(env>=tmin);
            cgain = ones(size(out));
            dbe = 20*log10(env(idx));
            s = (1-1/ratio)*ones(size(dbe));
            ev = (tmindB-dbe);
            if kneeWidth > 0
                sidx = dbe<=tmaxdB;
                s(sidx) = s(sidx).*(dbe(sidx)-tmindB)/kneeWidth/2;
                ev(~sidx) = tdB-dbe(~sidx);
            end
            g = s.*ev;
            cgain(idx) = 10.^(g/20);

            %Output gain factor
            og = 10.^(plugin.outputGain/20);
            
            out = out.*cgain.*og;
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
        
        function set.release(plugin, val)
            plugin.release = val;
        end    
    end
end