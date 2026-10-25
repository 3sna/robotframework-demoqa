*** Settings ***
Documentation    Negative cases: the form refuses missing or invalid data,
...              and no employee is added.
Resource         ../resources/webtables_keywords.robot
Test Tags        negative    add
Test Template    Invalid Employee Should Be Rejected

*** Test Cases ***                                FIELD         VALUE
TC11 - Reject Missing First Name                 first_name    ${EMPTY}
TC12 - Reject Missing Last Name                  last_name     ${EMPTY}
TC13 - Reject Missing Email                      email         ${EMPTY}
TC14 - Reject Missing Age                        age           ${EMPTY}
TC15 - Reject Missing Salary                     salary        ${EMPTY}
TC16 - Reject Missing Department                 department    ${EMPTY}
TC17 - Reject Email Without At Sign              email         alice.example.com
TC18 - Reject Email Without Domain Extension     email         alice@example
TC19 - Reject Non Numeric Age                    age           thirty
TC20 - Reject Non Numeric Salary                 salary        50k

TC21 - Reject Empty Form
    [Documentation]    Submitting an empty form flags all 6 fields as invalid.
    [Template]    NONE
    ${rows_before}=    Get Row Count
    Open Add Employee Form
    Submit Employee Form
    Get Element Count    ${INVALID_INPUTS}    ==    6
    Employee Form Should Still Be Open
    Close Employee Form
    Row Count Should Be    ${rows_before}

*** Keywords ***
Invalid Employee Should Be Rejected
    [Documentation]    Fills a valid employee, replaces one field, and checks the form refuses it.
    [Arguments]    ${field}    ${value}
    ${rows_before}=    Get Row Count
    Open Add Employee Form
    Fill Employee Form    &{NEW_EMPLOYEE}
    Fill Text    ${FIELDS}[${field}]    ${value}
    Submit Employee Form
    Field Should Be Invalid    ${field}
    Employee Form Should Still Be Open
    Close Employee Form
    Employee Should Not Be Displayed    ${NEW_EMPLOYEE}[email]
    Row Count Should Be    ${rows_before}
