import numpy as np

from randomgen.common import BitGenerator
from randomgen.typing import IntegerSequenceSeed, SeedMode

class SFMT(BitGenerator):
    def __init__(
        self, seed: IntegerSequenceSeed | None = ..., *, mode: SeedMode | None = ...
    ) -> None: ...
    def seed(self, seed: IntegerSequenceSeed | None = ...) -> None: ...
    def jump(self, iter: int = ...) -> SFMT: ...
    def jumped(self, iter: int = ...) -> SFMT: ...
    @property
    def state(
        self,
    ) -> dict[str, str | int | np.ndarray | dict[str, int | np.ndarray]]: ...
    @state.setter
    def state(
        self,
        value: dict[str, str | int | np.ndarray | dict[str, int | np.ndarray]],
    ) -> None: ...