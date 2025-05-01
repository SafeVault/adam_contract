struct Employee {
    id: felt,
    name: felt,
    wallet: felt,
    salary: u128, 
    payment_schedule: felt,  
}

@storage_var
fn employees(id: felt) -> Employee {}

fn add_employee(id: felt, name: felt, wallet: felt, salary: u128, payment_schedule: felt) {
    let employee = Employee {
        id: id,
        name: name,
        wallet: wallet,
        salary: salary,
        payment_schedule: payment_schedule,
    };
    employees::write(id, employee);
}


fn remove_employee(id: felt) {
    employees::write(id, Employee { id: 0, name: 0, wallet: 0, salary: 0, payment_schedule: 0 });
}

fn update_employee(id: felt, name: felt, wallet: felt, salary: u128, payment_schedule: felt) {
    let employee = Employee {
        id: id,
        name: name,
        wallet: wallet,
        salary: salary,
        payment_schedule: payment_schedule,
    };
    employees::write(id, employee);
}


fn execute_payment(id: felt) {
    let employee = employees::read(id);
    assert(employee.id != 0, 'Employee not found');
    emit_payment_event(employee.wallet, employee.salary);
}

fn batch_execute_payments(ids: Array<felt>) {
    for id in ids {
        execute_payment(id);
    }
}


event PaymentConfirmed {
    wallet: felt,
    amount: u128,
}

fn emit_payment_event(wallet: felt, amount: u128) {
    emit PaymentConfirmed {
        wallet: wallet,
        amount: amount,
    };
}