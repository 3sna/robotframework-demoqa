*** Settings ***
Library     Browser
Resource    data.robot

*** Keywords ***
Open Web Tables
    New Browser    ${BROWSER}    headless=False
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    ${URL}
    Wait For Elements State    id=addNewRecordButton    visible    timeout=30s
    Wait For Elements State    css=table    visible    timeout=30s

Fill Employee Form
    [Arguments]    ${first}    ${last}    ${email}    ${age}    ${salary}    ${department}
    Fill Text    id=firstName     ${first}
    Fill Text    id=lastName      ${last}
    Fill Text    id=userEmail     ${email}
    Fill Text    id=age           ${age}
    Fill Text    id=salary        ${salary}
    Fill Text    id=department    ${department}

Find Employee Row
    [Arguments]    ${email}
    ${row}=    Set Variable    xpath=//tbody/tr[td[normalize-space()='${email}']]
    RETURN    ${row}

Close Employee Form
    ${count}=    Get Element Count    xpath=//div[@role='dialog' and contains(@class,'show')]
    IF    ${count} > 0
        Click    css=.modal-content button.btn-close
    END

Close Web Tables
    Close Browser