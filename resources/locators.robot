*** Variables ***
${ADD_BUTTON}        id=addNewRecordButton
${TABLE}             css=table
${TABLE_ROWS}        css=tbody tr
${FORM}              id=userForm
${MODAL}             css=div[role='dialog']
${MODAL_CLOSE}       css=.modal-content button.btn-close
${SUBMIT_BUTTON}     id=submit
${INVALID_INPUTS}    css=#userForm input:invalid

# Form field per employee attribute
&{FIELDS}     first_name=id=firstName    last_name=id=lastName    age=id=age
...           email=id=userEmail         salary=id=salary         department=id=department

# Table column index per employee attribute
&{COLUMNS}    first_name=1    last_name=2    age=3    email=4    salary=5    department=6
