*** Settings ***
Documentation     User story: as a user, I can manage a dynamic table to add, edit
...               and delete employees, so that the list stays up to date.
...               https://demoqa.com/webtables
Resource          ../resources/webtables_keywords.robot
Suite Setup       Open Web Tables
Suite Teardown    Close Web Tables
Test Setup        Reload Web Tables
