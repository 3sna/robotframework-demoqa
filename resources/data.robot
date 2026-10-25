*** Variables ***
${URL}             https://demoqa.com/webtables
${BROWSER}         chromium
# Override from the command line: --variable HEADLESS:True
${HEADLESS}        False
${TIMEOUT}         15s

# DemoQA keeps the table in memory: a reload restores these 3 rows
${DEFAULT_ROWS}    3
&{EXISTING_EMPLOYEE}    first_name=Cierra    last_name=Vega        age=39    email=cierra@example.com
...                     salary=10000         department=Insurance
&{OTHER_EMPLOYEE}       first_name=Alden     last_name=Cantrell    age=45    email=alden@example.com
...                     salary=12000         department=Compliance

&{NEW_EMPLOYEE}         first_name=Alice     last_name=Martin      age=30    email=alice.martin@example.com
...                     salary=50000         department=QA
&{UPDATED_EMPLOYEE}     first_name=Alicia    last_name=Durand      age=31    email=alicia.durand@example.com
...                     salary=62000         department=Engineering
&{EMPTY_EMPLOYEE}       first_name=${EMPTY}    last_name=${EMPTY}    age=${EMPTY}    email=${EMPTY}
...                     salary=${EMPTY}        department=${EMPTY}
