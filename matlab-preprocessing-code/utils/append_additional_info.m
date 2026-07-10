function info_struct = append_additional_info(dataset_name, data_struct, subject_id, trial_id)
    switch dataset_name
    case {"KUL-AV-GC_preprocessed"}
        vc = data_struct.conditionID{trial_id};
        vc = regexp(vc, '[A-Z0-9]?[a-z]*', 'match');
        vc = vc(1:end-1);
        vc = join(vc,"");
        vc = string(vc);
        info_struct = struct("visual_condition",vc);
    otherwise
        % do nothing
        info_struct = struct();
    end
end

