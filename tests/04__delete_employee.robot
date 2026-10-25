*** Settings ***
Documentation    Acceptance criteria: the user deletes an employee with the delete icon.
Resource         ../resources/webtables_keywords.robot
Test Tags        delete

*** Test Cases ***
TC08 - Delete Employee Successfully
    [Documentation]    Only the deleted row disappears, without a page reload.
    [Tags]    smoke
    ${rows_before}=    Get Row Count
    Delete Employee    ${EXISTING_EMPLOYEE}[email]
    Employee Should Not Be Displayed    ${EXISTING_EMPLOYEE}[email]
    Row Count Should Be    ${rows_before - 1}
    Employee Should Be Displayed    &{OTHER_EMPLOYEE}
    Page Should Not Have Reloaded

TC09 - Delete A Newly Added Employee
    [Documentation]    An employee added during the session can be deleted.
    Add Employee    &{NEW_EMPLOYEE}
    ${rows_before}=    Get Row Count
    Delete Employee    ${NEW_EMPLOYEE}[email]
    Employee Should Not Be Displayed    ${NEW_EMPLOYEE}[email]
    Row Count Should Be    ${rows_before - 1}
