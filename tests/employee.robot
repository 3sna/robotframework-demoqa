*** Settings ***
Library           Browser
Library           BuiltIn
Resource          ../resources/helper.robot
Suite Setup       Open Web Tables
Suite Teardown    Close Web Tables

*** Test Cases ***
TC01 - Display Employee Table
    Wait For Elements State    css=table    visible    timeout=15s
    Get Element    id=addNewRecordButton

TC02 - Open Add Employee Form
    Click    id=addNewRecordButton
    Wait For Elements State    id=firstName    visible    timeout=10s
    Get Element    id=submit
    Close Employee Form

TC03 - Add Employee Successfully
    Click    id=addNewRecordButton
    Wait For Elements State    id=firstName    visible    timeout=10s
    Fill Employee Form
    ...    ${FIRST_NAME}
    ...    ${LAST_NAME}
    ...    ${EMAIL}
    ...    ${AGE}
    ...    ${SALARY}
    ...    ${DEPARTMENT}
    Click    id=submit
    ${row}=    Find Employee Row    ${EMAIL}
    Wait For Elements State    ${row}    visible    timeout=15s
    ${text}=    Get Text    ${row}
    Should Contain    ${text}    ${FIRST_NAME}
    Should Contain    ${text}    ${LAST_NAME}
    Should Contain    ${text}    ${EMAIL}
    Should Contain    ${text}    ${DEPARTMENT}

TC04 - Reject Missing Required Fields
    Click    id=addNewRecordButton
    Wait For Elements State    id=firstName    visible    timeout=10s
    ${rows_before}=    Get Element Count    css=tbody tr
    Click    id=submit
    Get Attribute    id=userForm    class    contains    was-validated
    Wait For Elements State    id=firstName    visible    timeout=5s
    Get Element Count    css=#userForm input:invalid    ==    6
    Close Employee Form
    Get Element Count    css=tbody tr    ==    ${rows_before}

TC05 - Edit Employee
    ${row}=    Find Employee Row    ${EMAIL}
    Wait For Elements State    ${row}    visible    timeout=10s
    Click    xpath=//tbody/tr[td[normalize-space()='${EMAIL}']]//span[@title='Edit']
    Wait For Elements State    id=firstName    visible    timeout=10s
    Fill Text    id=firstName    Updated
    Click    id=submit
    Wait For Elements State    css=div[role='dialog']    detached    timeout=10s
    ${updated_row}=    Find Employee Row    ${EMAIL}
    Wait For Elements State    ${updated_row}    visible    timeout=10s
    ${text}=    Get Text    ${updated_row}
    Should Contain    ${text}    Updated

TC06 - Delete Employee
    ${row}=    Find Employee Row    ${EMAIL}
    Wait For Elements State    ${row}    visible    timeout=10s
    Click    xpath=//tbody/tr[td[normalize-space()='${EMAIL}']]//span[@title='Delete']
    Wait For Elements State    ${row}    detached    timeout=10s