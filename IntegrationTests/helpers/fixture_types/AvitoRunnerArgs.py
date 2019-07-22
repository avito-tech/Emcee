import textwrap
from typing import List

from IntegrationTests.helpers.fixture_types.EmceePluginFixture import EmceePluginFixture
from IntegrationTests.helpers.fixture_types.ExecutableFixture import ExecutableFixture
from IntegrationTests.helpers.fixture_types.IosAppFixture import IosAppFixture
from IntegrationTests.helpers.Directory import Directory

class AvitoRunnerArgs:
    def __init__(
            self,
            avito_runner: ExecutableFixture,
            fbsimctl_url: str,
            fbxctest_url: str,
            junit_path: str,
            trace_path: str,
            test_destinations: [str],
            temp_folder: str,
            current_directory: Directory,
            test_arg_file_path: str,
            number_of_simulators: int = 1,
            plugins: [EmceePluginFixture] = None,
            single_test_timeout: int = 300,
    ):
        if plugins is None:
            plugins = []

        self.avito_runner = avito_runner
        self.fbsimctl_url = fbsimctl_url
        self.fbxctest_url = fbxctest_url
        self.junit_path = junit_path
        self.trace_path = trace_path
        self.test_destinations = test_destinations
        self.temp_folder = temp_folder
        self.test_arg_file_path = test_arg_file_path
        self.number_of_simulators = number_of_simulators
        self.plugins = plugins
        self.single_test_timeout = single_test_timeout
        self.current_directory = current_directory

    def command(self):
        args: List[str] = [
            self.avito_runner.path, 'runTests',
            '--fbsimctl', self.fbsimctl_url,
            '--fbxctest', self.fbxctest_url,
            '--junit', self.junit_path,
            '--number-of-simulators', str(self.number_of_simulators),
            '--single-test-timeout', str(self.single_test_timeout),
            '--temp-folder', self.temp_folder,
            '--test-arg-file', self.test_arg_file_path,
            '--trace', self.trace_path
        ]

        for plugin in self.plugins:
            args.extend(['--plugin', plugin.path])

        for destination in self.test_destinations:
            args.extend(['--test-destinations', destination])

        return args
