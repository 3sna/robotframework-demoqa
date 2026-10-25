#!/usr/bin/env python3
"""Summarize Robot Framework results from output.xml, log.html or report.html.

Usage:
    analyze_results.py PATH [PATH ...] [--json] [--all-tests]

Each PATH is a results folder or a single file. In a folder, output.xml is
preferred (most detail), then log.html, then report.html. Several PATHs are
treated as several runs of the same suite and compared (flaky tests, new
failures). Only the Python standard library is used.
"""

import argparse
import base64
import html
import json
import re
import sys
import xml.etree.ElementTree as ET
import zlib
from datetime import datetime
from pathlib import Path

STATUS_CODES = {0: "FAIL", 1: "PASS", 2: "SKIP", 3: "NOT RUN"}
LEVEL_CODES = {0: "TRACE", 1: "DEBUG", 2: "INFO", 3: "WARN", 4: "ERROR", 5: "FAIL", 6: "SKIP"}
BODY_TYPES = {
    0: "KEYWORD", 1: "SETUP", 2: "TEARDOWN", 3: "FOR", 4: "ITERATION", 5: "IF",
    6: "ELSE IF", 7: "ELSE", 8: "RETURN", 9: "VAR", 10: "TRY", 11: "EXCEPT",
    12: "FINALLY", 13: "WHILE", 14: "GROUP", 15: "CONTINUE", 16: "BREAK", 17: "ERROR",
}
XML_BODY_TAGS = {"kw", "for", "iter", "if", "branch", "try", "while", "group", "var",
                 "return", "continue", "break", "error"}

# First matching pattern wins. Categories are hints for the analysis, not verdicts.
FAILURE_CATEGORIES = [
    ("parent-setup", r"Parent suite setup failed|Setup failed:"),
    ("timeout-waiting-element", r"TimeoutError|Timeout \d+ms exceeded|waiting for locator|did not become"),
    ("locator-ambiguous", r"strict mode violation|resolved to \d+ elements"),
    ("element-not-found", r"Could not find element|No element found|element is not attached|not visible|detached"),
    ("click-intercepted", r"intercepts pointer events|not receive pointer events|element is outside of the viewport"),
    ("assertion-mismatch", r"should be|should contain|!=|==|does not match|is not equal|expected"),
    ("browser-or-environment", r"Browser has been closed|Target page, context or browser has been closed|"
                               r"net::ERR_|ECONNREFUSED|grpc|Could not connect|missing shared librar|playwright"),
    ("robot-syntax-or-keyword", r"No keyword with name|got multiple values|expected \d+ arguments?|"
                                r"Variable '.*' not found|Non-existing variable|Resource file .* does not exist"),
    ("timeout-test", r"Test timeout .* exceeded|Keyword timeout .* exceeded"),
]
IMG_SRC = re.compile(r"""<img[^>]+src=["']([^"']+)["']""", re.IGNORECASE)
TAG_RE = re.compile(r"<[^>]+>")


def plain(text):
    """HTML message to plain text."""
    return html.unescape(TAG_RE.sub("", text or "")).strip()


def categorize(message):
    for name, pattern in FAILURE_CATEGORIES:
        if re.search(pattern, message or "", re.IGNORECASE):
            return name
    return "other"


def new_test(name, longname, test_id, tags, status, elapsed_ms, message, doc=""):
    return {
        "id": test_id, "name": name, "longname": longname, "tags": tags,
        "status": status, "elapsed_s": round(elapsed_ms / 1000, 2),
        "message": plain(message), "doc": plain(doc),
        "failure_path": [], "fail_messages": [], "warnings": [], "screenshots": [],
    }


# --- output.xml -----------------------------------------------------------------

def parse_output_xml(path):
    root = ET.parse(path).getroot()
    run = {"source": str(path), "format": "output.xml",
           "generated": root.get("generated", ""), "generator": root.get("generator", ""),
           "tests": [], "suite_failures": [], "errors": []}

    def elapsed_ms(status):
        return float(status.get("elapsed", 0)) * 1000 if status is not None else 0

    def walk_body(node, test, path):
        """Records the deepest failing keyword chain, messages and screenshots."""
        for child in node:
            if child.tag == "msg":
                level, text = child.get("level"), child.text or ""
                for src in IMG_SRC.findall(text):
                    test["screenshots"].append(src)
                if level in ("FAIL", "ERROR"):
                    test["fail_messages"].append(plain(text))
                elif level == "WARN":
                    test["warnings"].append(plain(text))
            elif child.tag in XML_BODY_TAGS:
                status = child.find("status")
                failed = status is not None and status.get("status") == "FAIL"
                label = describe_xml_item(child)
                if failed and not test["_path_done"]:
                    path.append(label)
                walk_body(child, test, path)
                if failed and not test["_path_done"]:
                    test["failure_path"] = list(path)
                    test["_path_done"] = True

    def describe_xml_item(item):
        kind = item.get("type") or item.tag.upper()
        if item.tag == "kw":
            args = [a.text or "" for a in item.findall("arg")]
            owner = item.get("owner")
            name = f"{owner}.{item.get('name')}" if owner else item.get("name", "")
            prefix = "" if kind in ("KW", "KEYWORD") else f"[{kind}] "
            return (prefix + name + ("    " + "    ".join(args) if args else "")).strip()
        values = [v.text or "" for v in item.findall("var")] + [v.text or "" for v in item.findall("value")]
        flavor = item.get("flavor") or item.get("condition") or ""
        return f"[{kind}] {flavor} {' '.join(values)}".strip()

    def walk_suite(suite, parents):
        longname = ".".join(parents + [suite.get("name", "")])
        status = suite.find("status")
        for kw in suite.findall("kw"):
            kw_status = kw.find("status")
            if kw_status is not None and kw_status.get("status") == "FAIL":
                run["suite_failures"].append({
                    "suite": longname, "type": kw.get("type", "KEYWORD"), "keyword": kw.get("name"),
                    "message": plain(kw_status.text or (status.text if status is not None else "")),
                })
        for test in suite.findall("test"):
            t_status = test.find("status")
            t = new_test(
                test.get("name", ""), f"{longname}.{test.get('name', '')}", test.get("id", ""),
                [tag.text or "" for tag in test.findall("tag")],
                t_status.get("status") if t_status is not None else "NOT RUN",
                elapsed_ms(t_status), t_status.text if t_status is not None else "",
                (test.findtext("doc") or ""),
            )
            t["_path_done"] = False
            walk_body(test, t, [])
            del t["_path_done"]
            run["tests"].append(t)
        for child in suite.findall("suite"):
            walk_suite(child, parents + [suite.get("name", "")])

    walk_suite(root.find("suite"), [])
    for msg in root.findall("./errors/msg"):
        run["errors"].append({"level": msg.get("level"), "message": plain(msg.text)})
    return run


# --- log.html / report.html -------------------------------------------------------

JS_ASSIGN = re.compile(r'^(window\.(?:output\["(\w+)"\]|sPart(\d+))) = (.*);\s*$', re.MULTILINE)
JS_HEX = re.compile(r'(?<!\\)((?:\\\\)*)\\x([0-9a-fA-F]{2})')
SPART_REF = re.compile(r'window\.sPart(\d+)')


def js_to_json(text):
    text = JS_HEX.sub(lambda m: m.group(1) + "\\u00" + m.group(2), text)
    return SPART_REF.sub(lambda m: f'"__sPart{m.group(1)}__"', text)


def parse_html(path):
    content = Path(path).read_text(encoding="utf-8", errors="replace")
    output, parts, strings = {}, {}, []
    for match in JS_ASSIGN.finditer(content):
        key, out_key, part_no, value = match.groups()
        if out_key == "strings":
            concat = re.match(r'window\.output\["strings"\]\.concat\((.*)\)$', value, re.DOTALL)
            if concat:
                strings.extend(json.loads(js_to_json(concat.group(1))))
        elif out_key:
            try:
                output[out_key] = json.loads(js_to_json(value))
            except json.JSONDecodeError:
                pass
        else:
            parts[int(part_no)] = json.loads(js_to_json(value))
    if "suite" not in output:
        raise ValueError(f"{path}: no Robot Framework data found (is it a log.html or report.html?)")

    def resolve(node):
        if isinstance(node, str):
            ref = re.fullmatch(r"__sPart(\d+)__", node)
            return resolve(parts[int(ref.group(1))]) if ref else node
        if isinstance(node, list):
            return [resolve(item) for item in node]
        return node

    def text(index):
        if not isinstance(index, int) or index >= len(strings):
            return ""
        raw = strings[index]
        if raw.startswith("*"):
            return html.unescape(raw[1:])
        return html.unescape(zlib.decompress(base64.b64decode(raw)).decode("utf-8"))

    base_millis = output.get("baseMillis", 0)
    generated = output.get("generated")
    run = {"source": str(path), "format": Path(path).name,
           "generated": datetime.fromtimestamp((base_millis + generated) / 1000).isoformat()
           if generated is not None else "",
           "generator": "", "tests": [], "suite_failures": [], "errors": []}

    def status_of(model):
        message = text(model[3]) if len(model) > 3 else ""
        return STATUS_CODES.get(model[0], "?"), model[2], message

    def walk_body(items, test, path):
        for item in items:
            if len(item) == 3:  # message: (timestamp, level, text)
                level, msg = LEVEL_CODES.get(item[1], "?"), text(item[2])
                for src in IMG_SRC.findall(msg):
                    test["screenshots"].append(src)
                if level in ("FAIL", "ERROR"):
                    test["fail_messages"].append(plain(msg))
                elif level == "WARN":
                    test["warnings"].append(plain(msg))
                continue
            kind, name, owner, args = BODY_TYPES.get(item[0], "?"), text(item[1]), text(item[2]), text(item[5])
            failed = item[8][0] == 0
            label = f"{owner}.{name}" if owner else name
            if kind != "KEYWORD":
                label = f"[{kind}] {label}"
            label = (label + ("    " + args if args else "")).strip()
            if failed and not test["_path_done"]:
                path.append(label)
            walk_body(item[9], test, path)
            if failed and not test["_path_done"]:
                test["failure_path"] = list(path)
                test["_path_done"] = True

    def walk_suite(suite, parents, suite_id):
        name = text(suite[0])
        longname = ".".join(parents + [name])
        _, _, suite_message = status_of(suite[5])
        for fixture in suite[8]:
            if fixture[8][0] == 0:
                run["suite_failures"].append({
                    "suite": longname, "type": BODY_TYPES.get(fixture[0], "?"),
                    "keyword": text(fixture[1]), "message": plain(suite_message),
                })
        for index, test in enumerate(suite[7], 1):
            status, elapsed, message = status_of(test[5])
            t = new_test(text(test[0]), f"{longname}.{text(test[0])}", f"{suite_id}-t{index}",
                         [text(tag) for tag in test[3]], status, elapsed, message, text(test[2]))
            t["_path_done"] = False
            walk_body(test[6] if len(test) > 6 else [], t, [])
            del t["_path_done"]
            run["tests"].append(t)
        for index, child in enumerate(suite[6], 1):
            walk_suite(child, parents + [name], f"{suite_id}-s{index}")

    walk_suite(resolve(output["suite"]), [], "s1")
    for error in resolve(output.get("errors", [])):
        run["errors"].append({"level": LEVEL_CODES.get(error[1], "?"), "message": plain(text(error[2]))})
    if Path(path).name.startswith("report"):
        run["note"] = "report.html has no keyword details: failure paths, log messages and screenshots are missing."
    return run


# --- loading and summarizing ------------------------------------------------------

def load(path):
    path = Path(path).expanduser()
    if path.is_dir():
        for candidate in ("output.xml", "log.html", "report.html"):
            if (path / candidate).exists():
                path = path / candidate
                break
        else:
            raise FileNotFoundError(f"{path}: no output.xml, log.html or report.html")
    run = parse_output_xml(path) if path.suffix == ".xml" else parse_html(path)
    folder = path.parent
    for test in run["tests"]:
        test["category"] = categorize(" ".join([test["message"]] + test["fail_messages"])) \
            if test["status"] == "FAIL" else ""
        resolved = []
        for src in dict.fromkeys(test["screenshots"]):
            file = (folder / src).resolve()
            resolved.append(str(file) + ("" if file.exists() else "  (file not found)"))
        test["screenshots"] = resolved
    counts = {s: sum(t["status"] == s for t in run["tests"]) for s in ("PASS", "FAIL", "SKIP", "NOT RUN")}
    run["totals"] = {"total": len(run["tests"]), **counts,
                     "elapsed_s": round(sum(t["elapsed_s"] for t in run["tests"]), 2)}
    tags = {}
    for test in run["tests"]:
        for tag in test["tags"]:
            stat = tags.setdefault(tag, {"PASS": 0, "FAIL": 0, "SKIP": 0})
            if test["status"] in stat:
                stat[test["status"]] += 1
    run["tags"] = dict(sorted(tags.items()))
    run["other_files"] = sorted(p.name for p in folder.iterdir()
                                if p.suffix in (".txt", ".log", ".zip") and p.is_file())
    return run


def compare(runs):
    """Status of every test across runs, oldest first.

    Tests are matched on "suite.test" rather than the full long name, because the
    top-level suite name depends on the folder robot was started from.
    """
    def key(test):
        return ".".join(test["longname"].split(".")[-2:])

    names = list(dict.fromkeys(key(t) for run in runs for t in run["tests"]))
    matrix = {name: [next((t["status"] for t in run["tests"] if key(t) == name), "-")
                     for run in runs] for name in names}
    flaky = [n for n, s in matrix.items() if "PASS" in s and "FAIL" in s]
    always_failing = [n for n, s in matrix.items() if all(x == "FAIL" for x in s)]
    new_failures = [n for n, s in matrix.items() if s[-1] == "FAIL" and "PASS" in s[:-1]]
    fixed = [n for n, s in matrix.items() if s[-1] == "PASS" and "FAIL" in s[:-1]]
    return {"matrix": matrix, "flaky": flaky, "always_failing": always_failing,
            "new_failures": new_failures, "fixed": fixed}


def print_markdown(runs, comparison, all_tests):
    for number, run in enumerate(runs, 1):
        totals = run["totals"]
        print(f"## Run {number}: {run['source']}")
        print(f"- Format: {run['format']}  |  Generated: {run['generated']}  {run['generator']}")
        print(f"- Tests: {totals['total']}  |  PASS {totals['PASS']}  |  FAIL {totals['FAIL']}  |  "
              f"SKIP {totals['SKIP']}  |  NOT RUN {totals['NOT RUN']}  |  test time {totals['elapsed_s']}s")
        if run.get("note"):
            print(f"- Note: {run['note']}")
        if run["other_files"]:
            print(f"- Other files next to the report: {', '.join(run['other_files'])}")
        print("\n### Tags")
        print("| Tag | PASS | FAIL | SKIP |\n|---|---|---|---|")
        for tag, stat in run["tags"].items():
            print(f"| {tag} | {stat['PASS']} | {stat['FAIL']} | {stat['SKIP']} |")
        for failure in run["suite_failures"]:
            print(f"\n**Suite {failure['type'].lower()} failed** in `{failure['suite']}` "
                  f"(`{failure['keyword']}`): {failure['message']}")
        failed = [t for t in run["tests"] if t["status"] == "FAIL"]
        print(f"\n### Failed tests ({len(failed)})")
        for t in failed:
            print(f"\n#### {t['name']}  ({t['id']}, {t['elapsed_s']}s)")
            print(f"- Suite: `{t['longname'].rsplit('.', 1)[0]}`  |  Tags: {', '.join(t['tags']) or '-'}")
            print(f"- Category hint: {t['category']}")
            print(f"- Message: {t['message'][:1500]}")
            if t["failure_path"]:
                print("- Failing keyword chain:")
                for depth, step in enumerate(t["failure_path"]):
                    print(f"  {'  ' * depth}- {step}")
            extra = [m for m in t["fail_messages"] if m and m not in t["message"]]
            for msg in extra[:3]:
                print(f"- Log FAIL message: {msg[:800]}")
            for warning in t["warnings"][:3]:
                print(f"- Warning: {warning[:500]}")
            for shot in t["screenshots"]:
                print(f"- Screenshot: {shot}")
            if t["doc"]:
                print(f"- Test documentation: {t['doc'][:500]}")
        slowest = sorted(run["tests"], key=lambda t: t["elapsed_s"], reverse=True)[:5]
        print("\n### Slowest tests")
        for t in slowest:
            print(f"- {t['elapsed_s']}s  {t['status']}  {t['name']}")
        if run["errors"]:
            print("\n### Execution errors and warnings")
            for error in run["errors"]:
                print(f"- {error['level']}: {error['message'][:500]}")
        if all_tests:
            print("\n### All tests")
            print("| ID | Test | Status | Time (s) | Tags |\n|---|---|---|---|---|")
            for t in run["tests"]:
                print(f"| {t['id']} | {t['name']} | {t['status']} | {t['elapsed_s']} | {', '.join(t['tags'])} |")
        print()
    if comparison:
        print(f"## Comparison across {len(runs)} runs (oldest first)")
        for key, title in (("new_failures", "New failures in the latest run"), ("fixed", "Fixed in the latest run"),
                           ("flaky", "Flaky (passed and failed)"), ("always_failing", "Failing in every run")):
            print(f"- {title}: {', '.join(comparison[key]) or 'none'}")
        print("\n| Test | " + " | ".join(f"Run {i}" for i in range(1, len(runs) + 1)) + " |")
        print("|---|" + "---|" * len(runs))
        for name, statuses in comparison["matrix"].items():
            if len(set(statuses)) > 1 or all_tests:
                print(f"| {name} | " + " | ".join(statuses) + " |")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="+", help="results folder(s) or output.xml / log.html / report.html")
    parser.add_argument("--json", action="store_true", help="print JSON instead of Markdown")
    parser.add_argument("--all-tests", action="store_true", help="also list passing tests")
    args = parser.parse_args()
    runs = []
    for path in args.paths:
        try:
            runs.append(load(path))
        except (OSError, ValueError, ET.ParseError) as error:
            print(f"Could not read {path}: {error}", file=sys.stderr)
    if not runs:
        return 1
    runs.sort(key=lambda r: r["generated"])
    comparison = compare(runs) if len(runs) > 1 else None
    if args.json:
        json.dump({"runs": runs, "comparison": comparison}, sys.stdout, indent=2, ensure_ascii=False)
    else:
        print_markdown(runs, comparison, args.all_tests)
    return 0


if __name__ == "__main__":
    sys.exit(main())
