function [wav2vec_feature, feat_fs] = extract_wav2vec(feature_extractor, model, audio, fs, run_pca, n_components)
arguments
    feature_extractor
    model
    audio (:,:) double
    fs (1,1) double
    run_pca logical = true
    n_components (1,1) double = 64
end

if run_pca
    skpca = py.getattr(py.importlib.import_module("sklearn.decomposition"),"PCA");
else
    n_components = 1024;
end

if size(audio,2) > size(audio,1)
    audio = audio';
end
%  ensure (time, channel)

if fs ~= 16000
    audio = resample(audio,16000,fs);
    fs = 16000;
end

seg_len = fs * 30;
n_segs = ceil(size(audio,1)/seg_len);
n_pts_per_frame = fs * 0.02;
audio = [audio;zeros(n_segs*seg_len-size(audio,1),size(audio,2))];
wav2vec_feature = zeros(size(audio,1)/n_pts_per_frame,n_components,size(audio,2));
for s = 1:n_segs
    audio_frame = [audio((1:seg_len)+(s-1)*seg_len,:);zeros(n_pts_per_frame,size(audio,2))];
    % pad to obtain constant output size
    feat_fs = 50;
    for c = 1:size(audio,2)
        audio_input = feature_extractor(py.numpy.array(audio_frame(:,c)),sampling_rate=py.int(fs),return_tensors=py.str("pt"),padding=py.bool(true));
        wav2vec_outputs = model(audio_input{"input_values"}.half().cuda());
        wav2vec_feature_tmp = wav2vec_outputs.last_hidden_state.detach().squeeze().cpu().numpy();
        if run_pca
            skpca_inst = skpca(n_components=py.int(n_components));
            wav2vec_feature_tmp = skpca_inst.fit_transform(wav2vec_feature_tmp);
            wav2vec_feature_tmp = py.numpy.ascontiguousarray(wav2vec_feature_tmp);
        end
        wav2vec_feature((1:30*feat_fs)+(s-1)*30*feat_fs,:,c) = double(wav2vec_feature_tmp.astype(py.numpy.float32));
    end
end

end