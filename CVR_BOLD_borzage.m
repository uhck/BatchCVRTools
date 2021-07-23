%% MTB Bold processing 2019 10 30
% this program accepts a path that should contain subfolders with a
% specific format.

%%
% 1 get folders
% 2 loop folders
% 3 load NII and jason
% 4 remove first three dynamics
% 5 compute first order polynomial
% 6 subtract first order polynomial
% 7 compute time vector
% 8 export csv data (time vector and subtracted first order polynomial)
parameters.import_folder= '\\FALCON\Image_Repository\Research_Raw_NII\SH (Last_updated_30AUG19_KW)\';
parameters.export_folder='C:\Users\User\Desktop\bold_export';
parameters.dummy_dyn=3;
%% 1 get folders

folders=dir(parameters.import_folder);
folders=folders(~ismember({folders.name},{'.DS_Store','.','..'}));

%% 2 loop folders
for index=1:length(folders)
    try
    local_path=[parameters.import_folder filesep folders(index).name filesep 'bold'];
    files=dir(local_path);
    files=files(not([files.isdir]));
    %% 3 load NII and jason
    
    try
        raw.jason = jsondecode(fileread( [local_path filesep files(1).name] ));
    catch
        disp(['folder' folders(index).name ' had no jason'])
    end
    
    try
        raw.nii=load_nii([local_path filesep files(2).name]);
    catch
        disp(['folder' folders(index).name ' had no nii'])
    end
    
    raw.tr=raw.jason.RepetitionTime;
    %% 4 remove first three dynamics
    y=squeeze(mean(mean(mean(raw.nii.img(:,:,:,parameters.dummy_dyn+1:end),1),2),3));
    
    %% 5 compute first order polynomial
    x=([1:length(y)]');
    y2=fit(x,y,'poly1');
    y3=feval(y2,x);
    
    %% 6 subtract first order polynomial
    y_out=y-y3;
    
    %% 7 compute time vector
    x_out=[0:raw.tr:(length(y_out)-1)*raw.tr]';
    
    
    %% 8 export csv data (time vector and subtracted first order polynomial)
     bold=[x_out y_out];
    temp_filename=[folders(index).name(1:2),'_',folders(index).name(4:end-4),'_edits.txt'];
    csvwrite([parameters.export_folder filesep temp_filename],bold);
    
    catch
         disp(['folder' folders(index).name ' had some other failure'])
    end
end