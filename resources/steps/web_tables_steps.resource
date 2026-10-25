*** Settings ***
Documentation    Step definitions: business sentences used by the feature files.
...              Robot Framework ignores the Given/When/Then/And/But prefixes, so each step
...              is written once and can be used with any of them.
...              Steps call page and component objects only, never Browser directly.
Library          Collections
Resource         ../common/browser.resource
Resource         ../pages/WebTablesPage.resource
Resource         ../components/RegistrationForm.resource


*** Keywords ***
# --- Context ---

the user is on the Web Tables page
    Reset Web Tables Page
    Mark Page As Not Reloaded

the employee "${alias}" exists in the table
    the employee "${alias}" is displayed in the table

the user has added the employee "${alias}"
    the user adds the employee "${alias}"

# --- Actions ---

the user opens the Add form
    Click Add Button
    Registration Form Should Be Open

the user opens the Edit form of "${alias}"
    ${employee}=    Employee    ${alias}
    Click Edit Icon    ${employee}[email]
    Registration Form Should Be Open

the user fills the form with "${alias}"
    ${employee}=    Employee    ${alias}
    Fill Registration Form    &{employee}

the user fills the form with "${alias}" but the ${field} "${value}"
    the user fills the form with "${alias}"
    Fill Registration Form    ${field}=${value}

the user submits the form
    Submit Registration Form

the user closes the form
    Close Registration Form

the user adds the employee "${alias}"
    the user opens the Add form
    the user fills the form with "${alias}"
    the user submits the form
    Registration Form Should Be Closed

the user replaces "${old}" with "${new}"
    the user opens the Edit form of "${old}"
    the user fills the form with "${new}"
    the user submits the form
    Registration Form Should Be Closed

the user deletes the employee "${alias}"
    ${employee}=    Employee    ${alias}
    Click Delete Icon    ${employee}[email]

the user searches for "${text}"
    Search Table    ${text}

# --- Outcomes ---

the employee "${alias}" is displayed in the table
    ${expected}=    Employee    ${alias}
    ${count}=    Count Rows For Email    ${expected}[email]
    Should Be Equal As Integers    ${count}    1    Expected exactly one row for "${alias}"
    ${actual}=    Get Row Values    ${expected}[email]
    Dictionaries Should Be Equal    ${actual}    ${expected}

the employee "${alias}" is not displayed in the table
    ${employee}=    Employee    ${alias}
    ${count}=    Count Rows For Email    ${employee}[email]
    Should Be Equal As Integers    ${count}    0    "${alias}" is still in the table

the table contains ${expected} employees
    ${count}=    Get Row Count
    Should Be Equal As Integers    ${count}    ${expected}

the form shows the data of "${alias}"
    ${expected}=    Employee    ${alias}
    ${actual}=    Get Registration Form Values
    Dictionaries Should Be Equal    ${actual}    ${expected}

the form is empty
    ${actual}=    Get Registration Form Values
    FOR    ${field}    ${value}    IN    &{actual}
        Should Be Empty    ${value}    Field '${field}' is not empty
    END

the form is rejected
    Registration Form Should Be Rejected

every field is invalid
    All Registration Fields Should Be Invalid

the ${field} field is invalid
    Registration Field Should Be Invalid    ${field}

the page has not been reloaded
    Page Has Not Been Reloaded

# --- Helpers ---

Employee
    [Documentation]    Looks up an employee by alias in ${EMPLOYEES}.
    [Arguments]    ${alias}
    Dictionary Should Contain Key    ${EMPLOYEES}    ${alias}    Unknown employee alias "${alias}"
    RETURN    ${EMPLOYEES}[${alias}]
