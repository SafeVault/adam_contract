
struct Transaction {
    id: felt,
    user: felt,
    amount: u128,
    transaction_type: felt,
    status: felt,           
    timestamp: felt,
}

@storage_var
fn transactions(id: felt) -> Transaction {}

@storage_var
fn user_transactions(user: felt, index: felt) -> felt {}

@storage_var
fn user_transaction_count(user: felt) -> felt {}

fn add_transaction(
    id: felt,
    user: felt,
    amount: u128,
    transaction_type: felt,
    status: felt,
    timestamp: felt
) {
    let transaction = Transaction {
        id: id,
        user: user,
        amount: amount,
        transaction_type: transaction_type,
        status: status,
        timestamp: timestamp,
    };

    transactions::write(id, transaction);

    let count = user_transaction_count::read(user);
    user_transactions::write(user, count, id);
    user_transaction_count::write(user, count + 1);
    emit_transaction_event(transaction);
}

event TransactionEvent {
    id: felt,
    user: felt,
    amount: u128,
    transaction_type: felt,
    status: felt,
    timestamp: felt,
}

fn emit_transaction_event(transaction: Transaction) {
    emit TransactionEvent {
        id: transaction.id,
        user: transaction.user,
        amount: transaction.amount,
        transaction_type: transaction.transaction_type,
        status: transaction.status,
        timestamp: transaction.timestamp,
    };
}

fn get_transaction_by_id(id: felt) -> Transaction {
    return transactions::read(id);
}

fn get_user_transactions(user: felt) -> Array<Transaction> {
    let count = user_transaction_count::read(user);
    let mut transactions_list = Array::new();

    for i in 0..count {
        let transaction_id = user_transactions::read(user, i);
        let transaction = transactions::read(transaction_id);
        transactions_list.append(transaction);
    }

    return transactions_list;
}

fn get_transactions_by_type(user: felt, transaction_type: felt) -> Array<Transaction> {
    let transactions_list = get_user_transactions(user);
    let mut filtered_transactions = Array::new();

    for transaction in transactions_list {
        if transaction.transaction_type == transaction_type {
            filtered_transactions.append(transaction);
        }
    }

    return filtered_transactions;
}

fn get_total_transaction_amount(user: felt) -> u128 {
    let transactions_list = get_user_transactions(user);
    let mut total: u128 = 0;

    for transaction in transactions_list {
        total += transaction.amount;
    }

    return total;
}

fn validate_access(caller: felt, user: felt) {
    assert(caller == user, 'Unauthorized access');
}

fn process_transaction(account: felt, amount: u128, category: felt) -> Transaction {
    let timestamp = get_block_timestamp();
    let status = 0;

    let transaction = Transaction {
        account: account,
        amount: amount,
        status: status,
        category: category,
        timestamp: timestamp,
    };

    emit_transaction_event(transaction);

    return transaction;
}