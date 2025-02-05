from abc import ABC, abstractmethod
from typing import Any, Iterator, Sequence, Tuple, Union, Dict
from utils import Role

__all__ = ['Provider']

class Provider(ABC):
    # When making a new provider, make sure to add **kwargs or proxy, no_content and other parameters
    @abstractmethod
    def __init__(self, **kwargs):
        ...

    @property
    @abstractmethod
    def models(self) -> Iterator[str]:
        ...
    
    @abstractmethod
    def chat(self, model: Union[str, Any], history: Union[Sequence[Tuple[Union[int, Role], str]], Sequence[Dict['str', 'str']]] = [], tools: Sequence[dict] = []) -> Iterator[str]:
        ...