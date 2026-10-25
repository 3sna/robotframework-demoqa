# DemoQA Web Tables Automation

Automated UI tests for the DemoQA Web Tables page, written with Robot Framework,
Browser Library and Playwright, using the Page Object Model and Gherkin-style
scenarios (Given / When / Then).

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
| The search box filters the table | TC22 |
| The table is displayed with the default employees (smoke) | TC01 |

How the checks work:

- **Exact data**: every column of the row (first name, last name, age, email,
  salary, department) is compared with the expected value. The row count is
  also checked, to catch duplicates or unexpected deletions.
- **No page reload**: before each test, a flag is set on `window`. A page
  reload would erase it, so the test checks that the flag and the URL are
  still there after the action.
- **Independent tests**: each scenario starts by reloading the page, which
  restores DemoQA's 3 default employees. Any scenario can run alone.

## Project structure

    resources/
      common/
        data.robot               Test data: URL, browser, employees by alias
        browser.robot            Browser lifecycle, "no page reload" flag
      pages/
        WebTablesPage.robot      Page object: table, Add button, search, row icons
      components/
        RegistrationForm.robot   Component object: the Add / Edit modal form
      steps/
        web_tables_steps.robot   Business steps used by the scenarios
    tests/
      __init__.robot             Opens the browser once for the whole run
      features/
        manage_employees.robot   TC01-TC10, TC22
        form_validation.robot    TC11-TC21 (Scenario Outline for negative cases)
    Jenkinsfile                  CI pipeline
    requirements.txt             Pinned Python dependencies

The layers only call the layer below them:

- **Features** contain only Given / When / Then steps: no selector, no Browser
  keyword. Robot Framework ignores the `Given`, `When`, `Then`, `And` and `But`
  prefixes, so each step is written once and works with any of them.
- **Steps** are sentences with embedded arguments, such as
  `the employee "${alias}" is displayed in the table`. They call page and
  component objects only. Employees are referenced by alias (`cierra`,
  `alice`, `alicia`...) and looked up in `&{EMPLOYEES}` in `data.robot`.
- **Page and component objects** are the only files that know the selectors.
  When DemoQA changes its HTML, only these files need an update. The form is a
  component because the same modal is used to add and to edit.

Example scenario:

    Scenario: TC06 - Edit an employee
        Given the employee "cierra" exists in the table
        When the user replaces "cierra" with "alicia"
        Then the employee "alicia" is displayed in the table
        And the employee "cierra" is not displayed in the table
        And the table contains 3 employees
        And the page has not been reloaded

Tests use tags: `smoke`, `add`, `edit`, `delete`, `search`, `e2e`, `negative`.

## Prerequisites

- Python 3.10 or later (developed with Python 3.13)
- Git
- No separate Node.js install is needed: `robotframework-browser[bb]` bundles it

| | macOS | Linux (Debian / Ubuntu) | Windows |
|---|---|---|---|
| Install Python | [python.org](https://www.python.org/downloads/) installer, or `brew install python@3.13` | `sudo apt install python3 python3-venv python3-pip` | [python.org](https://www.python.org/downloads/) installer, tick "Add python.exe to PATH" |
| Python command | `python3` (`/usr/bin/python3` is 3.9: use the python.org or Homebrew one) | `python3` (check `python3 --version` is 3.10+) | `py -3.13` (Python launcher) |
| Virtual env scripts | `.venv/bin/` | `.venv/bin/` | `.venv\Scripts\` |
| Browser system libraries | Not needed | Needed: `--with-deps` (uses `sudo`) | Not needed |

## Setup

### macOS

    git clone https://github.com/3sna/robotframework-demoqa.git
    cd robotframework-demoqa
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    rfbrowser install chromium

### Linux

    git clone https://github.com/3sna/robotframework-demoqa.git
    cd robotframework-demoqa
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    rfbrowser install --with-deps chromium

`--with-deps` installs the system libraries Chromium needs (it asks for the
`sudo` password). Without them, the browser fails to start with a "missing
shared libraries" error.

On a server without a display, always run the tests headless
(`--variable HEADLESS:True`).

### Windows (PowerShell)

    git clone https://github.com/3sna/robotframework-demoqa.git
    cd robotframework-demoqa
    py -3.13 -m venv .venv
    .venv\Scripts\Activate.ps1
    pip install -r requirements.txt
    rfbrowser install chromium

If PowerShell refuses to run `Activate.ps1`, allow local scripts once:

    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

In `cmd.exe`, activate with `.venv\Scripts\activate.bat` instead.

## Run the tests

With the virtual environment activated, the commands are the same on every OS.

All tests, with a visible browser:

    robot tests/

Headless, as in CI:

    robot --variable HEADLESS:True tests/

One test by ID:

    robot --test "*TC06 -*" tests/

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

### Agent OS

The pipeline detects the agent OS with `isUnix()`: it uses `sh` on macOS and
Linux, and `bat` on Windows, with the matching virtual env path. The Python
command is chosen as follows:

| Agent | Default `PYTHON` |
|---|---|
| macOS | `/usr/local/bin/python3.13` (python.org installer) |
| Linux | `python3` |
| Windows | `py -3.13` |

If Python is installed elsewhere, set a `PYTHON` environment variable on the
node (Manage Jenkins > Nodes > the node > Configure > Environment variables),
for example `/opt/homebrew/bin/python3.13` for Homebrew on Apple Silicon, or
`C:\Python313\python.exe` on Windows. It takes precedence over the defaults.

Per-OS notes for the agent:

- **macOS**: nothing else to install.
- **Linux**: the Jenkins user usually cannot use `sudo`, so the pipeline does
  not install the browser system libraries. Install them once on the agent,
  as an admin, from a checkout of the project:

      python3 -m venv /tmp/rfb && /tmp/rfb/bin/pip install -r requirements.txt
      sudo /tmp/rfb/bin/rfbrowser install --with-deps chromium

  On a Docker agent, use an image that already has them, such as
  `mcr.microsoft.com/playwright`.
- **Windows**: the agent needs PowerShell (used to clear old reports) and the
  Python launcher `py`, installed by default with the python.org installer.
  If Jenkins runs as a Windows service, install Python "for all users" so the
  service account can find it.

### Flaky tests: re-run failed tests

By default the pipeline runs every test once, so a single failure fails the
build. If a test fails now and then on the same code (a flaky test, for
example a modal that is slow to close on the CI agent), the pipeline can run
the failed tests a second time and merge both results:

1. `robot` runs the tests as usual.
2. If some tests failed, `robot --rerunfailed reports/output.xml` runs only
   those tests again, into `reports/rerun.xml`.
3. `rebot --merge` combines both runs into `reports/output.xml`, `log.html`
   and `report.html`. A test that passes the second time is marked PASS, with
   the message "Test has been re-executed and results merged" and its first
   failure. A test that fails twice stays FAIL, and so does the build.

Use it as a temporary measure: a re-run hides the symptom, not the cause.
Check the merged report for re-executed tests, and fix them.

To enable it, replace the `script:` of the `sh(...)` and `bat(...)` calls in
the `Run Robot Framework Tests` stage of the `Jenkinsfile`.

macOS and Linux (`sh`):

```groovy
result = sh(
    script: '''
        # Jenkins runs sh with -e: keep going after a failed run
        set +e
        if [ "$TEST_ID" = "All" ] || [ -z "$TEST_ID" ]; then
            set -- tests/
        else
            set -- --test "*$TEST_ID -*" tests/
        fi
        .venv/bin/robot --outputdir reports --variable HEADLESS:True "$@"
        status=$?
        if [ $status -ne 0 ] && [ -f reports/output.xml ]; then
            .venv/bin/robot --outputdir reports --output rerun.xml \
                --log NONE --report NONE --variable HEADLESS:True \
                --rerunfailed reports/output.xml tests/
            .venv/bin/rebot --outputdir reports --output output.xml \
                --merge reports/output.xml reports/rerun.xml
            status=$?
        fi
        exit $status
    ''',
    returnStatus: true
)
```

Windows (`bat`):

```groovy
result = bat(
    script: '''
        set FILTER=
        if not "%TEST_ID%"=="All" if not "%TEST_ID%"=="" set FILTER=--test "*%TEST_ID% -*"
        .venv\\Scripts\\robot --outputdir reports --variable HEADLESS:True %FILTER% tests
        set STATUS=%ERRORLEVEL%
        if "%STATUS%"=="0" goto done
        if not exist reports\\output.xml goto done
        .venv\\Scripts\\robot --outputdir reports --output rerun.xml --log NONE --report NONE --variable HEADLESS:True --rerunfailed reports\\output.xml tests
        .venv\\Scripts\\rebot --outputdir reports --output output.xml --merge reports\\output.xml reports\\rerun.xml
        set STATUS=%ERRORLEVEL%
        :done
        exit /b %STATUS%
    ''',
    returnStatus: true
)
```

The exit code is the merged result (`rebot` returns the number of failed
tests), so `ROBOT_EXIT_CODE` and the build status stay correct. The
`post` section needs no change: it publishes the merged `reports/output.xml`.
