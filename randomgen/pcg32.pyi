from randomgen.common import BitGenerator
from randomgen.typing import IntegerSequenceSeed, SeedMode

class PCG32(BitGenerator):
    def __init__(
        self,
        seed: IntegerSequenceSeed | None = ...,
        inc: int = ...,
        *,
        mode: SeedMode | None = ...
    ) -> None: ...
    def seed(self, seed: IntegerSequenceSeed | None = ..., inc: int = ...) -> None: ...
    @property
    def state(self) -> dict[str, str | dict[str, int]]: ...
    @state.setter
    def state(self, value: dict[str, str | dict[str, int]]) -> None: ...
    def advance(self, delta: int) -> None: ...
    def jump(self, iter: int = ...) -> PCG32: ...
    def jumped(self, iter: int = ...) -> PCG32: ...