*** Settings ***
Documentation    Business keywords for the DemoQA Web Tables page.
...              Employees are passed as dictionaries whose keys match ${FIELDS} and ${COLUMNS}.
Library          Browser
Resource         data.robot
Resource         locators.robot

*** Keywords ***
# --- Browser and page ---

Open Web Tables
    New Browser    ${BROWSER}    headless=${HEADLESS}
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    ${URL}
    Web Tables Should Be Displayed

Reload Web Tables
    [Documentation]    Restores the default rows so that every test starts from the same state.
    Reload
    Web Tables Should Be Displayed
    Mark Page As Not Reloaded

Close Web Tables
    Close Browser

Web Tables Should Be Displayed
    Wait For Elements State    ${ADD_BUTTON}    visible    timeout=${TIMEOUT}
    Wait For Elements State    ${TABLE}    visible    timeout=${TIMEOUT}

Mark Page As Not Reloaded
    [Documentation]    Sets a flag on window. A page reload would erase it.
    Evaluate JavaScript    ${None}    () => { window.__noReload = true; }

Page Should Not Have Reloaded
    [Documentation]    The table must update in real time, without reloading the page.
    ${flag}=    Evaluate JavaScript    ${None}    () => window.__noReload === true
    Should Be True    ${flag}    The page was reloaded
    Get Url    ==    ${URL}

# --- Employee form ---

Open Add Employee Form
    Click    ${ADD_BUTTON}
    Wait For Elements State    ${FORM}    visible    timeout=${TIMEOUT}

Open Edit Form For Employee
    [Arguments]    ${email}
    ${row}=    Employee Row Locator    ${email}
    Click    ${row}//span[@title='Edit']
    Wait For Elements State    ${FORM}    visible    timeout=${TIMEOUT}

Fill Employee Form
    [Arguments]    &{employee}
    FOR    ${field}    ${value}    IN    &{employee}
        Fill Text    ${FIELDS}[${field}]    ${value}
    END

Submit Employee Form
    Click    ${SUBMIT_BUTTON}

Submit Employee Form Successfully
    Submit Employee Form
    Wait For Elements State    ${MODAL}    detached    timeout=${TIMEOUT}

Close Employee Form
    Click    ${MODAL_CLOSE}
    Wait For Elements State    ${MODAL}    detached    timeout=${TIMEOUT}

Employee Form Should Contain
    [Arguments]    &{employee}
    FOR    ${field}    ${value}    IN    &{employee}
        Get Property    ${FIELDS}[${field}]    value    ==    ${value}
    END

Field Should Be Invalid
    [Arguments]    ${field}
    ${valid}=    Evaluate JavaScript    ${FIELDS}[${field}]    (input) => input.checkValidity()
    Should Not Be True    ${valid}    Field '${field}' was accepted

Employee Form Should Still Be Open
    Wait For Elements State    ${FORM}    visible    timeout=${TIMEOUT}

# --- Employee actions ---

Add Employee
    [Arguments]    &{employee}
    Open Add Employee Form
    Fill Employee Form    &{employee}
    Submit Employee Form Successfully

Edit Employee
    [Arguments]    ${current_email}    &{new_values}
    Open Edit Form For Employee    ${current_email}
    Fill Employee Form    &{new_values}
    Submit Employee Form Successfully

Delete Employee
    [Arguments]    ${email}
    ${row}=    Employee Row Locator    ${email}
    Click    ${row}//span[@title='Delete']
    Wait For Elements State    ${row}    detached    timeout=${TIMEOUT}

# --- Table checks ---

Employee Row Locator
    [Arguments]    ${email}
    RETURN    xpath=//tbody/tr[td[${COLUMNS}[email]][normalize-space()='${email}']]

Get Row Count
    ${count}=    Get Element Count    ${TABLE_ROWS}
    RETURN    ${count}

Row Count Should Be
    [Arguments]    ${expected}
    Get Element Count    ${TABLE_ROWS}    ==    ${expected}

Employee Should Be Displayed
    [Documentation]    Exactly one row matches the email, and each column equals the expected value.
    [Arguments]    &{employee}
    ${row}=    Employee Row Locator    ${employee}[email]
    Wait For Elements State    ${row}    visible    timeout=${TIMEOUT}
    Get Element Count    ${row}    ==    1
    FOR    ${field}    ${value}    IN    &{employee}
        Get Text    ${row}/td[${COLUMNS}[${field}]]    ==    ${value}
    END

Employee Should Not Be Displayed
    [Arguments]    ${email}
    ${row}=    Employee Row Locator    ${email}
    Get Element Count    ${row}    ==    0
