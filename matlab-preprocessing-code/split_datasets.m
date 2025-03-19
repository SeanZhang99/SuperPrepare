clear;clc;close all;
addpath(".\utils\");

config;

dataset_infos = get_dataset_info(dataset_names,raw_path);
metadata = py.dict;

for dataset_id = progress(1:length(dataset_names))
    dataset_name = dataset_names(dataset_id);
    dataset_info = dataset_infos(dataset_id);
    fs = dataset_info.fs;
    for subject_id = progress(1:fastif(DEBUG_MODE,1,dataset_info.num_subject))
        data_struct = load_data_struct(fullfile(dataset_info.filelists(subject_id).folder,dataset_info.filelists(subject_id).name),dataset_name);
        num_trial = get_num_trials(dataset_name, subject_id, dataset_info);
        for trial_id = 1:fastif(DEBUG_MODE,1,num_trial)
            %% get trial info
            entry = sprintf("dataset-%03d-subject-%03d-trial-%03d",dataset_id,subject_id,trial_id);
            trial_data = extract_trials(data_struct,dataset_info.base_path,trial_id,subject_id,dataset_name,[]);
            trial_data = trial_data(1);

            exg = trial_data.exg;
            label = trial_data.label;

            if DEBUG_MODE && subject_id == 1 && trial_id == 1
                plot(exg)
                keyboard
                close all
            end

            stimuli_path = trial_data.stimuli_path;
            compet_stimuli_path = trial_data.compet_stimuli_path;

            env_path = trial_data.env_path;
            compet_env_path = trial_data.compet_env_path;

            mel_path = trial_data.mel_path;
            compet_mel_path = trial_data.compet_mel_path;

            stimuli = trial_data.stimuli;
            compet_stimuli = trial_data.compet_stimuli;
            stimuli_fs = trial_data.stimuli_fs;

            env = trial_data.env;
            compet_env = trial_data.compet_env;

            mel = trial_data.mel;
            compet_mel = trial_data.compet_mel;
            %% processing exg
            % exg: nan-> no such trial. number-> correct, go on.
            if isnan(exg)
                % trial index exceed
                break
            end
            exg = exg(:,dataset_info.channel_indices);
            % save exg to file
            if EXG_OVERRIDE || ~exist(fullfile(exg_path,sprintf("%s.npy",entry)),"file")
                if fs ~= common_fs
                    exg = resample(exg,common_fs,fs);
                end
                py.numpy.save(fullfile(exg_path,sprintf("%s.npy",entry)),py.numpy.array(exg));
            end

            %% processing stimuli
            % stimuli_path: "" empty string-> stimuli does not come from a
            % file. "path/to/string"-> stimuli comes from a file, load
            % stimuli from file.
            if stimuli_path ~= ""
                [stimuli,stimuli_fs] = load_stimuli(dataset_info.audio_path,stimuli_path);
            end
            % stimuli: nan-> stimuli not provided, nor a stimuli file.
            % otherwise-> stimuli is available
            if ~isnan(stimuli)
                % compet_stimuli_path: "" empty stirng-> no competing stimuli
                % provided by file(s). string array-> provided competing
                % stimuli with file(s).
                if compet_stimuli_path ~= ""
                    for path = compet_stimuli_path
                        tmp = load_stimuli(dataset_info.audio_path,path);
                        assert(all(~isnan(tmp),"all"))
                        tmp = to_column_vector(tmp);
                        stimuli(:,end+1) = tmp;
                    end
                    % compet_stimuli: nan: competing stimuli not directly
                    % provided. numeric: provided
                elseif ~isnan(compet_stimuli)
                    stimuli(:,end+size(compet_stimuli,2)) = to_column_vector(compet_stimuli);
                end
            end

            if ~isnan(stimuli)
                stimuli_path = fullfile(wav_path,"wav",sprintf("%s_wav.npy",entry));
            end

            stimuli_is_available = stimuli_path~=""&&~isempty(stimuli);

            if stimuli_path ~= "" && (STIMULI_OVERRIDE || ~exist(stimuli_path,"file"))
                py.numpy.save(stimuli_path,py.numpy.array(stimuli));
            end

            %% processing envelope
            if env_path ~= ""
                env = sum(load_stimuli(dataset_info.audio_path,env_path),2);
            end
            if ~isnan(env)
                if compet_env_path ~= ""
                    for path = compet_env_path
                        tmp = load_stimuli(dataset_info.audio_path,path);
                        assert(all(~isnan(tmp),"all"))
                        tmp = sum(to_column_vector(tmp),2);
                        env(:,end+1) = tmp;
                    end
                elseif ~isnan(compet_env)
                    env(:,end+size(compet_env,2)) = to_column_vector(compet_env);
                end
                if fs ~= common_fs
                    env = resample(env,common_fs,fs);
                end
            elseif stimuli_is_available
                % although envelope is not directly provided, stimuli is
                % available.
                tmp = [];
                for ii = 1:size(stimuli,2)
                    tmp(:,ii) = calculateEnvelopeERBGammatone(stimuli(:,ii),stimuli_fs,env_gmt_freq_range,env_gmt_num_bands,env_gmt_plaw);
                end
                env = resample(tmp,common_fs,stimuli_fs);
            end

            if ~isnan(env)
                env_path = fullfile(wav_path,"env",sprintf("%s_env.npy",entry));
            end
            if env_path ~= "" && (ENVELOPE_OVERRIDE || ~exist(env_path,"file"))
                py.numpy.save(env_path,py.numpy.array(env));
            end
            %% processing mel spectrum
            if mel_path ~= ""
                mel = load_stimuli(dataset_info.audio_path,mel_path);
            end
            if ~isnan(mel)
                if compet_mel_path ~= ""
                    for path = compet_mel_path
                        tmp = load_stimuli(dataset_info.audio_path,path);
                        assert(all(~isnan(tmp),"all"))
                        tmp = to_column_vector(tmp);
                        mel(:,:,end+1) = tmp;
                    end
                elseif ~isnan(compet_mel)
                    mel(:,:,end+size(compet_mel,2)) = compet_mel;
                end
            elseif stimuli_is_available
                % although envelope is not directly provided, stimuli is
                % available.
                tmp = [];
                for ii = 1:size(stimuli,2)
                    tmp(:,:,ii) = to_column_vector(double(...
                        py.mel.calculate_mel_spectrogram(...
                        audio=py.numpy.array(stimuli(:,ii)), ...
                        fs=py.int(stimuli_fs), ...
                        target_fs=py.int(common_fs))));
                end
                mel = tmp;
            end

            if ~isnan(mel)
                mel_path = fullfile(wav_path,"mel",sprintf("%s_mel.npy",entry));
            end
            if mel_path ~= "" && (MEL_SPECTRUM_OVERRIDE || ~exist(mel_path,"file"))
                py.numpy.save(mel_path,py.numpy.array(mel));
            end

            %% prepare metadata
            entry = py.str(entry);
            metadata{entry} = py.dict;
            metadata{entry}{"dataset_id"} = py.int(dataset_id);
            metadata{entry}{"subject_id"} = py.int(subject_id);
            metadata{entry}{"trial_id"} = py.int(trial_id);
            metadata{entry}{"signal_length"} = py.len(exg);
            metadata{entry}{"num_channel"} = py.int(dataset_info.nch);
            metadata{entry}{"fs"} = py.int(fs);
            metadata{entry}{"dataset_name"} = py.str(dataset_name);
            metadata{entry}{"channel_infos"} = dataset_info.channel_infos;

            if label~=""
                metadata{entry}{"label"}=py.str(label);
            end
            if stimuli_path~=""
                metadata{entry}{"wav"}=py.int(1);
                metadata{entry}{"wav_fs"}=py.int(stimuli_fs(1));
            else
                metadata{entry}{"wav"}=py.int(0);
            end
            if env_path~=""
                metadata{entry}{"env"}=py.int(1);
                metadata{entry}{"env_fs"}=py.int(fs);
            else
                metadata{entry}{"env"}=py.int(0);
            end
            if mel_path~=""
                metadata{entry}{"mel"}=py.int(1);
                metadata{entry}{"mel_fs"}=py.int(fs);
            else
                metadata{entry}{"mel"}=py.int(0);
            end
            clearvars("-except","data_struct","dataset_id","dataset_info","dataset_infos","dataset_name","dataset_names",...
                "DEBUG_MODE","ENVELOPE_OVERRIDE","EXG_OVERRIDE","exg_path","fs","MEL_SPECTRUM_OVERRIDE","metadata",...
                "num_trial","OVERRIDE_ALL","raw_path","save_path","STIMULI_OVERRIDE","subject_id","wav_path",...
                "env_gmt_freq_range","env_gmt_num_bands","env_gmt_plaw","common_fs");
            clearvars("trial_id","trial_info",...
                "exg","label",...
                "stimuli_path","compet_stimuli_path",...
                "env_path","compet_env_path",...
                "mel_path","compet_mel_path",...
                "stimuli","compet_stimuli","stimuli_fs",...
                "env","compet_env",...
                "mel","compet_mel")
        end
    end
end

%% save metadata
pickle = py.importlib.import_module('pickle');
with_open = py.open(fullfile(save_path, "meta","metadata.pkl"),"wb");
pickle.dump(metadata,with_open);
with_open.close;