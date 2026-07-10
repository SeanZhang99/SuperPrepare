import sys
import os
from pathlib import Path


def wav2vec

def run(path: os.PathLike):
    path = Path(path).resolve() / "stimuli" / "wav"
    for file in path.glob("*.wav"):
        pass