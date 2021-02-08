from typing import Dict, Optional, Union

import numpy as np

from randomgen.common import BitGenerator
from randomgen.typing import IntegerSequenceSeed, SeedMode

class Xoroshiro128(BitGenerator):
    def __init__(
        self,
        seed: Optional[IntegerSequenceSeed] = None,
        *,
        mode: SeedMode = None,
        plusplus: bool = False
    ) -> None: ...
    def seed(self, seed: Optional[IntegerSequenceSeed] = None) -> None: ...
    def jump(self, iter: int = 1) -> Xoroshiro128: ...
    def jumped(self, iter: int = 1) -> Xoroshiro128: ...
    @property
    def state(self) -> Dict[str, Union[str, np.ndarray, bool, int]]: ...
    @state.setter
    def state(self, value: Dict[str, Union[str, np.ndarray, bool, int]]) -> None: ...
