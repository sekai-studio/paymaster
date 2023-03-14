
from dataclasses import dataclass
from typing import Iterable, List, Union

@dataclass
class PaidCall:
    to_addr: int
    selector: int
    payer_addr: int
    calldata: List[int]

PaidCalls = Union[PaidCall, Iterable[PaidCall]]