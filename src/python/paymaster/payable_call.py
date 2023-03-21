
from dataclasses import dataclass
from typing import Iterable, List, Union

@dataclass
class PayableCall:
    to_addr: int
    selector: int
    payer_addr: int
    calldata: List[int]

PayableCalls = Union[PayableCall, Iterable[PayableCall]]