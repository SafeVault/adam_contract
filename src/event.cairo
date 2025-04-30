event TransactionEvent {
    account: felt,
    amount: u128,
    status: felt,
    category: felt,
    timestamp: felt,
}

fn emit_transaction_event(transaction: Transaction) {
    emit TransactionEvent {
        account: transaction.account,
        amount: transaction.amount,
        status: transaction.status,
        category: transaction.category,
        timestamp: transaction.timestamp,
    };
}