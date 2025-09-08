%% prepare necessary parameters
clear;clc;close all;
eeglab nogui
addpath('C:\Users\Sean\Documents\MATLAB\eeglab2023.0');
eegrawpath = 'E:\RAW\NJU-15class-Emotiv-AAD\exg\raw';
savepath = 'E:\RAW\NJU-15class-Emotiv-AAD\exg\preprocessed_mwf';

if ~isfolder(savepath)
    mkdir(savepath);
end

chan = {'Cz', 'Fz', 'Fp1', 'F7', 'F3', 'FC1', 'C3', 'FC5', 'FT9', 'T7', 'CP5', 'CP1', 'P3', 'P7', 'PO9', 'O1', 'Pz', 'Oz', 'O2', 'PO10', 'P8', 'P4', 'CP2', 'CP6', 'T8', 'FT10', 'FC6', 'C4', 'FC2', 'F4', 'F8', 'Fp2'};
frontal_chans = {'Fp1', 'Fp2', 'Fz', 'F3', 'F4', 'F7', 'F8', 'FC1', 'FC2', 'FC5', 'FC6'};
frontal_idx = find(ismember(chan, frontal_chans));
chanlocs = pop_readlocs('C:\Users\Sean\Documents\Seafile\ZYMdeDocument\21-04-EEG\Datasets\channels\emotivChan.loc', 'filetype', 'loc', 'importmode', 'eeglab');
fs = 128;
[b,a] = butter(1,0.5*2/fs,"high");
%% list all files
for subject_idx = [2,3,4,6,7,8,9,12,13,14,15,16,17,18,19,21,22,23,25,26,27]
    %% extract each subject
    %% load subject
    clear EEG ALLEEG
    eegs = load(fullfile(eegrawpath,sprintf("S%02d.mat",subject_idx)));
    data = eegs.data;
    expinfo = eegs.expinfo;
    
    if isfield(data, 'dim')
        data = rmfield(data, 'dim');
    end
    
    if isfield(data, 'event')
        data = rmfield(data, 'event');
    end
    
    if ~isfield(data, 'fsample')
        continue
    end
    
    trialnum = length(eegs.data.eeg);
    
    sepidx = 0;
    eegdata = [];
    if str2double(subject_idx) <= 20
        trialnum = 24;
    end
    %% append subject data to one array
    for trialIdx = 1:trialnum
        eeg = eegs.data.eeg{trialIdx};
        
        % Step 1: High-pass filter at 0.5 Hz
        
        eeg = filtfilt(b, a, double(eeg));
        if size(eeg,1) > size(eeg,2)
            eeg = eeg';
            % prefer channel first
        end
        % Step 2: Interpolate large amplitude artifacts
        eeg = interpolate_artifacts(eeg, 500); % threshold 可调整
        
        % Step 3: Apply MWF artifact removal
        eeg = artifact_removal_mwf(eeg, fs, frontal_idx, 3);
        
        % Step 4: Common average reference
        eeg = eeg - mean(eeg, 1);
        
        % Save back to data struct
        if size(eeg, 1) < size(eeg, 2)
            eeg = eeg';
        end
        data.eeg{trialIdx} = eeg;
        data.dim.chan.eeg{trialIdx} = chan;
        data.event.eeg(trialIdx).sample = 1;
        data.event.eeg(trialIdx).value = {table2array(expinfo(trialIdx, 1))};
        
    end
    
    
    data.fsample.eeg = fs;
    data.fsample = rmfield(data.fsample, 'wav');
    data.dim.eeg = 'time_chan';
    save(fullfile(savepath, sprintf("S%02d.mat",subject_idx)), 'data', 'expinfo', '-v7.3');
end

