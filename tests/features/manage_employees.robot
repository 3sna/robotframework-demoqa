*** Settings ***
Documentation    Feature: Manage employees
...              As a user, I want to add, edit and delete employees in the table,
...              so that the list stays up to date.
Resource         ../../resources/steps/web_tables_steps.robot
Test Setup       Given the user is on the Web Tables page

*** Test Cases ***
Scenario: TC01 - The table shows the default employees
    [Tags]    smoke
    Then the table contains 3 employees
    And the employee "cierra" is displayed in the table
    And the employee "alden" is displayed in the table
    And the employee "kierra" is displayed in the table

Scenario: TC02 - The Add button opens an empty form
    [Tags]    add
    When the user opens the Add form
    Then the form is empty

Scenario: TC03 - Add a new employee
    [Tags]    smoke    add
    When the user adds the employee "alice"
    Then the employee "alice" is displayed in the table
    And the table contains 4 employees
    And the page has not been reloaded

Scenario: TC04 - Closing the Add form adds nothing
    [Tags]    add
    Given the user opens the Add form
    When the user fills the form with "alice"
    And the user closes the form
    Then the employee "alice" is not displayed in the table
    And the table contains 3 employees

Scenario: TC05 - The Edit form is pre-filled
    [Tags]    edit
    When the user opens the Edit form of "cierra"
    Then the form shows the data of "cierra"

Scenario: TC06 - Edit an employee
    [Tags]    smoke    edit
    Given the employee "cierra" exists in the table
    When the user replaces "cierra" with "alicia"
    Then the employee "alicia" is displayed in the table
    And the employee "cierra" is not displayed in the table
    And the table contains 3 employees
    And the page has not been reloaded

Scenario: TC07 - Closing the Edit form keeps the employee unchanged
    [Tags]    edit
    Given the user opens the Edit form of "cierra"
    When the user fills the form with "alicia"
    And the user closes the form
    Then the employee "cierra" is displayed in the table
    And the employee "alicia" is not displayed in the table

Scenario: TC08 - Delete an employee
    [Tags]    smoke    delete
    Given the employee "cierra" exists in the table
    When the user deletes the employee "cierra"
    Then the employee "cierra" is not displayed in the table
    And the employee "alden" is displayed in the table
    And the table contains 2 employees
    And the page has not been reloaded

Scenario: TC09 - Delete a newly added employee
    [Tags]    delete
    Given the user has added the employee "alice"
    When the user deletes the employee "alice"
    Then the employee "alice" is not displayed in the table
    And the table contains 3 employees

Scenario: TC10 - Add, edit and delete the same employee
    [Tags]    e2e    add    edit    delete
    Given the user has added the employee "alice"
    When the user replaces "alice" with "alicia"
    And the user deletes the employee "alicia"
    Then the employee "alicia" is not displayed in the table
    And the table contains 3 employees
    And the page has not been reloaded

Scenario: TC22 - Search filters the table
    [Tags]    search
    When the user searches for "Legal"
    Then the table contains 1 employees
    And the employee "kierra" is displayed in the table
