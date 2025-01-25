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
from pyexpat import model
from typing import Iterable
import torch
import importlib
from torch.nn import functional as F
import torch.optim.lr_scheduler as lrs

import pytorch_lightning as pl


class MInterface(pl.LightningModule):
    def __init__(
        self,
        model_config: dict,
        optimizer_config: dict,
        lr_scheduler_config: dict,
        **kwargs,
    ):
        super().__init__()
        self.model_name = list(model_config.keys())[0]
        self.model_config = model_config[self.model_name]
        self.optimizer_config = optimizer_config
        self.lr_scheduler_config = lr_scheduler_config
        self.load_model(**kwargs)

    def load_model(self, **other_args):
        # Change the `snake_case.py` file name to `CamelCase` class name.
        # Please always name your model file name as `snake_case.py` and
        # class name corresponding `CamelCase`.
        camel_name = "".join([i.capitalize() for i in self.model_name.split("_")])
        try:
            Model = getattr(
                importlib.import_module("." + self.model_name, package=__package__),
                camel_name,
            )
        except:
            raise ValueError(
                f"Invalid Module File Name or Invalid Class Name {self.model_name}.{camel_name}!"
            )
        self.model = self.instancialize(Model, **other_args)

    def instancialize(self, Model, **other_args):
        """Instancialize a model using the corresponding parameters
        from self.hparams dictionary. You can also input any args
        to overwrite the corresponding value in self.hparams.
        """

        def extract_args(source: dict, target: dict, required_keys: Iterable[str]):
            for key, value in source.items():
                if key in required_keys:
                    target[key] = value
                elif isinstance(value, dict):
                    extract_args(value, target, required_keys)

        class_args = list(inspect.signature(Model.create_models).parameters.keys())
        out_args = {}
        extract_args(self.model_config, out_args, class_args)
        extract_args(other_args, out_args, class_args)
        return Model.create_models(**out_args)
