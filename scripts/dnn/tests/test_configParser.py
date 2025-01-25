import unittest
import os
from functional.configParser import ConfigParser
from io import StringIO
import sys


class TestConfigParser(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.config_dir = "C:/Users/sean/Documents/Seafile/ZYMdeDocument/24-12-SuperHugeAAD/SuperHugeAAD/scripts/dnn/configs"
        cls.parser = ConfigParser(cls.config_dir)

    def test_instance_creation(self):
        self.assertIsInstance(self.parser, ConfigParser)
        self.assertIsInstance(self.parser._dataset_config, dict)
        self.assertIsInstance(self.parser._model_config, dict)
        self.assertIsInstance(self.parser._optimizer_config, dict)
        self.assertIsInstance(self.parser._task_config, dict)

    def test_load_yaml_config(self):
        file_path = os.path.join(self.config_dir, "dataset_config.yaml")
        config_data = self.parser._ConfigParser__load_yaml_config(file_path)
        self.assertIsInstance(config_data, dict)
        self.assertIn("path", config_data)

    def test_load_configs(self):
        self.assertIsInstance(self.parser._dataset_config, dict)
        self.assertIsInstance(self.parser._model_config, dict)
        self.assertIsInstance(self.parser._optimizer_config, dict)
        self.assertIsInstance(self.parser._task_config, dict)

    def test_print_tree(self):
        captured_output = StringIO()
        sys.stdout = captured_output
        self.parser.print_tree(self.parser._dataset_config)
        self.parser.print_tree(self.parser._model_config)
        self.parser.print_tree(self.parser._optimizer_config)
        self.parser.print_tree(self.parser._task_config)
        sys.stdout = sys.__stdout__
        output = captured_output.getvalue()
        self.assertIn("path", output)
        self.assertIn("Adam_optimizer", output)
        self.assertIn("directional_focus_decoding", output)

        # Test with a sample dictionary
        sample_data = {"key1": "value1", "key2": {"subkey1": "subvalue1"}}
        self.parser.print_tree(sample_data)

    def test_dataset_config_generator(self):
        generator = self.parser._ConfigParser__dataset_config_generator()
        for config in generator:
            self.assertIn("fold_idx", config)
            self.assertIn("exg_path", config)

    def test_model_config_generator(self):
        generator = self.parser._ConfigParser__model_config_generator()
        for config in generator:
            self.assertTrue(
                any(
                    model_name in config
                    for model_name in self.parser._model_config
                    if model_name != "trainer_config"
                )
            )

    def test_task_config_generator(self):
        generator = self.parser._ConfigParser__task_config_generator()
        for config in generator:
            self.assertIn("task_name", config)
            self.assertIn("type", config)
            self.assertIn("target", config)
            self.assertIn("cross_validation", config)

    def test_all_config_generator(self):
        generator = self.parser._ConfigParser__all_config_generator()
        for config_dict in generator:
            self.assertIn("dataset_config", config_dict)
            self.assertIn("model_config", config_dict)
            self.assertIn("optimizer_config", config_dict)
            self.assertIn("task_config", config_dict)
            self.assertIn("fold_idx", config_dict["dataset_config"])
            self.assertIn("exg_path", config_dict["dataset_config"])
            self.assertTrue(
                any(
                    model_name in config_dict["model_config"]
                    for model_name in self.parser._model_config
                    if model_name != "trainer_config"
                )
            )
            self.assertIn("name", config_dict["optimizer_config"])
            self.assertIn("config", config_dict["optimizer_config"])
            self.assertIn("name", config_dict["lr_scheduler_config"])
            self.assertIn("config", config_dict["lr_scheduler_config"])
            self.assertIn("task_name", config_dict["task_config"])
            self.assertIn("type", config_dict["task_config"])
            self.assertIn("target", config_dict["task_config"])
            self.assertIn("cross_validation", config_dict["task_config"])

    def test_len(self):
        self.assertEqual(
            len(self.parser),
            sum(1 for _ in self.parser._ConfigParser__all_config_generator()),
        )

    def test_dataset_config(self):
        self.assertIn("path", self.parser._dataset_config)
        self.assertIn("cross_validation", self.parser._dataset_config)

    def test_model_config(self):
        self.assertIn("deformer", self.parser._model_config)

    def test_optimizer_config(self):
        self.assertEqual(len(self.parser._optimizer_config), 1)
        optimizer_name, optimizer_config = next(
            iter(self.parser._optimizer_config.items())
        )
        self.assertEqual(optimizer_name, "Adam_optimizer")
        self.assertIn("config", optimizer_config)

    def test_lr_scheduler_config(self):
        self.assertEqual(len(self.parser._lr_scheduler_config), 1)
        scheduler_name, scheduler_config = next(
            iter(self.parser._lr_scheduler_config.items())
        )
        self.assertEqual(scheduler_name, "CosineAnnealingLR_scheduler")
        self.assertIn("config", scheduler_config)

    def test_task_config(self):
        self.assertIn("directional_focus_decoding", self.parser._task_config)
        self.assertNotIn("envelope_reconstruction", self.parser._task_config)
        self.assertNotIn("mel_reconstruction", self.parser._task_config)


if __name__ == "__main__":
    unittest.main()
