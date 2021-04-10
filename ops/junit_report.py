"""
 Generates JUnit report

 Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0

 2021-03-23 Modified - Nick Gilbert

"""
import sys
import re
import json
sys.path.insert(0, "external")
from junit_xml import TestSuite, TestCase

def generate_junit_report_from_cfn_nag(report):

  total_failures=0

  """Generate Test Case from cfn_nag report"""

  test_cases = []

  for file_findings in report:
    for violation in file_findings["file_results"]['violations']:
      total_failures+=1
      for i,resource_id in enumerate(violation['logical_resource_ids']):

        test_case = TestCase(
          "%s - %s" % (violation['id'], violation['message']),
           classname=resource_id)
  
        test_case.add_failure_info(output="%s#L%s" % (
          file_findings['filename'], violation['line_numbers'][i]))

        test_cases.append(test_case)

  test_suite = TestSuite("cfn-nag test suite", test_cases)

  if total_failures>0:
    f = open("CFN_NAG_FAILURE", "a")
    f.close()      

  return TestSuite.to_xml_string([test_suite], prettyprint=False)

with open(sys.argv[1]) as json_file:
  report = json.load(json_file)
print(generate_junit_report_from_cfn_nag(report))
