*** Settings ***
Documentation    End-to-end: add, edit and delete the same employee in one session,
...              with the table updated in real time after each action.
Resource         ../resources/webtables_keywords.robot
Test Tags        e2e    add    edit    delete

*** Test Cases ***
TC10 - Add Edit And Delete An Employee Without Page Reload
    ${rows_before}=    Get Row Count
    Add Employee    &{NEW_EMPLOYEE}
    Employee Should Be Displayed    &{NEW_EMPLOYEE}
    Edit Employee    ${NEW_EMPLOYEE}[email]    &{UPDATED_EMPLOYEE}
    Employee Should Be Displayed    &{UPDATED_EMPLOYEE}
    Employee Should Not Be Displayed    ${NEW_EMPLOYEE}[email]
    Delete Employee    ${UPDATED_EMPLOYEE}[email]
    Employee Should Not Be Displayed    ${UPDATED_EMPLOYEE}[email]
    Row Count Should Be    ${rows_before}
    Page Should Not Have Reloaded
