import collections

import jsonpickle
from typing import Callable


def using_pycache(request, key: str, make: Callable[[], collections.Iterable]):
    cached_json = request.config.cache.get(key, None)

    if cached_json is None:
        for value in make():
            request.config.cache.set(key, jsonpickle.encode(value))
            yield value
    else:
        yield jsonpickle.decode(cached_json)