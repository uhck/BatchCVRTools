
close all; clc

studygroup = ''; %edits
satisfied = 0; %edits

%% Gather Patient Information

if isempty(studygroup) %edits
    studygroup = input ('Study Group: C (Clinical), W (Whittier), P (Pediatric mTBI), A (Adult mTBI), H (HIV), M (Mena), O (Other): ', 's'); 
    if isempty(studygroup)
        studygroup = 'O';
    end

    studygroup=upper(studygroup);

    subject= input('Subject Numeric ID Code: ', 's');
    if isempty(subject)
        subject = '0000';
    end
    subject=upper(subject);

    date=input('Date of Exam in MMDDYYYY or leave empty for Today: ', 's');
    if isempty(date)
        date = datestr(now,'mmddyyyy');
    end
end

%% Convert VarName to useful variables
    exist Time;
    Time = VarName1;
    O2 = -VarName2;
    CO2 = VarName3;
    %Time = VarName1(1:64:end);
    %O2 = -VarName2(1:64:end);
    %CO2 = VarName3(1:64:end);
    
    %% Convert biopac output from minutes to seconds

    if Time(end) < 20       %If data is in minutes, the final value will be < 20
        Time=(Time*60);         %Conversion to seconds
    end
    
    %% Creating timing for output file

    TR_value = str2num(input('Enter TR value: ', 's'));
    ScanTime = 0:TR_value:Time(end);   
    ScanTime = ScanTime';
    
%For 125hz Biopac data use downsample(Time,175)
%For 62.5hz Biopac data use resample(Time,2,175)!!! Resample has errors as it assumes line should be
%zero at start and end of data.  Downsample can only change by a set
%integer, however, so if I want TR 1.4s I can't get there from 62.5 with an
%integer.  ?? Use 3 column format instead?  Keep native resolution?  
%ResampleTime=downsample(Time,175);

%% CO2 Analysis
while (~satisfied)
%Calls function so that variables can be reused and don't have to be
%cleared.
    ExtractEndTidals(ScanTime,Time,O2,CO2,studygroup,subject,date);

%MinPeakProminence: prevents false identification of noise as a peak
%MinPeakWidth: removes small breaths
    
    satisfied = input('Are you satisfied with this run? 0=no, 1=yes: '); %edits
end %edits while loop


function ExtractEndTidals(ScanTime,Time,O2,CO2,studygroup,subject,date)
    studypath='C:\Users\Kevin\Dropbox\EndTidal_Recordings';
    
    PeakCO2 = [];
    while (size(PeakCO2) < 10)
        prominence_value = input('New prominence value (default = 1): '); %edits
        if isempty(prominence_value)
            prominence_value = 1
        end
    
        width_value = input('New width value (default = 1): ');
        if isempty(width_value)
            width_value = 1
        end
        [PeakCO2, PeakTimeCO2] = findpeaks(CO2, Time,'MinPeakProminence',prominence_value,'MinPeakWidth',width_value);
    end

    FitPeakCO2 = fit(PeakTimeCO2,PeakCO2,'linearinterp');
    ETCO2 = FitPeakCO2(ScanTime);
    
    SmoothPeakCO2 = smooth(PeakCO2,3);
    FitSmoothPeakCO2 = fit(PeakTimeCO2,SmoothPeakCO2,'linearinterp');
    SmoothETCO2 = FitSmoothPeakCO2(ScanTime);

%% O2 analysis

    PeakO2 = [];
    while (size(PeakO2) < 10)
        prominence_value = input('New prominence value (default = 1): '); %edits
        if isempty(prominence_value)
            prominence_value = 1
        end
        
        width_value = input('New width value (default = 1): ');
        if isempty(width_value)
            width_value = 1
        end
        [PeakO2, PeakTimeO2] = findpeaks(O2, Time,'MinPeakProminence',prominence_value,'MinPeakWidth',width_value);
    end
    
    SmoothPeakO2 = smooth(PeakO2,3);
    FitSmoothPeakO2 = fit(PeakTimeO2,SmoothPeakO2,'linearinterp');
    SmoothETO2 = FitSmoothPeakO2(ScanTime);
    
%creates a function that connects the peak values then puts discrete values
%for each of the time points.  
    FitPeakO2 = fit(PeakTimeO2,PeakO2,'linearinterp');
    ETO2 = FitPeakO2(ScanTime);

%% Quality check end tidal data
    close all;
    figure;
    subplot(2,1,1);
    plot(Time, CO2, 'r', ScanTime, ETCO2,'g');
    xlabel('Time - seconds');
    ylabel('Partial Pressure CO2 -  mmHG');
    title('ETCO2');
    
%    subplot(4,1,2)
%    plot(Time, CO2, 'r-', ScanTime, SmoothETCO2,'g')
%    xlabel('Time - seconds')
%    ylabel('Partial Pressure CO2 -  mmHG')
%    title('SmoothETCO2')
    
%   Flip O2 back
    O2 = -O2;
    ETO2 = -ETO2;

    subplot(2,1,2);
    plot(Time, O2, 'r', ScanTime, ETO2,'g');
    xlabel('Time - seconds');
    ylabel('O2 (%)');
    title('ETO2');
    
%    subplot(4,1,4)
%    plot(Time, O2, 'r-', ScanTime, SmoothETO2,'g')
%    xlabel('Time - seconds')
%    ylabel('O2 (%)')
%    title('SmoothETO2')

    filenameET = char([studypath filesep studygroup subject '_' date '_ET_Tracings.pdf']);
    saveas(gcf,filenameET);
    clear filenameET;

%% The following exports ETCO2 and ETO2 in CSV format for 1 column analysis

    filename=char([studypath filesep studygroup subject '_' date '_ETCO2.txt']);
    keepsmooth = input('Save SmoothETCO2? Yes=1: ');
    if keepsmooth == 1
        fid=fopen(filename,'w');
        fprintf(fid,'%f \n',SmoothETCO2);% comma separated value!
        fclose(fid);
    else
        fid=fopen(filename,'w');
        fprintf(fid,'%f \n',ETCO2);% comma separated value!
        fclose(fid);
    end
    
    filename=[studypath filesep studygroup subject '_' date '_ETO2.txt'];
    keepsmooth = input('Save SmoothETO2? Yes=1: ');
    if keepsmooth == 1
        fid=fopen(filename,'w');
        fprintf(fid,'%f \n',SmoothETO2);% comma separated value!
        fclose(fid);
    else
        fid=fopen(filename,'w');
        fprintf(fid,'%f \n',ETO2);% comma separated value!
        fclose(fid);
    end

end
