*** Settings ***
Documentation    Browser lifecycle, shared by every page object.
Library          Browser
Resource         data.robot

*** Keywords ***
Open Application
    New Browser    ${BROWSER}    headless=${HEADLESS}
    # Wide viewport: on DemoQA, long rows push the action icons under the right-hand column
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    ${URL}

Close Application
    Close Browser

Mark Page As Not Reloaded
    [Documentation]    Sets a flag on window. A page reload would erase it.
    Evaluate JavaScript    ${None}    () => { window.__noReload = true; }

Page Has Not Been Reloaded
    ${flag}=    Evaluate JavaScript    ${None}    () => window.__noReload === true
    Should Be True    ${flag}    The page was reloaded
