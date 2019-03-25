class IosAppFixture:
    def __init__(self, app_path, ui_tests_runner_path, ui_xctest_bundle_path, app_xctest_bundle_path):
        self.app_path = app_path
        self.ui_tests_runner_path = ui_tests_runner_path
        self.ui_xctest_bundle_path = ui_xctest_bundle_path
        self.app_xctest_bundle_path = app_xctest_bundle_path
