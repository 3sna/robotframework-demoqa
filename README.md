# DemoQA Web Tables Automation

Automated UI testing for the DemoQA Web Tables page using Robot Framework,
Browser Library, and Playwright.

## Prerequisites

- Python 3.13 or a compatible Python 3 version
- Node.js, as required by the Browser Library installation
- Google Chrome or the Chromium browser installed by Browser Library

## Setup

Clone this repository and enter the project directory:

    git clone https://github.com/3sna/robotframework-demoqa.git
    cd robotframework-demoqa

Create and activate a virtual environment:

    python3 -m venv .venv
    source .venv/bin/activate

Install the test dependencies:

    pip install "robotframework-browser[bb]"
    rfbrowser install chromium

## Run the test

    robot tests/webtables.robot

The test opens the DemoQA Web Tables page and verifies that the Add button
and table are visible.

Robot Framework generates output.xml, log.html, and report.html after a run.
These generated files are excluded from Git.

## Target website

https://demoqa.com/webtables
