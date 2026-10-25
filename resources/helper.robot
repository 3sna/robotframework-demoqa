*** Settings ***
Library     Browser
Resource    data.robot

*** Keywords ***
Open Web Tables
    New Browser    ${BROWSER}    headless=False
    New Page    ${URL}
    Wait For Elements State    id=addNewRecordButton    visible    timeout=30s
    Wait For Elements State    css=.rt-table    visible    timeout=30s

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
    ${row}=    Set Variable    xpath=//div[contains(@class,'rt-tr') and .//div[normalize-space()='${email}']]
    RETURN    ${row}

Close Employee Form
    ${count}=    Get Element Count    xpath=//div[@role='dialog' and contains(@class,'show')]
    IF    ${count} > 0
        Click    id=closeLargeModal
    END

Close Web Tables
    Close Browser