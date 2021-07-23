%% Co2 and o2 shifting for CVR

% CAO and BORZAGE 2019 10 23

%% data requirements:
% CO2 'RAW' signals where the 'SIGNAL' (low passed to keep gas challenge and breathing data, peak-to-peak max)
% and 'NOISE' (raw-SIGNAL RMS value) have SNR> XXX

% O2 'RAW' signals where the 'SIGNAL' (low passed to keep gas challenge and breathing data, peak-to-peak max)
% and 'NOISE' (raw-SIGNAL RMS value) have SNR> XXX

% BOLD 'RAW' signals where the 'SIGNAL' (low passed to keep gas challenge and breathing data, peak-to-peak max)
% and 'NOISE' (raw-SIGNAL RMS value) have SNR> XXX

% Outputs:
% O2, Co2 shifts (seconds)
% r-values for O2 and CO2
% graphs for Raw bold, Co2, o2, and any processed versions of BOLD, Co2, O2
% graphs of cross correlation of BOLD-Co2 and BOLD-O2, and BOLD-(Processed)
% quality metrics for CO2, O2 and BOLD 


% Outcome Metrics
% A Co2 and o2 signals (or Co2-E and o2-E signals) with lag of less than XXX
% points, AND
% JIMI CHECK B Co2 Lag less than o2 Lag (with some small allowable error) , AND
% C.1 either both [Co2 & o2] Correlation coefficients each above 40%, OR
% C.2 both [Co2-Processed & o2-Processed] Correlation coefficients above 80%

%% Overview
% 0 Load Data, Prepare for Looping (1-8)
% 1 Get Signal
% 3 Processing signals Matt: Calculate Envelopes of Signal, JIMI: FFT filtered version of signals
% 4 Interpolate Bold Signal
% 5 Perform Cross Correlation of Signals, and Envolopes
% 5.2 shift the data by the amount proscribed in raw
% 5.3 cinterpolate everything back to bold original & compute R and p values
% 6 Quality metric
% 7 Plot Results
% 7.1 Raw BOLD, Co2, o2 -Co2-E, o2-E
% 7.2 Xcorr BOLD-Co2, BOLD-o2,  BOLD-Co2-E, BOLD-o2-E,
% 7.3 Adjusted BOLD+Co2+o2, Adjusted BOLD+Co2-E+o2-E
% 8 Package Results





%% 0 Load Data, Prepare for looping
parameters.lowess_filter=0.05; % percent of data to smooth and subtract as a baseline correction in running average
parameters.estimated_resp=700; % units are data points, this was emperitcal and intended to surpress breath-to-breath variation
parameters.verbose=1; % 1 turns on graphing
parameters.printer=0; % 1 turns on printing, if a printer is installed
parameters.snr_cutoff=45; % units are data points. this is intended to retain breath-to-breath variations
parameters.gas_path='C:\Users\User\Desktop\cvr_gas';
parameters.bold_path='C:\Users\User\Desktop\all_bold';
parameters.max_shift=50; % plus or minus based on the histogram of the differences, which indicated descrete changes of unis of 100.
parameters.export_path='C:\Users\User\Desktop\shifted_export';
    
% configure the output table 'results'
temp_name=nan;
co2_corr=nan;
o2_corr =nan;
co2_shift=nan;
o2_shift=nan;
o2_quality=nan;
co2_quality=nan;
bold_quality=nan;

if not(exist('results'))
    results=table(temp_name,co2_corr,o2_corr,co2_shift,o2_shift,co2_quality,o2_quality,bold_quality);
    clear temp_name co2_corr o2_corr co2_shift o2_shift co2_quality o2_quality bold_quality
end

% look for files
filenames=dir(parameters.gas_path);
filenames=filenames(~ismember({filenames.name},{'.','..'}));

% loop through all files. Note that the filenames have not been scrubbed
% clean.

output_redo=[];
for index=1:length(filenames)
    disp(['running: ', num2str(index) '/' num2str(length(filenames))])
    try
    %% 1 Get Signal
    try
        
    try
    gas.raw=load([parameters.gas_path filesep filenames(index).name]);
    catch
        disp(['Gas'])
    end
    
    try
    % BOLD
    bold.raw=xlsread([parameters.bold_path filesep ,filenames(index).name(1:2),filenames(index).name(4:end-4),'.xlsx']);
    bold.raw_time=bold.raw(:,1); %time in seconds
    bold.raw_bold=bold.raw(:,2);
    catch
        disp(['BOLD'])
    end
    
    % gas Time
    gas.raw_time=gas.raw(:,1)*60; % converts to time in seconds
    % Co2
    gas.raw_co2=gas.raw(:,3);
    % o2
    gas.raw_o2 =gas.raw(:,2);
    catch
        disp(['Part1'])
    end
    
    %% 2 Processing signals Matt: Calculate Envelopes of Signal, JIMI: FFT filtered version of signals
    [gas.upper_co2,gas.lower_co2] = envelope(gas.raw_co2,parameters.estimated_resp,'peak');
    [gas.upper_o2 ,gas.lower_o2 ] = envelope(gas.raw_o2,parameters.estimated_resp,'peak');
    %[gas.upper_co2,gas.lower_co2] = envelope(gas.raw_co2);
    
%     if parameters.verbose==1
%         figure
%         title([filenames(index).name(1:end-4) ' Envelope Functions'])
%         subplot(1,3,1)
%         plot(gas.raw_time,gas.raw_co2,':r',gas.raw_time,gas.lower_co2,'or',gas.raw_time,gas.upper_co2,'or')
%         subplot(1,3,2)
%         plot(gas.raw_time,gas.raw_o2,':g', gas.raw_time,gas.lower_o2 ,'og',gas.raw_time,gas.upper_o2 ,'og')
%         if parameters.printer==1
%             print
%         end
%         
%     end
%     
    %% 3 Interpolate Bold Signal
    
    bold.interp_time=bold.raw_time(1):median(diff(gas.raw_time)):bold.raw_time(end);
    
    bold.interp_bold=interp1(bold.raw_time,bold.raw_bold,bold.interp_time);
    
%     if parameters.verbose==1
%         figure
%         subplot(1,2,1)
%         title([filenames(index).name(1:end-4) ' BOLD interpolation'])
%         plot(bold.raw_time,bold.raw_bold,'-b')
%         subplot(1,2,2)
%         plot(bold.interp_time,bold.interp_bold,'-b')
%         if parameters.printer==1
%             print
%         end
%         
%     end
   
    
    
    %% 5 Perform Cross Correlation of Signals, and Envolopes
    % Save lag/correlation coefficients
    
    [C_bold_raw_co2  ,LAGS_bold_raw_co2  ] = xcorr(bold.interp_bold-mean(bold.interp_bold),gas.raw_co2-mean(gas.raw_co2));
    [C_bold_upper_co2,LAGS_bold_upper_co2] = xcorr(bold.interp_bold-mean(bold.interp_bold),gas.upper_co2-mean(gas.upper_co2));
    [C_bold_lower_co2,LAGS_bold_lower_co2] = xcorr(bold.interp_bold-mean(bold.interp_bold),gas.lower_co2-mean(gas.lower_co2));
    [C_bold_raw_o2   ,LAGS_bold_raw_o2   ] = xcorr(bold.interp_bold-mean(bold.interp_bold),gas.raw_o2-mean(gas.raw_o2));
    [C_bold_upper_o2 ,LAGS_bold_upper_o2 ] = xcorr(bold.interp_bold-mean(bold.interp_bold),gas.upper_o2-mean(gas.upper_o2));
    [C_bold_lower_o2 ,LAGS_bold_lower_o2 ] = xcorr(bold.interp_bold-mean(bold.interp_bold),gas.lower_o2-mean(gas.lower_o2));
    
    
    %% apply windowing on the raw upper and lower to limit their max shift
    
    center=round(length(C_bold_raw_co2)/2);
    interp_max_shift=round(parameters.max_shift.*length(bold.interp_bold)/length(bold.raw));
    C_bold_raw_co2([1:center-interp_max_shift center+interp_max_shift:end] )=0;
    C_bold_upper_co2([1:center-interp_max_shift center+interp_max_shift:end] )=0;
    C_bold_lower_co2([1:center-interp_max_shift center+interp_max_shift:end] )=0;
    C_bold_raw_o2([1:center-interp_max_shift center+interp_max_shift:end] )=0;
    C_bold_upper_o2([1:center-interp_max_shift center+interp_max_shift:end] )=0;
    C_bold_lower_o2([1:center-interp_max_shift center+interp_max_shift:end] )=0;  
    %%
    
    if parameters.verbose==1
        figure
        
        subplot(1,2,1)
        title([filenames(index).name(1:end-4) ' Correlation CO_2'])
        hold on
        plot(LAGS_bold_raw_co2,C_bold_raw_co2,'-')
        plot(LAGS_bold_upper_co2,C_bold_upper_co2,'-.')
        plot(LAGS_bold_lower_co2,C_bold_lower_co2,':')
        
        plot(LAGS_bold_raw_co2(find(C_bold_raw_co2==max(C_bold_raw_co2))),  max(C_bold_raw_co2),'o');
        plot(LAGS_bold_upper_co2(find(C_bold_upper_co2==max(C_bold_upper_co2))),max(C_bold_upper_co2),'o');
        plot(LAGS_bold_lower_co2(find(C_bold_lower_co2==max(C_bold_lower_co2))),max(C_bold_lower_co2),'o');
        
        legend('Raw','Upper','Lower')
        
        subplot(1,2,2)
        title([filenames(index).name(1:end-4) ' Correlation O_2'])
        hold on
        plot(LAGS_bold_raw_o2,C_bold_raw_o2,'-')
        plot(LAGS_bold_upper_o2,C_bold_upper_o2,'-.')
        plot(LAGS_bold_lower_o2,C_bold_lower_o2,':')
        
        
        plot(LAGS_bold_raw_o2(find(C_bold_raw_o2==max(C_bold_raw_o2))),  max(C_bold_raw_o2),'o');
        plot(LAGS_bold_upper_o2(find(C_bold_upper_o2==max(C_bold_upper_o2))),max(C_bold_upper_o2),'o');
        plot(LAGS_bold_lower_o2(find(C_bold_lower_o2==max(C_bold_lower_o2))),max(C_bold_lower_o2),'o');
        
        legend('Raw','Upper','Lower')
        if parameters.printer==1
            print
        end
        
    end
    
    % 5.2 shift the data by the amount proscribed in raw
    gas.co2_shift=median(diff(gas.raw_time))*(LAGS_bold_raw_co2(find(C_bold_raw_co2==max(C_bold_raw_co2))));
    gas.o2_shift =median(diff(gas.raw_time))*(LAGS_bold_raw_o2(find(C_bold_raw_o2==max(C_bold_raw_o2))));
    gas.shift_time_co2=gas.raw_time+gas.co2_shift;
    gas.shift_time_o2 =gas.raw_time+gas.o2_shift;
    
    
    
    % 5.3 cinterpolate everything back to bold original & compute R and p values
    
    % time_last_start=max([gas.shift_time_co2(1) gas.shift_time_o2(1) bold.interp_time(1)]);
    % time_first_end =min([gas.shift_time_co2(end) gas.shift_time_o2(end) bold.interp_time(end)]);
    
    gas.final_co2=interp1(gas.shift_time_co2,gas.raw_co2,bold.raw_time,'nearest','extrap');
    gas.final_o2 =interp1(gas.shift_time_o2 ,gas.raw_o2, bold.raw_time,'nearest','extrap');

    [r, p]=corrcoef(bold.raw_bold,gas.final_co2);
    gas.co2_corr=r(1,2);
    gas.co2_p=p(1,2);
    
    clear r p
    [r, p]=corrcoef(bold.raw_bold,gas.final_o2);
    gas.o2_corr=r(1,2);
    gas.o2_p=p(1,2);
    
    clear r p
    
    
    if parameters.verbose==1
        figure
        plot(gas.shift_time_co2,gas.raw_co2,'r',gas.shift_time_o2,gas.raw_o2,'g',bold.interp_time,bold.interp_bold,'b');
        
        subplot(3,1,1)
        
        plot(gas.raw_time,gas.raw_co2,'r',gas.raw_time,gas.raw_o2,'g',bold.interp_time,bold.interp_bold,'b');
        xlim([gas.raw_time(1)-50 gas.raw_time(end)+50])
        legend('CO_2','O_2','BOLD')
        title([filenames(index).name(1:end-4) ' Raw Time Series'])
        
        subplot(3,1,2)
        plot(gas.shift_time_co2,gas.raw_co2,'r',gas.shift_time_o2,gas.raw_o2,'g',bold.interp_time,bold.interp_bold,'b');
        xlim([gas.raw_time(1)-50 gas.raw_time(end)+50])
        legend('CO_2','O_2','BOLD')
        title([filenames(index).name(1:end-4) ' Shifted Time Series'])
        
        subplot(3,1,3)
        plot(bold.raw_time,gas.final_co2,'r',bold.raw_time,gas.final_o2,'g',bold.raw_time,bold.raw_bold,'b');
        xlim([gas.raw_time(1)-50 gas.raw_time(end)+50])
        text(gas.raw_time(1),40,['CO_2 Shift: ',num2str(gas.co2_shift)])
        text(gas.raw_time(1),80,[ 'O_2 Shift: ',num2str(gas.o2_shift)])
        legend(['CO_2 r:' num2str(gas.co2_corr)],['O_2 r:' num2str(gas.o2_corr)],'BOLD')
        title([filenames(index).name(1:end-4) ' Final Time Series'])
        if parameters.printer==1
            print
        end
        
    end
    %% 6 Quality metric
     bold.bold_smoothed=smooth(bold.raw_time,bold.raw_bold,parameters.snr_cutoff,'lowess');
     gas.co2_smoothed  =smooth(gas.raw_time, gas.raw_co2  ,parameters.snr_cutoff,'lowess');
     gas.o2_smoothed   =smooth(gas.raw_time, gas.raw_o2   ,parameters.snr_cutoff,'lowess');
%     
    bold.bold_quality=peak2peak(bold.bold_smoothed) /rms(bold.raw_bold-bold.bold_smoothed);
    gas.co2_quality  =peak2peak(gas.co2_smoothed) /rms(gas.raw_co2-gas.co2_smoothed);
    gas.o2_quality   =peak2peak(gas.o2_smoothed) /rms(gas.raw_o2-gas.o2_smoothed);
    
    %% JIMI: Consider doing the linear combination
    % Matt: Why?
    % JIMI: works better.
    
    %% 7 Plot Results
    % 5.1 Raw BOLD, Co2, o2 -Co2-E, o2-E
    % 5.2 Xcorr BOLD-Co2, BOLD-o2,  BOLD-Co2-E, BOLD-o2-E,
    % 5.3 Adjusted BOLD+Co2+o2, Adjusted BOLD+Co2-E+o2-E
    
    %% 8 Package Results
    % NAME, Lag Co2, corr-coeff Co2, Lag o2, corr-coeff o2, CO2 Quality, O2 quality
    
    results=[results; {filenames(index).name(1:end-4),gas.co2_corr,gas.o2_corr,gas.co2_shift,gas.o2_shift,gas.co2_quality,gas.o2_quality,bold.bold_quality}];
    catch
        disp(['fail ' filenames(index).name(1:end-4)])
        output_redo=[output_redo;index]
    end
   %close all
    %clear gas bold LAGS_bold_upper_o2 C_bold_lower_co2 C_bold_lower_o2 C_bold_raw_co2 C_bold_raw_o2 C_bold_upper_co2 C_bold_upper_o2 LAGS_bold_lower_co2 LAGS_bold_lower_o2 LAGS_bold_raw_co2 LAGS_bold_raw_o2 LAGS_bold_upper_co2

     % save results
     try

    temp_filename=filenames(index).name;
    temp_filename=temp_filename([1:2, 4:end-4]);
    csvwrite([parameters.export_path filesep temp_filename '_co2.txt'],gas.final_co2);
    csvwrite([parameters.export_path filesep temp_filename '_o2.txt'] ,gas.final_o2);
     catch
     end

     clear bold gas
end

    
