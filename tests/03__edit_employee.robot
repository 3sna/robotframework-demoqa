*** Settings ***
Documentation    Acceptance criteria: the user edits an existing employee with the
...              edit icon and updates the data in the form.
Resource         ../resources/webtables_keywords.robot
Test Tags        edit

*** Test Cases ***
TC05 - Edit Form Is Pre-Filled With Employee Data
    [Documentation]    The edit icon opens the form filled with the employee's current data.
    Open Edit Form For Employee    ${EXISTING_EMPLOYEE}[email]
    Employee Form Should Contain    &{EXISTING_EMPLOYEE}
    Close Employee Form

TC06 - Edit Employee Successfully
    [Documentation]    Every column is updated in place, without a duplicate row or a page reload.
    [Tags]    smoke
    ${rows_before}=    Get Row Count
    Edit Employee    ${EXISTING_EMPLOYEE}[email]    &{UPDATED_EMPLOYEE}
    Employee Should Be Displayed    &{UPDATED_EMPLOYEE}
    Employee Should Not Be Displayed    ${EXISTING_EMPLOYEE}[email]
    Row Count Should Be    ${rows_before}
    Page Should Not Have Reloaded

TC07 - Closing The Edit Form Keeps Employee Unchanged
    [Documentation]    Closing the edited form without submitting keeps the original data.
    Open Edit Form For Employee    ${EXISTING_EMPLOYEE}[email]
    Fill Employee Form    &{UPDATED_EMPLOYEE}
    Close Employee Form
    Employee Should Be Displayed    &{EXISTING_EMPLOYEE}
    Employee Should Not Be Displayed    ${UPDATED_EMPLOYEE}[email]
