import torch
from tqdm import tqdm
from functional.configParser import ConfigParser
from functional.folder_creator import (
    create_folder_with_timestamp,
    create_subfolder_from_config,
)
import pytorch_lightning as pl
from pytorch_lightning import callbacks as plc
from pytorch_lightning.loggers import TensorBoardLogger
from pytorch_lightning import Trainer
from datasets.data_interface import DInterface
from models.model_interface import MInterface


if __name__ == "__main__":
    config_parser = ConfigParser()
    # base_path = create_folder_with_timestamp(
    #     config_parser._dataset_config["path"]["tmp_path"]
    # )

    for i, config_dict in enumerate(
        tqdm(
            config_parser,
            desc="Config Generator",
            total=len(config_parser),
        )
    ):
        config_parser.print_tree(config_dict)
        # create_subfolder_from_config(base_path=base_path, config_dict=config_dict)
        callbacks = config_dict["callback_list"]

        model_interface = MInterface(
            config_dict["model_config"],
            config_dict["optimizer_config"],
            **config_dict["dataset_config"],
            **config_dict["task_config"]
        )

        data_interface = DInterface()

        trainer = Trainer(
            accelerator="gpu",
            callbacks=callbacks,
        )
        break
