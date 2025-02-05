from collections.abc import Callable, Iterable
from typing import Any
from datasets.classifyFilter import get_classification_filter
from datasets.eeg_dataset import EegDataset
from datasets.metadata_processing import Callable, ClassifyMetaDataElement
from datasets.metadata_processing import MetaDataElement


class EegClassifyBaseDataset(EegDataset):
    metadata_cls = ClassifyMetaDataElement

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        required_meta_fields = ["label"]
        self._validate_kwargs(kwargs["metadata_fields"], required_meta_fields)

    def __getitem__(self, idx):
        meta, exg = super().__getitem__(idx).values()
        label = getattr(meta, "label", None)
        return {"meta": meta, "exg": exg, "label": label}

    @classmethod
    def meta_filter_func_parser(
        cls,
        meta_filter_func: (
            Callable[
                [
                    ClassifyMetaDataElement,
                ],
                ClassifyMetaDataElement | None,
            ]
            | None
        ),
        **kwargs
    ):
        assert "target" in kwargs, "target must be provided in kwargs"
        if meta_filter_func is None:
            meta_filter_func = get_classification_filter(kwargs["target"])
        return meta_filter_func
