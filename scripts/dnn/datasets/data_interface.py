# Copyright 2021 Zhongyang Zhang
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import inspect
import importlib
import pickle as pkl
from torch.utils.data import DataLoader
from torch.utils.data.sampler import WeightedRandomSampler

from datasets.eeg_dataset import EegDataset
import lightning as pl  # Changed import statement


class DInterface(pl.LightningDataModule):

    def __init__(self, /, **kwargs):
        super().__init__()
        assert "dataset_name" in kwargs, "Please provide a dataset_name."
        self.dataset_name = kwargs.pop("dataset_name")
        self.kwargs = kwargs
        self.load_data_module()

    def setup(self, /, stage: str = "", **kwargs) -> None:
        self.trainset, self.valset, self.testset = self.instancialize(**kwargs)
        self.trainloader, self.valloader, self.testloader = self.create_dataloaders(
            [self.trainset, self.valset, self.testset], **kwargs
        )

    def train_dataloader(self):
        return self.trainloader

    def val_dataloader(self):
        return self.valloader

    def test_dataloader(self):
        return self.testloader

    def create_dataloaders(self, datasets, **other_args):
        inkeys = self.kwargs.keys()
        other_keys = other_args.keys()
        out_args = {}
        class_args = list(inspect.signature(DataLoader).parameters.keys())
        for arg in class_args:
            if arg in inkeys:
                out_args[arg] = self.kwargs[arg]
            elif arg in other_keys:
                out_args[arg] = other_args[arg]
        return [DataLoader(dataset, **out_args) for dataset in datasets]

    def load_data_module(self):
        name = self.dataset_name
        # Change the `snake_case.py` file name to `CamelCase` class name.
        # Please always name your model file name as `snake_case.py` and
        # class name corresponding `CamelCase`.
        camel_name = "".join([i.capitalize() for i in name.split("_")])
        try:
            self.data_module: type[EegDataset] = getattr(
                importlib.import_module(
                    "." + name, package=__package__), camel_name
            )
            assert issubclass(self.data_module, EegDataset)
        except:
            raise ValueError(
                f"Invalid Dataset File Name or Invalid Class Name data.{
                    name}.{camel_name}"
            )

    def instancialize(self, **other_args):
        """Instancialize a model using the corresponding parameters
        from self.hparams dictionary. You can also input any args
        to overwrite the corresponding value in self.kwargs.
        """

        def extract_args(source, target, required_keys):
            for key, value in source.items():
                if isinstance(value, dict):
                    extract_args(value, target, required_keys)
                elif key in required_keys:
                    target[key] = value

        class_args = list(
            inspect.signature(
                self.data_module.create_datasets).parameters.keys()
        )
        out_args = {}
        extract_args(self.kwargs, out_args, class_args)
        out_args.update(other_args)
        return self.data_module.create_datasets(**out_args)
