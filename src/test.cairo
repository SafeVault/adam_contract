use super::transaction::{
    add_transaction, get_transaction_by_id, get_user_transactions, get_transactions_by_type,
    get_total_transaction_amount, validate_access,
};

#[cfg(test)]
mod tests {
    #[test]
    fn test_add_transaction() {
        add_transaction(1, 0x123, 1000, 'deposit', 'completed', 1234567890);
        let transaction = get_transaction_by_id(1);
        assert(transaction.amount == 1000, 'Test failed: amount mismatch');
        assert(transaction.transaction_type == 'deposit', 'Test failed: type mismatch');
    }

    #[test]
    fn test_get_user_transactions() {
        add_transaction(2, 0x123, 500, 'withdrawal', 'completed', 1234567891);
        let transactions = get_user_transactions(0x123);
        assert(transactions.len() == 2, 'Test failed: transaction count mismatch');
    }

    #[test]
    fn test_get_transactions_by_type() {
        let filtered = get_transactions_by_type(0x123, 'deposit');
        assert(filtered.len() == 1, 'Test failed: filtering mismatch');
    }

    #[test]
    fn test_get_total_transaction_amount() {
        let total = get_total_transaction_amount(0x123);
        assert(total == 1500, 'Test failed: total amount mismatch');
    }

    #[test]
    fn test_validate_access() {
        validate_access(0x123, 0x123);  // Should pass
        assert_panics(|| validate_access(0x456, 0x123), 'Test failed: unauthorized access not detected');
    }
}