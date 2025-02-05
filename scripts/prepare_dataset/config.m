EXG_OVERRIDE = 1;
STIMULI_OVERRIDE = 1;
ENVELOPE_OVERRIDE = 1;
MEL_SPECTRUM_OVERRIDE = 1;
DEBUG_MODE = 0;

save_path = "E:\SuperHuge\derivatives\";
exg_path = fullfile(save_path,"exg");
wav_path = fullfile(save_path,"stimuli");
mkdir(fullfile(save_path,"meta"))
mkdir(exg_path)
mkdir(wav_path)
for feature_type = ["wav","env","mel"]
    mkdir(fullfile(wav_path,feature_type));
end

dataset_names = ["NJU_preprocessed","DTU_preprocessed","KUL_preprocessed","Alices_raw","sparKULee_preprocessed"];
% dataset_names = ["KUL_preprocessed"];

pyenv("ExecutionMode","InProcess")
py.sys.path().append(".\utils\")