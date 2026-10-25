*** Settings ***
Documentation    The Web Tables page shows the employee table and its Add form.
Resource         ../resources/webtables_keywords.robot
Test Tags        smoke

*** Test Cases ***
TC01 - Employee Table Is Displayed With Default Employees
    [Documentation]    The table and the Add button are visible, with the default employees.
    Web Tables Should Be Displayed
    Row Count Should Be    ${DEFAULT_ROWS}
    Employee Should Be Displayed    &{EXISTING_EMPLOYEE}
    Employee Should Be Displayed    &{OTHER_EMPLOYEE}

TC02 - Add Button Opens An Empty Employee Form
    [Documentation]    Clicking "Add" opens the form, with every field empty.
    [Tags]    add
    Open Add Employee Form
    Employee Form Should Contain    &{EMPTY_EMPLOYEE}
    Close Employee Form
