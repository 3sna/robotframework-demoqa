*** Settings ***
Documentation    Feature: Form validation
...              The form refuses missing or invalid data, and no employee is added.
Resource         ../../resources/steps/web_tables_steps.robot
Test Setup       Given the user is on the Web Tables page
Test Tags        negative    add
Test Template    Scenario Outline: the ${field} "${value}" is rejected

*** Test Cases ***                                         FIELD         VALUE
Scenario: TC11 - Reject missing first name                first_name    ${EMPTY}
Scenario: TC12 - Reject missing last name                 last_name     ${EMPTY}
Scenario: TC13 - Reject missing email                     email         ${EMPTY}
Scenario: TC14 - Reject missing age                       age           ${EMPTY}
Scenario: TC15 - Reject missing salary                    salary        ${EMPTY}
Scenario: TC16 - Reject missing department                department    ${EMPTY}
Scenario: TC17 - Reject email without at sign             email         alice.example.com
Scenario: TC18 - Reject email without domain extension    email         alice@example
# The age field has maxlength=2: a longer value would be truncated
Scenario: TC19 - Reject letters in age                    age           ab
Scenario: TC20 - Reject letters in salary                 salary        50k

Scenario: TC21 - Reject an empty form
    [Template]    NONE
    Given the user opens the Add form
    When the user submits the form
    Then the form is rejected
    And every field is invalid
    When the user closes the form
    Then the table contains 3 employees

*** Keywords ***
Scenario Outline: the ${field} "${value}" is rejected
    Given the user opens the Add form
    When the user fills the form with "alice" but the ${field} "${value}"
    And the user submits the form
    Then the form is rejected
    And the ${field} field is invalid
    When the user closes the form
    Then the employee "alice" is not displayed in the table
    And the table contains 3 employees
