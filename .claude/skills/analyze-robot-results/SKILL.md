---
name: analyze-robot-results
description: Analyze Robot Framework test results (log.html, report.html, output.xml) and explain why tests failed. Use this skill whenever the user shares or mentions a Robot Framework report or log, a "reports" folder, a failing Jenkins / CI build of Robot tests, a fail screenshot, or asks things like "why did TC06 fail", "analyze my test results", "is this test flaky", "compare these builds" or "what broke since the last run", even if they don't name the file format.
---

# Analyze Robot Framework results

The goal is a short, evidence-based diagnosis: what failed, why, whether it is
a product bug, a test bug, an environment problem or a flaky test, and what to
change. The raw HTML reports are large (hundreds of KB of compressed
JavaScript), so never read them directly: the bundled script decodes them.

## 1. Find the results

Results usually sit together in one folder: `output.xml`, `log.html`,
`report.html`, sometimes `playwright-log.txt` and `browser/screenshot/*.png`.
Look where the user points, then in the usual places:

- the project's output folder (`reports/`, or `output-dir` in `robot.toml`)
- a Jenkins workspace: `~/.jenkins/workspace/<job>/reports/`
- downloaded build artifacts, often in `~/Downloads/`

When several folders or builds are given, analyze them together: the script
compares them.

## 2. Run the analyzer

```bash
python3 <this skill's folder>/scripts/analyze_results.py <folder-or-file> [more ...]
```

- A folder uses `output.xml` if present (most detail), else `log.html`, else
  `report.html`. A file path forces that file.
- Several paths are treated as runs of the same suite, sorted by date: the
  output adds new failures, fixed tests, flaky tests and a status matrix.
- `--all-tests` also lists passing tests. `--json` gives the same data as JSON.
- Only the Python standard library is needed.

For each failed test the output gives the message, the failing keyword chain
(deepest failing keyword last), FAIL and WARN log messages, screenshot paths,
a category hint and suite setup / teardown failures. `report.html` alone has
no keyword details: say so and ask for `log.html` or `output.xml` if the cause
is unclear.

## 3. Investigate each failure

The script tells you where a test failed. Find out why before you conclude:

1. **Look at the screenshot.** Open the PNG with the Read tool. It often shows
   the answer at once: a modal still open, an ad or cookie banner over the
   button, an error page, an unexpected value.
2. **Read the failing keyword in the project.** Search the keyword name from
   the chain (for example in `resources/`) and read the locator, the timeout
   and the step before it. A failure in a "should be closed / detached" check
   often means the action before it (a click on Submit) did not work.
3. **Check the time.** A test that takes exactly the timeout (15.36s for a
   15s timeout) waited for something that never happened. Very short failures
   point to a missing element or a wrong argument.
4. **Use the other files.** `playwright-log.txt` (Browser Library) has one
   JSON object per line, with a `test_id` field matching the test ID in the
   analyzer output: filter on it rather than on the time, which is in UTC
   while Robot logs use local time. Look for errors, failed requests or
   navigation during the failing test.
5. **Compare runs.** If the same test passed in another run with the same
   code, it is likely flaky or environment-related, not a code bug.
6. **When needed, check the live page** (browser tool, or the rf-mcp server
   if the project has one) to confirm whether a locator still matches.

Category hints and what they usually mean:

| Hint | Usual cause | What to check |
|---|---|---|
| `parent-setup` | Suite setup failed, so every test in it failed | Report it once as the root cause, not per test |
| `timeout-waiting-element` | An element never reached the expected state | Screenshot; the previous step; locator; slow page or overlay |
| `locator-ambiguous` | The selector matches several elements | Make the locator more specific |
| `element-not-found` | Selector out of date, or the element is hidden | Live page HTML; a wait before the action |
| `click-intercepted` | Something covers the element (ad, banner, modal) | Screenshot; scroll or close the overlay |
| `assertion-mismatch` | The app returned a different value | Expected vs actual: product bug, or wrong test data? |
| `browser-or-environment` | Browser, network or CI machine problem | Same test in other runs; CI agent setup |
| `robot-syntax-or-keyword` | Error in the test code itself | The keyword call and its arguments |
| `timeout-test` | A test or keyword timeout was reached | What was still running |

The hint comes from pattern matching on the message, so confirm it with the
evidence above.

## 4. Classify and report

Give each failure one verdict, with a confidence level:

- **Product bug**: the application behaves against the requirement, and the
  test is right. Needs clear evidence (expected vs actual, screenshot).
- **Test bug**: wrong locator, timing, data, or a dependency between tests.
- **Environment**: browser, network, CI agent, third-party site (ads, outage).
- **Flaky**: passes and fails on the same code; name the likely race.

Say "likely" when the evidence is indirect, and say what would confirm it.
Do not call something a product bug only because a test failed.

Write the report in the user's language, with this structure:

```markdown
# Test results: <run name or date>

**Verdict:** <one sentence: e.g. 21/22 passed, 1 failure caused by a test timing issue, not a product bug>

| Total | Passed | Failed | Skipped | Duration |
|---|---|---|---|---|

## Failures
### <Test ID and name>
- **What failed:** <the step in plain words, with the keyword>
- **Evidence:** <message, screenshot finding, timing, other runs>
- **Cause:** <verdict> (<confidence>) — <explanation>
- **Fix:** <concrete change, with the file and keyword to edit>

## Trends (only with several runs)
<new failures, fixed tests, flaky tests>

## Recommendations
<at most 3 actions, most important first>
```

When everything passed, keep it to the verdict, the table, the slowest tests
and any warnings from the execution errors section.

Offer to apply the fix when it is in the project's test code, but don't edit
files unless the user asks.
