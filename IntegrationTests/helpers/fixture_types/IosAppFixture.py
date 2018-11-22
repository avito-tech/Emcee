class IosAppFixture:
    def __init__(self, app_path, ui_tests_runner_path, xctest_bundle_path):
        self.app_path = app_path
        self.ui_tests_runner_path = ui_tests_runner_path
        self.xctest_bundle_path = xctest_bundle_path