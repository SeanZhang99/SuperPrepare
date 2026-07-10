function trial_data = extract_trials(data_struct,dataset_path,trial_idxs,subject_id,dataset_name,desired_length)
%EXTRACT_TRIALS Summary of this function goes here
%   Detailed explanation goes here
trial_data = struct();
for trial_idx = trial_idxs
    exg = nan;
    stimuli_path = "";
    compet_stimuli_path = "";
    stimuli_name = "";
    compet_stimuli_name = "";
    label = "";
    env_path = "";
    compet_env_path = "";
    mel_path = "";
    compet_mel_path = "";
    stimuli = nan;
    compet_stimuli = nan;
    env = nan;
    compet_env = nan;
    mel = nan;
    compet_mel = nan;
    stimuli_fs = nan;
    wav2vec2 = nan;
    wav2vec2_path = "";
    compet_wav2vec2 = nan;
    compet_wav2vec2_path = "";
    wav2vec2_fs = nan;
    switch dataset_name
        case {"NJU_preprocessed","NJU_raw"}
            if trial_idx <= length(data_struct.data.eeg)
                exg = data_struct.data.eeg{trial_idx};
                [~,label] = get_attention_directions(data_struct.expinfo,trial_idx);
                stimuli_path = table2array(data_struct.expinfo(trial_idx,2+(data_struct.expinfo.attended_lr(trial_idx)=="right")));
                compet_stimuli_path = table2array(data_struct.expinfo(trial_idx,2+(data_struct.expinfo.attended_lr(trial_idx)~="right")));
                
                stimuli_name = split(stimuli_path,".");
                stimuli_name = stimuli_name{1};
                compet_stimuli_name = split(compet_stimuli_path,".");
                compet_stimuli_name = compet_stimuli_name{1};
            end
        case {"Alices_raw"}
            if trial_idx <= length(data_struct.data.exg)
                exg = data_struct.data.exg{trial_idx};
                pattern = "DownTheRabbitHoleFinal_SoundFile";
                stimuli_path = sprintf("%s%d.wav",pattern,trial_idx);
                stimuli_name = sprintf("%s%d",pattern,trial_idx);
            end
        case {"KUL_raw","KUL_preprocessed"}
            if dataset_name == "KUL_raw"
                field = "trials";
            elseif dataset_name == "KUL_preprocessed"
                field = "preproc_trials";
            end
            if trial_idx <= length(data_struct.(field))
                exg = data_struct.(field){trial_idx}.RawData.EegData;
                label = string(data_struct.(field){trial_idx}.attended_ear);
                stimuli_path = string(data_struct.(field){trial_idx}.stimuli{1+(label=="R")});
                compet_stimuli_path = string(data_struct.(field){trial_idx}.stimuli{1+(label~="R")});
                split_stimuli = split(stimuli_path,"_");
                compet_split_stimuli = split(compet_stimuli_path,"_");
                env_path = sprintf("powerlaw subbands %s_dry.mat",join(split_stimuli(1:end-1),"_"));
                compet_env_path = sprintf("powerlaw subbands %s_dry.mat",join(compet_split_stimuli(1:end-1),"_"));
                
                if label == "L"
                    label = "left";
                elseif label == "R"
                    label = "right";
                end

                stimuli_name = split(stimuli_path,[".","_"]);
                stimuli_name = stimuli_name(1:end-2);
                if length(stimuli_name) == 3
                    stimuli_name = stimuli_name(2:end);
                end
                stimuli_name = join(stimuli_name,"_");
                
                compet_stimuli_name = split(compet_stimuli_path,[".","_"]);
                compet_stimuli_name = compet_stimuli_name(1:end-2);
                if length(compet_stimuli_name) == 3
                    compet_stimuli_name = compet_stimuli_name(2:end);
                end
                compet_stimuli_name = join(compet_stimuli_name,"_");
            end
        case {"sparKULee_raw","sparKULee_preprocessed"}
            subject_id_str = sprintf('%03d', subject_id);
            filelists = dir(fullfile(dataset_path, ['sub-' subject_id_str], '*', '*.npy'));
            if trial_idx <= length(filelists)
                exg_py = py.numpy.load(fullfile(filelists(trial_idx).folder,filelists(trial_idx).name));
                exg = double(exg_py)';

                target_audio = regexp(filelists(trial_idx).name, ...
                    'desc-preproc-audio-(audiobook_\d+(_\d+)?(?:_(shifted|artefact))?|podcast_\d+)_eeg\.npy' ,...
                    "tokens");
                env_path = target_audio{1}{1}+"_-_envelope.npy";
                mel_path = target_audio{1}{1}+"_-_mel.npy";
    
                stimuli_path = target_audio{1}{1}+".wav";
    
                wav2vec2_path = target_audio{1}{1}+"_-_wav2vec14pca.npy";
                wav2vec2_fs = 128;

                stimuli_name = target_audio{1}{1};
                
            end
        case {"DTU_preprocessed","DTU_raw"}
            data_struct.expinfo = data_struct.expinfo(~cellfun(@isempty,data_struct.expinfo.wavfile_female),:);
            if trial_idx <= length(data_struct.data)
                data = data_struct.data{trial_idx};
                exg = data.eeg{1};

                % explicitly say, we are extrating label from attention
                % direction but not speaker gender.
                label = fastif(data_struct.expinfo.attend_lr(trial_idx)==1,"left","right");
                stimuli = data.wavA{1}; % in DTU dataset (preprocessed with our scripts), wavA is always the attended speaker.
                compet_stimuli = data.wavB{1};
                stimuli_fs = data.fsample.wavA;

                stimuli_name = fastif(data_struct.expinfo.attend_mf(trial_idx)==1,data_struct.expinfo.wavfile_male,data_struct.expinfo.wavfile_female);
                compet_stimuli_name = fastif(data_struct.expinfo.attend_mf(trial_idx)==1,data_struct.expinfo.wavfile_female,data_struct.expinfo.wavfile_male);

                stimuli_name = split(stimuli_name(trial_idx),".");
                stimuli_name = stimuli_name{1};
                compet_stimuli_name = split(compet_stimuli_name(trial_idx),".");
                compet_stimuli_name = compet_stimuli_name{1};
            end
        case {"PKU_preprocessed","PKU-NBD_preprocessed"}
            exg = data_struct.EEG_space.data';
            % The label (1-4) is infered based on the source code given by PKU
            % dataset's authors. The actual directions were told by authors
            % themselves to me.
            label = ceil(trial_idx/10);
            switch label
                case 1
                    label = 30;
                case 2
                    label = -30;
                case 3
                    label = 90;
                case 4
                    label = -90;
                otherwise
                    error("Unimplemented label");
            end
            % The envelope is found on the source code given by authors of
            % the dataset. The original sampling rate is 64 Hz, and we
            % resample it to 128 Hz to match the 128 Hz EEG signals.
            all_envelope = load(fullfile(dataset_path,"space_envall.mat"));
            all_envelope = resample(all_envelope.space_env',128,64);
            envelope_index = load(fullfile(dataset_path,"space_num.mat"));
            envelope_index = envelope_index.space_num(trial_idx,:);
            env = all_envelope(:,envelope_index(1));
            compet_env = all_envelope(:,envelope_index(2:end));
        case "ICL_preprocessed"
            exg = data_struct.eeg;
            condition = data_struct.condition;
            stimuli_name = sprintf("%s_part%02d_story",condition,trial_idx);
            compet_stimuli_name = sprintf("%s_part%02d_distractor",condition,trial_idx);
            stimuli = data_struct.attended_audio;
            compet_stimuli = data_struct.competing_audio;
            stimuli_fs = data_struct.audio_fs;
        case "AHU_preprocessed"
            exg = data_struct((1:152*128)+(trial_idx-1)*152*128,:);
            label = fastif(mod(trial_idx,2)==1,"left","right");

            audio_path = fullfile(strrep(dataset_path,"eeg_preproc","mixed_audio"),sprintf("%d.wav",trial_idx));
            [stimuli,stimuli_fs] = audioread(audio_path);
            
            if label == "right"
                % convert to attended stimuli first.
                stimuli = stimuli(:,[2,1]);
            end

            exg = exg * 1e4;
        case "KUL-AV-GC_preprocessed"
            exg = data_struct.data{1,trial_idx};
            label =  string(data_struct.initAttention(1,trial_idx));
            env = data_struct.stimulus.attendedEnvelopes{1,trial_idx};
            compet_env = data_struct.stimulus.unattendedEnvelopes{1,trial_idx};

            % Regarding the attention switch in KUL-AV-GC:
            % label: the label presents the initial attention.
            % stimuli: the stimuli also switched sides (from left to
            % right or vice versa) when an attention switch occurred.
            % It is unnecessary to swap the stimuli and compet stimuli
            % nor swap their names.

            stimuli_name = data_struct.randomization{1,trial_idx}.(label);
            compet_stimuli_name = data_struct.randomization{1,trial_idx}.(fastif(label=="left","right","left"));

            stimuli_name = split(stimuli_name,"_");
            stimuli_name = string(join(stimuli_name(1:end-1),""));
            compet_stimuli_name = split(compet_stimuli_name,"_");
            compet_stimuli_name = string(join(compet_stimuli_name(1:end-1),""));

            exg = exg(1:length(exg),:);
            env = env(1:length(exg),:);
            compet_env = compet_env(1:length(exg),:);

        case "NUS_preprocessed"
            exg = data_struct.data{1,trial_idx};
            switch trial_idx
                case {1, 2, 3, 4}
                    if data_struct.labels(trial_idx, 1) == 0,label = '-90';else,label = '90';end
                case {5, 6, 7, 8}
                    if data_struct.labels(trial_idx, 1) == 0,label = '-60';else,label = '60';end
                case {9,10,11,12}
                    if data_struct.labels(trial_idx, 1) == 0,label = '-45';else,label = '45';end
                case {13,14,15,16}
                    if data_struct.labels(trial_idx, 1) == 0,label = '-30';else,label = '30';end
                case {17,18,19,20}
                    if data_struct.labels(trial_idx, 1) == 0,label = '-5';else,label = '5';end
            end
        case "CocktailParty_preprocessed"
            if ~isempty(data_struct.preprocessed_data{trial_idx})
                exg = data_struct.preprocessed_data{trial_idx}.eeg;

                stimuli = data_struct.preprocessed_data{trial_idx}.audio;
                stimuli_fs = data_struct.preprocessed_data{trial_idx}.audio_fs;
                if subject_id <= 17
                    label = "left";
                    stimuli_name = sprintf("TwentyThousandMiles_part%02d",trial_idx);
                    compet_stimuli_name = sprintf("JourneyTo_part%02d",trial_idx);
                else
                    label = "right";
                    stimuli = stimuli(:,[2,1]);
                    stimuli_name = sprintf("JourneyTo_part%02d",trial_idx);
                    compet_stimuli_name = sprintf("TwentyThousandMiles_part%02d",trial_idx);
                end
            end
        case {"USTC_preprocessed"}
            exg = data_struct.data(1,trial_idx+1).EEG;
            exg = squeeze(exg);

            stimuli_path = data_struct.data(1,trial_idx+1).audio_attended;
            compet_stimuli_path = data_struct.data(1,trial_idx+1).audio_unattended;

            stimuli_name = data_struct.data(1,trial_idx+1).audio_attended;
            compet_stimuli_name = data_struct.data(1,trial_idx+1).audio_unattended;

            label = data_struct.data(1,trial_idx+1).label;

        otherwise
            error("Unimplemented dataset %s",dataset_name)
    end
    trial_data(end).exg = exg;
    trial_data(end).stimuli_path = stimuli_path;
    trial_data(end).compet_stimuli_path = string(compet_stimuli_path);
    trial_data(end).stimuli_name = string(stimuli_name);
    trial_data(end).compet_stimuli_name = string(compet_stimuli_name);
    trial_data(end).label = string(label);
    trial_data(end).env_path = env_path;
    trial_data(end).compet_env_path = string(compet_env_path);
    trial_data(end).mel_path = mel_path;
    trial_data(end).compet_mel_path = compet_mel_path;
    trial_data(end).stimuli = stimuli;
    trial_data(end).compet_stimuli = compet_stimuli;
    trial_data(end).env = env;
    trial_data(end).compet_env = compet_env;
    trial_data(end).mel = mel;
    trial_data(end).compet_mel = compet_mel;
    trial_data(end).stimuli_fs = stimuli_fs;
    trial_data(end).wav2vec2 = wav2vec2;
    trial_data(end).wav2vec2_path = wav2vec2_path;
    trial_data(end).compet_wav2vec2 = compet_wav2vec2;
    trial_data(end).compet_wav2vec2_path = compet_wav2vec2_path;
    trial_data(end).wav2vec2_fs = wav2vec2_fs;
    trial_data(end+1) = struct("exg",[],...
        "stimuli_path",[],"compet_stimuli_path",[],...
        "stimuli_name",[],"compet_stimuli_name",[],...
        "stimuli",[],"compet_stimuli",[],...
        "stimuli_fs",[],...
        "label",[],...
        "env_path",[],"compet_env_path",[],"env",[],"compet_env",[],...
        "mel_path",[],"compet_mel_path",[],"mel",[],"compet_mel",[],...
        "wav2vec2_path",[],"compet_wav2vec2_path",[],"wav2vec2",[],"compet_wav2vec2",[],"wav2vec2_fs",[]);
end
end


