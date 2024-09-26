from randomgen.common import BitGenerator
from randomgen.typing import IntegerSequenceSeed

class Tyche(BitGenerator):
    def __init__(
        self, seed: IntegerSequenceSeed | None = ..., *, idx: int | None = ...
    ) -> None: ...
    def seed(
        self, seed: IntegerSequenceSeed | None = ..., *, idx: int | None = ...
    ) -> None: ...
    @property
    def state(
        self,
    ) -> dict[str, str | dict[str, int]]: ...
    @state.setter
    def state(self, value: dict[str, str | dict[str, int]]) -> None: ...