classdef HRVFeature
    properties
    end
    methods(Static)
        % Time Domain Features
        function r = AVNN(rr)
            r = mean(rr);
        end
        function r = SDNN(rr)
            r = std(rr);
        end
        function r = RMSSD(rr_diff)
            r = sqrt(mean(rr_diff.^2));
        end
        function r = SDSD(rr_diff)
            r = std(rr_diff);
        end
        function r = NNx(x, rr_diff)
            r = sum((rr_diff*1000)>x);
        end
        function r = PNNx(NNx, rr_size)
            r = (NNx/(rr_size-1))*100;
        end
        
        % Geometrical Features
        function r = HRV_TRIANGULAR_IDX(rr)
            bin_size = 7.812;
            rr = rr.*1000;
            max_val = max(rr);
            min_val = min(rr);
            bin_count = ceil((max_val-min_val)/bin_size);
            % generate edges
            edges = zeros(bin_count+1, 1);
            edges(1) = min_val;
            for i=2:bin_count+1
                edges(i) = edges(i-1) + bin_size;
            end
            % calculate histogram
            N = histcounts(rr, edges);
            % calculate hrv triangular index
            r = max(N)/sum(N);
        end
        
        % Poincare Features
        function r = SD1(sdsd)
            r = (sdsd^2)/2;
        end
        function r = SD2(sdnn, sdsd)
            r = 2*(sdnn^2)-(sdsd^2)/2;
        end
        function r = SD1_SD2_RATIO(sd1, sd2)
            r = sd1/sd2;
        end
        function r = S(sd1, sd2)
            r = pi*sd1*sd2;
        end
        
        % Frequency Domain Features
        function [TP,pLF,pHF,LFHFratio,VLF,LF,HF,f,Y,NFFT] = ...
                fft_val_fun(RR,Fs,type)
        %function source: https://marcusvollmer.github.io/HRV/
        %fft_val_fun Spectral analysis of a sequence.
        %   [pLF,pHF,LFHFratio,VLF,LF,HF,f,Y,NFFT] = fft_val_fun(RR,Fs,type)
        %   uses FFT to compute the spectral density function of the interpolated
        %   RR tachogram.  The density of very low, low and high frequency parts
        %   will be estimated.
        %   RR is a vector containing RR intervals in seconds.
        %   Fs specifies the sampling frequency.
        %   type is the interpolation type. Look up interp1 function of Matlab for
        %   accepted types (default: 'spline').
        %
        %   Example: If RR = repmat([1 .98 .9],1,20),
        %      then [pLF,pHF,LFHFratio,VLF,LF,HF] = HRV.fft_val_fun(RR,1000) 
        %      yields pLF = 5.4297 and pHF = 94.5703 and pHFratio = 0.0574 and
        %      VLF = 0.0505 and LF = 0.1749 and HF = 3.0467.
        %      [pLF,pHF,LFHFratio] = HRV.fft_val_fun(RR,1000,'linear') yields
        %      pLF = 4.0484 and pHF = 95.9516 and LFHFratio = 0.0422.
        %
        %   See also INTERP1, FFT.

            RR = RR(:);
            if nargin<2 || isempty(Fs)
                error('fft_val_fun: wrong number or types of arguments');
            end
            if nargin<3
                type = 'spline';
            end

            switch type
                case 'none'
                    RR_rsmp = RR;
                otherwise
                    if sum(isnan(RR))==0 && length(RR)>1
                        ANN = cumsum(RR)-RR(1);
                        % use interp1 methods for resampling
                        RR_rsmp = interp1(ANN,RR,0:1/Fs:ANN(end),type);
                    else
                        RR_rsmp = [];
                    end
            end

            % FFT
            L = length(RR_rsmp); 

            if L==0 
                pLF = NaN;
                pHF = NaN;
                LFHFratio = NaN;
                VLF = NaN;
                LF = NaN;
                HF = NaN;
                f = NaN;
                Y = NaN;
                NFFT = NaN;
            else
                NFFT = 2^nextpow2(L);
                Y = fft(HRVFeature.nanzscore(RR_rsmp),NFFT)/L;
                f = Fs/2*linspace(0,1,NFFT/2+1);  

                YY = 2*abs(Y(1:NFFT/2+1));

                VLF = sum(YY(f<=.04));
                LF = sum(YY(f<=.15))-VLF;  
                HF = sum(YY(f<=.4))-VLF-LF;
                TP = sum(YY(f<=.4));

                pLF = LF/(TP-VLF)*100;
                pHF = HF/(TP-VLF)*100;    
                LFHFratio = LF/HF;
            end
        end
        function [z,m,s] = nanzscore(x,opt,varargin)
        %function source: https://marcusvollmer.github.io/HRV/
            if (nargin < 3) % check input
                dim = find(size(x)>1,1);
                if isempty(dim)
                    dim = 1;
                end
            else
                dim = varargin{1};
            end

            if (nargin < 2) || isempty(opt)
                opt = 0;
            end

            % compute mean value(s) and standard deviation(s)
            m = HRVFeature.nanmean(x,dim);
            s = HRVFeature.nanstd(x,opt,dim);    
            % computer z scores
            z = (x-repmat(m,size(x)./size(m)))./repmat(s,size(x)./size(s));
        end
        function m = nanmean(x, varargin)
        %function source: https://marcusvollmer.github.io/HRV/
            if (nargin < 2) % check input
                dim = find(size(x)>1,1);
                if isempty(dim)
                    dim = 1;
                end
            else
                dim = varargin{1};
            end

            % determine number of regular (not nan) data points
            n = sum(not(isnan(x)),dim);

            % replace nans with zeros and compute mean value(s)
            x(isnan(x)) = 0;
            n(n==0) = nan;
            m = sum(x,dim)./n;
        end
        function s = nanstd(x, opt, varargin)
        %function source: https://marcusvollmer.github.io/HRV/
            if (nargin < 3) % check input
                dim = find(size(x)>1,1);
                if isempty(dim)
                    dim = 1;
                end
            else
                dim = varargin{1};
            end

            if (nargin < 2) || isempty(opt)
                opt = 0;
            end

            % determine number of regular (not nan) data points and nans
            n = sum(not(isnan(x)),dim);
            nnan = sum(isnan(x),dim);

            % replace nans with zeros,
            % remove mean value(s) and compute squared sums
            x(isnan(x)) = 0;
            m = sum(x, dim)./n;
            x = x-repmat(m, size(x)./size(m));
            s = sum(x.^2, dim);

            % remove contributions of added zeros
            s = s-(m.^2).*nnan;

            % normalization
            if (opt == 0)
                s = sqrt(s./max(n-1,1));
            elseif (opt == 1)
                s = sqrt(s./n);
            else
                error('nanstd: unkown normalization type');
            end
        end        
    end
end