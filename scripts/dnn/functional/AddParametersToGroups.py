import torch


def recursivelyAddParametersToGroups(
    net: torch.nn.Module, decayed_group_list, default_group_list
):
    size = 0
    for model_name, model in net.named_children():
        # if "aux_encoder" in model_name:
        #     for p in model.parameters():
        #         default_group_list += [p,]
        # else:
        [decayed_group_list, default_group_list] = recursivelyAddParametersToGroups(
            model, decayed_group_list, default_group_list
        )
        size += 1
    if size == 0:
        if not (
            isinstance(net, torch.nn.PReLU)
            or isinstance(net, torch.nn.modules.batchnorm._BatchNorm)
        ):
            for name, p in net.named_parameters():
                if "weight" in name:
                    decayed_group_list += [
                        p,
                    ]
                else:
                    default_group_list += [
                        p,
                    ]

        else:
            for name, p in net.named_parameters():
                default_group_list += [
                    p,
                ]

    return decayed_group_list, default_group_list
