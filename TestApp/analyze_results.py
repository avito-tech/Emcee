import os
import unittest
from xml.etree import ElementTree


def check_file_exists(path):
    if not os.path.exists(path):
        raise AssertionError("Expected to have file at: {path}".format(path=path))


def get_test_cases_from_xml_file(path):
    tree = ElementTree.parse(path)
    root = tree.getroot()
    cases = []
    for case in root.findall('.//testcase'):
        if not case.findall('skipped'):
            case_dict = case.attrib.copy()
            if len(case):
                for child in case:
                    print("child: " + str(child))
                    case_dict[child.tag] = child.attrib.copy()
            cases.append(case_dict)
    return cases


class IntegrationTests(unittest.TestCase):
    @staticmethod
    def test_check_reports_exist():
        check_file_exists("test-results/iphone_se_ios_103.json")
        check_file_exists("test-results/iphone_se_ios_103.xml")
        check_file_exists("test-results/trace.combined.json")
        check_file_exists("test-results/junit.combined.xml")

    def test_junit_contents(self):
        iphone_se_junit = get_test_cases_from_xml_file("test-results/iphone_se_ios_103.xml")
        self.assertEqual(len(iphone_se_junit), 4)

        successful_tests = set([item["name"] for item in iphone_se_junit if item.get("failure") is None])
        failed_tests = set([item["name"] for item in iphone_se_junit if item.get("failure") is not None])

        self.assertEqual(successful_tests, {"testSlowTest", "testAlwaysSuccess", "testQuickTest"})
        self.assertEqual(failed_tests, {"testAlwaysFails"})
