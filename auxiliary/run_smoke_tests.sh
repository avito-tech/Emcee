#!/bin/bash

set -e

which pytest || pip3 install pytest

cd `dirname $0`
cd `git rev-parse --show-toplevel`
cd "IntegrationTests"

pip3 install -r "requirements.txt"
pytest --cache-clear
