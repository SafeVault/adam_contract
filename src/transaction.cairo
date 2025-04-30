struct Transaction {
    account: felt,
    amount: u128,
    status: felt,
    category: felt,
    timestamp: felt,
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