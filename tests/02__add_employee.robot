*** Settings ***
Documentation    Acceptance criteria: an employee added through the "Add" form is
...              visible in the table, with the data entered in the form.
Resource         ../resources/webtables_keywords.robot
Test Tags        add

*** Test Cases ***
TC03 - Add Employee Successfully
    [Documentation]    Every column of the new row matches the form, without a page reload.
    [Tags]    smoke
    ${rows_before}=    Get Row Count
    Add Employee    &{NEW_EMPLOYEE}
    Employee Should Be Displayed    &{NEW_EMPLOYEE}
    Row Count Should Be    ${rows_before + 1}
    Page Should Not Have Reloaded

TC04 - Closing The Add Form Does Not Add An Employee
    [Documentation]    Closing the filled form without submitting leaves the table unchanged.
    ${rows_before}=    Get Row Count
    Open Add Employee Form
    Fill Employee Form    &{NEW_EMPLOYEE}
    Close Employee Form
    Employee Should Not Be Displayed    ${NEW_EMPLOYEE}[email]
    Row Count Should Be    ${rows_before}
