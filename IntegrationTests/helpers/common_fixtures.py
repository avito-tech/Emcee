import os

import git
import pytest

from IntegrationTests.helpers.Directory import Directory
from IntegrationTests.helpers.bash import bash
from IntegrationTests.helpers.cache import using_pycache
from IntegrationTests.helpers.fixture_types.ExecutableFixture import ExecutableFixture


@pytest.fixture(scope="session")
def generated_package_fixture(request, repo_root):
    def make():
        bash(command='make generate', current_directory=repo_root.path)

        yield None

    yield from using_pycache(
        request=request,
        key="generated_package_fixture",
        make=make
    )

@pytest.fixture(scope="session")
def avito_runner(repo_root, request):
    def make():
        bash(command='make build', current_directory=repo_root.path)

        yield ExecutableFixture(
            path=f'{repo_root.path}/.build/x86_64-apple-macosx10.10/debug/AvitoRunner'
        )

    yield from using_pycache(
        request=request,
        key="avito_runner",
        make=make
    )

@pytest.fixture(scope="session")
def repo_root() -> 'Directory':
    any_path_inside = __file__
    git_repo = git.Repo(any_path_inside, search_parent_directories=True)

    return Directory(
        path=git_repo.git.rev_parse("--show-toplevel")
    )

@pytest.fixture(scope="session")
def fbsimctl_url():
    return os.environ.get('FBSIMCTL_URL', 'https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.2/fbsimctl_20181120T145356.zip')


@pytest.fixture(scope="session")
def fbxctest_url():
    return os.environ.get('FBXCTEST_URL', 'https://github.com/beefon/FBSimulatorControl/releases/download/avito0.0.2/fbxctest_20181120T145305.zip')
