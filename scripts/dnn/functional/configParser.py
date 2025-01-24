from dataclasses import dataclass, field
import yaml
import os
from typing import Any


@dataclass
class ConfigParser:
    _config_path: str = "configs"
    _dataset_config: dict[str, dict[str, Any]] = field(default_factory=dict)
    _model_config: dict[str, dict[str, Any]] = field(default_factory=dict)
    _optimizer_config: dict[str, dict[str, Any]] = field(default_factory=dict)
    _task_config: dict[str, dict[str, Any]] = field(default_factory=dict)
    _lr_scheduler_config: dict[str, dict[str, Any]] = field(default_factory=dict)
    _config_types: list[str] = field(
        default_factory=lambda: [
            "dataset",
            "model",
            "optimizer",
            "task",
            "lr_scheduler",
        ]
    )

    def __post_init__(self):
        for config_type in self._config_types:
            assert not getattr(
                self, f"_{config_type}_config"
            ), f"{config_type}_config already loaded. Each config type should only be loaded once."
            file_path = os.path.join(
                self._config_path,
                f"{config_type}_config.yaml",
            )
            config_data = self.__load_yaml_config(file_path)
            setattr(self, f"_{config_type}_config", config_data)

        assert len(self._optimizer_config) == 1, "Only one optimizer should be defined."
        assert (
            len(self._lr_scheduler_config) == 1
        ), "Only one lr_scheduler should be defined."

        for k, v in self._dataset_config.get("path", {}).items():
            self._dataset_config["path"][k] = (
                os.path.join(self._dataset_config["path"]["root_path"], v)
                if "root_path" not in k
                else v
            )

        # Remove all "0" targets and "cv"s
        for task_name, task_info in list(self._task_config.items()):
            if task_name == "general":
                continue
            task_info["target"] = {
                k: v for k, v in task_info["target"].items() if v == 1
            }
            task_info["cross_validation"] = {
                k: v for k, v in task_info["cross_validation"].items() if v == 1
            }
            if not task_info["target"] or not task_info["cross_validation"]:
                del self._task_config[task_name]

        # Merge iterable fields from 'general' config with specific configs
        general_config = self._task_config.get("general", {})
        for task_name, task_info in self._task_config.items():
            if task_name == "general":
                continue
            for key, value in general_config.items():
                if isinstance(value, (list, tuple, set)):
                    task_info[key] = list(set(task_info.get(key, [])) | set(value))
                elif isinstance(value, dict):
                    task_info[key] = {**value, **task_info.get(key, {})}

        self.__len = len([_ for _ in self.__all_config_generator()])

    def __str__(self):
        output = []
        for config_type in self._config_types:
            config_data = getattr(self, f"_{config_type}_config")
            output.append(f"{config_type.capitalize()} Config:")
            output.append(self.__get_tree_string(config_data))
        return "\n".join(output)

    @staticmethod
    def __load_yaml_config(file_path: str) -> dict[str, Any]:
        with open(file_path, "r") as file:
            return yaml.safe_load(file)

    @staticmethod
    def print_tree(d: dict, indent="", last="└── "):
        """Recursively prints a dictionary as a tree structure with branch symbols and vertical bars."""
        items = list(d.items())
        for i, (key, value) in enumerate(items):
            # Determine if this is the last item at this level
            last = "└── " if i == len(items) - 1 else "├── "
            # Print the current key with appropriate symbols for the tree structure
            print(indent + last + str(key), end=": ")

            if isinstance(value, dict):
                print()  # Newline before printing the nested dictionary
                # Update the indent for the next level of tree structure
                new_indent = indent + ("│   " if last == "├── " else "    ")
                ConfigParser.print_tree(value, new_indent, last)
            else:
                print(value)  # Print the value if it's not a dictionary

    @staticmethod
    def __get_tree_string(d: dict, indent="", last="└── "):
        """Recursively returns a dictionary as a tree structure string with branch symbols and vertical bars."""
        items = list(d.items())
        output = []
        for i, (key, value) in enumerate(items):
            # Determine if this is the last item at this level
            last = "└── " if i == len(items) - 1 else "├── "
            # Append the current key with appropriate symbols for the tree structure
            output.append(indent + last + str(key) + ": ")

            if isinstance(value, dict):
                # Update the indent for the next level of tree structure
                new_indent = indent + ("│   " if last == "├── " else "    ")
                output.append(
                    ConfigParser.__get_tree_string(value, new_indent, last)
                    if len(value) >= 1
                    else new_indent + "Empty Field."
                )
            else:
                # Append the value if it's not a dictionary
                output[-1] += str(value)
        return "\n".join(output)

    def __dataset_config_generator(self):
        return (
            {**self._dataset_config["path"], "fold_idx": fold_idx}
            for fold_idx in range(self._dataset_config["cross_validation"]["n_folds"])
        )

    def __model_config_generator(self):
        trainer_config = self._model_config.get("trainer_config", {})
        return (
            {"trainer_config": trainer_config, model_name: model_config}
            for model_name, model_config in self._model_config.items()
            if model_name != "trainer_config"
        )

    def __task_config_generator(self):
        general_config = self._task_config.get("general", {})
        for task_name, task_info in self._task_config.items():
            if task_name == "general":
                continue
            task_info_with_general = {**general_config, **task_info}
            for target_name in task_info_with_general["target"]:
                for cv_name in task_info_with_general["cross_validation"]:
                    metadata_fields = [
                        target_name if field == "as_target" else field
                        for field in task_info_with_general["metadata_fields"]
                    ]
                    yield {
                        "task_name": task_name,
                        "type": task_info_with_general["type"],
                        "target": target_name,
                        "cross_validation": cv_name,
                        "dataset_name": task_info_with_general["dataset_name"],
                        "metadata_fields": metadata_fields,
                    }

    def __len__(self):
        return self.__len

    def __all_config_generator(self):
        optimizer_name, optimizer_config = next(iter(self._optimizer_config.items()))
        scheduler_name, scheduler_config = next(iter(self._lr_scheduler_config.items()))
        return (
            {
                "dataset_config": dataset_config,
                "model_config": model_config,
                "optimizer_config": {
                    "name": optimizer_name,
                    "config": optimizer_config,
                },
                "lr_scheduler_config": {
                    "name": scheduler_name,
                    "config": scheduler_config,
                },
                "task_config": task_config,
            }
            for dataset_config in self.__dataset_config_generator()
            for model_config in self.__model_config_generator()
            for task_config in self.__task_config_generator()
        )

    def __iter__(self):
        return self.__all_config_generator()


if __name__ == "__main__":
    config_dir = "configs"
    parser = ConfigParser(config_dir)
    print(parser)

    # Run tests
    import sys

    sys.path.append(
        r"C:\Users\sean\Documents\Seafile\ZYMdeDocument\24-12-SuperHugeAAD\scripts\dnn"
    )

    import unittest
    from tests.test_configParser import TestConfigParser

    suite = unittest.TestLoader().loadTestsFromTestCase(TestConfigParser)
    unittest.TextTestRunner(verbosity=2).run(suite)
