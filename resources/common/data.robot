*** Variables ***
${URL}         https://demoqa.com/webtables
${BROWSER}     chromium
# Override from the command line: --variable HEADLESS:True
${HEADLESS}    False
${TIMEOUT}     15s

# Employees are referenced by alias in the scenarios: "cierra", "alice"...
&{CIERRA}      first_name=Cierra    last_name=Vega        age=39    email=cierra@example.com
...            salary=10000         department=Insurance
&{ALDEN}       first_name=Alden     last_name=Cantrell    age=45    email=alden@example.com
...            salary=12000         department=Compliance
&{KIERRA}      first_name=Kierra    last_name=Gentry      age=29    email=kierra@example.com
...            salary=2000          department=Legal
&{ALICE}       first_name=Alice     last_name=Martin      age=30    email=alice.martin@example.com
...            salary=50000         department=QA
&{ALICIA}      first_name=Alicia    last_name=Durand      age=31    email=alicia.durand@example.com
...            salary=62000         department=Engineering
&{EMPLOYEES}   cierra=${CIERRA}    alden=${ALDEN}    kierra=${KIERRA}    alice=${ALICE}    alicia=${ALICIA}
