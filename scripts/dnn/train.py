import torch
from torch.multiprocessing.spawn import spawn
from tqdm import tqdm
from datasets import *
from models import *
from functional import *
from functional.configParser import ConfigParser
from functional.folder_creator import (
    create_folder_with_timestamp,
    create_subfolder_from_config,
)
from functional.run_dist import run_dist

if __name__ == "__main__":
    config_parser = ConfigParser()
    # base_path = create_folder_with_timestamp(
    #     config_parser._dataset_config["path"]["tmp_path"]
    # )

    ddp_ports = [int(x) for x in torch.randint(
        0, 99, (len(config_parser),))]
    for i, config_dict in enumerate(tqdm(
        config_parser,
        desc="Config Generator",
        total=len(config_parser),
    )):
        config_parser.print_tree(config_dict)
        # create_subfolder_from_config(base_path=base_path, config_dict=config_dict)
        spawn(
            run_dist,
            args=(
                torch.cuda.device_count(),
                ddp_ports[i],
                *config_dict.values(),
            ),
            nprocs=torch.cuda.device_count(),
            join=True,
            daemon=True,
        )
