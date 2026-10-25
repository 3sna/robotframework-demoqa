*** Settings ***
Documentation    Page object for https://demoqa.com/webtables: the table, its toolbar and row actions.
...              Only this file knows the page selectors.
Library          Browser
Resource         ../common/data.robot

*** Variables ***
${WT_ADD_BUTTON}    id=addNewRecordButton
${WT_SEARCH_BOX}    id=searchBox
${WT_TABLE}         css=table
${WT_ROWS}          css=tbody tr
&{WT_COLUMNS}       first_name=1    last_name=2    age=3    email=4    salary=5    department=6

*** Keywords ***
Web Tables Page Should Be Loaded
    Wait For Elements State    ${WT_ADD_BUTTON}    visible    timeout=${TIMEOUT}
    Wait For Elements State    ${WT_TABLE}    visible    timeout=${TIMEOUT}

Reset Web Tables Page
    [Documentation]    DemoQA keeps the table in memory: a reload restores the default rows.
    Reload
    Web Tables Page Should Be Loaded

Click Add Button
    Click    ${WT_ADD_BUTTON}

Search Table
    [Arguments]    ${text}
    Fill Text    ${WT_SEARCH_BOX}    ${text}

Row Locator
    [Arguments]    ${email}
    RETURN    xpath=//tbody/tr[td[${WT_COLUMNS}[email]][normalize-space()='${email}']]

Click Edit Icon
    [Arguments]    ${email}
    ${row}=    Row Locator    ${email}
    Click    ${row}//span[@title='Edit']

Click Delete Icon
    [Arguments]    ${email}
    ${row}=    Row Locator    ${email}
    Click    ${row}//span[@title='Delete']
    Wait For Elements State    ${row}    detached    timeout=${TIMEOUT}

Get Row Count
    ${count}=    Get Element Count    ${WT_ROWS}
    RETURN    ${count}

Count Rows For Email
    [Arguments]    ${email}
    ${row}=    Row Locator    ${email}
    ${count}=    Get Element Count    ${row}
    RETURN    ${count}

Get Row Values
    [Documentation]    Returns the row as a dictionary with the same keys as an employee.
    [Arguments]    ${email}
    ${row}=    Row Locator    ${email}
    Wait For Elements State    ${row}    visible    timeout=${TIMEOUT}
    &{values}=    Create Dictionary
    FOR    ${field}    ${index}    IN    &{WT_COLUMNS}
        ${values}[${field}]=    Get Text    ${row}/td[${index}]
    END
    RETURN    ${values}
