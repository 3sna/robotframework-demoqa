# DemoQA Web Tables Automation

Automated UI tests for the DemoQA Web Tables page, written in full code with
Robot Framework, Browser Library and Playwright.

Target page: https://demoqa.com/webtables

## User story

> As a user, I want to manage a dynamic table to add, edit and delete
> employee information, so that the list stays up to date.

## Coverage

| Acceptance criterion | Test cases |
|---|---|
| The "Add" button opens a form | TC02 |
| An added employee is visible, with the data entered in the form | TC03, TC10 |
| The edit icon opens the form with the employee's data, and the update is applied | TC05, TC06, TC10 |
| The delete icon removes the employee from the table | TC08, TC09, TC10 |
| The table updates in real time, without a page reload | TC03, TC06, TC08, TC10 |
| Closing a form without submitting changes nothing | TC04, TC07 |
| Missing or invalid data is refused (negative cases) | TC11 to TC21 |
| The table is displayed with the default employees (smoke) | TC01 |

How the checks work:

- **Exact data**: every column of the row (first name, last name, age, email,
  salary, department) is compared with the expected value. The row count is
  also checked, to catch duplicates or unexpected deletions.
- **No page reload**: before each test, a flag is set on `window`. A page
  reload would erase it, so the test checks that the flag and the URL are
  still there after the action.
- **Independent tests**: each test starts by reloading the page, which
  restores DemoQA's 3 default employees. Any test can run alone.

## Project structure

    resources/
      data.robot                 Test data: URL, browser, employees
      locators.robot             Page selectors, form fields, table columns
      webtables_keywords.robot   Business keywords (Add Employee, Edit Employee...)
    tests/
      __init__.robot             Opens the browser once, reloads the page before each test
      01__table_display.robot    TC01-TC02
      02__add_employee.robot     TC03-TC04
      03__edit_employee.robot    TC05-TC07
      04__delete_employee.robot  TC08-TC09
      05__employee_lifecycle.robot  TC10 (end to end)
      06__form_validation.robot  TC11-TC21 (data-driven negative cases)
    Jenkinsfile                  CI pipeline
    requirements.txt             Pinned Python dependencies

Tests use tags: `smoke`, `add`, `edit`, `delete`, `e2e`, `negative`.

## Prerequisites

- Python 3.10 or later (developed with Python 3.13)
- No separate Node.js install is needed: `robotframework-browser[bb]` bundles it

## Setup

    git clone https://github.com/3sna/robotframework-demoqa.git
    cd robotframework-demoqa
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    rfbrowser install chromium

## Run the tests

All tests, with a visible browser:

    robot tests/

Headless, as in CI:

    robot --variable HEADLESS:True tests/

One test by ID:

    robot --test "TC06 *" tests/

By tag:

    robot --include smoke tests/
    robot --include negative tests/

Reports are written to `reports/` (`report.html`, `log.html`, `output.xml`,
plus a screenshot on failure). They are excluded from Git.

## Jenkins

The `Jenkinsfile` installs the dependencies, runs the tests headless and
publishes the Robot Framework report.

The `TEST_ID` parameter selects the tests: `All` (default) runs everything,
otherwise only the test with that ID runs (for example `TC03`).

The job uses "Pipeline script from SCM" on branch `*/main`, with a read-only
GitHub token stored in Jenkins credentials.
