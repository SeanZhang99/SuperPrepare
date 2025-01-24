import os
from datetime import datetime
import yaml


def create_folder_with_timestamp(base_path):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    folder_path = os.path.join(base_path, timestamp)
    os.makedirs(folder_path, exist_ok=True)
    return folder_path


def save_configs_to_yaml(subfolder_path, **configs):
    for config_name, config in configs.items():
        file_path = os.path.join(subfolder_path, f"{config_name}.yaml")
        with open(file_path, "w") as file:
            yaml.dump(config, file)


def create_subfolder_from_config(base_path, config_dict):
    task_config = config_dict["task_config"]
    model_config = config_dict["model_config"]
    subfolder_name = f"{task_config['task_name']}-{task_config['target']}-{task_config['cross_validation']}-{model_config['trainer_config']['model_name']}"
    subfolder_path = os.path.join(base_path, subfolder_name)
    os.makedirs(subfolder_path, exist_ok=True)
    save_configs_to_yaml(
        subfolder_path,
        **config_dict,
    )


# Example usage:
# base_path = "/tmp"
# config_parser = ConfigParser()  # Assuming ConfigParser is defined elsewhere
# main_folder = create_folder_with_timestamp(base_path)
# create_subfolders(main_folder, config_parser)
