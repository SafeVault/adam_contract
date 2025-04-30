use super::transaction::process_transaction;
use super::utils::get_block_timestamp;

#[cfg(test)]
mod tests {
    #[test]
    fn test_process_transaction() {
        let transaction = process_transaction(123, 1000, 0);
        assert(transaction.account == 123, 'Test failed: account mismatch');
        assert(transaction.amount == 1000, 'Test failed: amount mismatch');
        assert(transaction.category == 0, 'Test failed: category mismatch');
        assert(transaction.status == 0, 'Test failed: status mismatch');
    }

    #[test]
    fn test_get_block_timestamp() {
        let timestamp = get_block_timestamp();
        assert(timestamp == 1234567890, 'Test failed: timestamp mismatch');
    }
}