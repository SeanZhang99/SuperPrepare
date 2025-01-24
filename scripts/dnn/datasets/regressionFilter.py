from collections.abc import Callable
from .leaveOneOut import MetaDataElement


__all__ = ["get_regression_filter"]


def env(metadata_element: MetaDataElement) -> MetaDataElement | None:
    if "env" in metadata_element.keys():
        return metadata_element
    else:
        return None


def mel(metadata_element: MetaDataElement) -> MetaDataElement | None:
    if "mel" in metadata_element.keys():
        return metadata_element
    else:
        return None


def get_regression_filter(
    filter_name: str,
) -> Callable[[MetaDataElement], MetaDataElement | None]:
    return globals()[filter_name]
