
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(1, 2), 3);
    }
    #[test]
    fn test_add_numbers() {
        assert_eq!(add(2, 3), 5);
        assert_eq!(add(-1, 5), 4);
        assert_eq!(add(0, 0), 0);
        assert_eq!(add(-10, -5), -15);

    }

}