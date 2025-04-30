mod transaction;
mod payroll;
mod utils;
mod event;
mod authorization;

use transaction::{
    process_transaction, add_transaction, get_transaction_by_id, get_user_transactions,
    get_transactions_by_type, get_total_transaction_amount, validate_access,
};

use payroll::{
    add_employee, remove_employee, update_employee, execute_payment, batch_execute_payments,
};

use utils::get_block_timestamp;

use authorization::{
    assign_role, verify_role, verify_permission, add_approval, check_approvals, delegate_function,
    verify_delegate, set_employee_status, get_employee_status,
};