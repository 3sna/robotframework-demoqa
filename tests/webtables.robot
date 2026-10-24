
*** Settings ***
Library    Browser
Suite Setup       Open DemoQA Web Tables
Suite Teardown    Close Browser

*** Variables ***
${URL}    https://demoqa.com/webtables

*** Test Cases ***
TC01 - Web Tables Page Is Accessible
    Wait For Elements State    id=addNewRecordButton    visible    timeout=20s
    Wait For Elements State    id=searchBox    visible    timeout=20s
    Wait For Elements State    .rt-tbody    visible    timeout=20s

*** Keywords ***
Open DemoQA Web Tables
    New Browser    chromium    headless=False
    New Context
    New Page    ${URL}
    Wait For Elements State    id=addNewRecordButton    visible    timeout=30s
