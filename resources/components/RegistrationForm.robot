*** Settings ***
Documentation    Component object for the "Registration Form" modal, shared by Add and Edit.
Library          Browser
Resource         ../common/data.robot

*** Variables ***
${RF_MODAL}     css=div[role='dialog']
${RF_FORM}      id=userForm
${RF_SUBMIT}    id=submit
${RF_CLOSE}     css=.modal-content button.btn-close
${RF_INVALID}   css=#userForm input:invalid
&{RF_FIELDS}    first_name=id=firstName    last_name=id=lastName    age=id=age
...             email=id=userEmail         salary=id=salary         department=id=department

*** Keywords ***
Registration Form Should Be Open
    Wait For Elements State    ${RF_FORM}    visible    timeout=${TIMEOUT}

Fill Registration Form
    [Arguments]    &{employee}
    FOR    ${field}    ${value}    IN    &{employee}
        Fill Text    ${RF_FIELDS}[${field}]    ${value}
    END

Get Registration Form Values
    &{values}=    Create Dictionary
    FOR    ${field}    ${locator}    IN    &{RF_FIELDS}
        ${values}[${field}]=    Get Property    ${locator}    value
    END
    RETURN    ${values}

Submit Registration Form
    Click    ${RF_SUBMIT}

Close Registration Form
    Click    ${RF_CLOSE}
    Registration Form Should Be Closed

Registration Form Should Be Closed
    Wait For Elements State    ${RF_MODAL}    detached    timeout=${TIMEOUT}

Registration Form Should Be Rejected
    [Documentation]    After a refused submit, the form gets "was-validated" and stays open.
    Get Attribute    ${RF_FORM}    class    contains    was-validated
    Registration Form Should Be Open

Registration Field Should Be Invalid
    [Arguments]    ${field}
    ${valid}=    Evaluate JavaScript    ${RF_FIELDS}[${field}]    (input) => input.checkValidity()
    Should Not Be True    ${valid}    Field '${field}' was accepted

All Registration Fields Should Be Invalid
    ${count}=    Get Length    ${RF_FIELDS}
    Get Element Count    ${RF_INVALID}    ==    ${count}
