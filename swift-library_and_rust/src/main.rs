fn main() {
    let privKey: String = "3344".to_string(); 
    println!("{}", ffi::rustcall_create_key(privKey)); 

}

#[swift_bridge::bridge]
pub mod ffi{
    // Rust-Methods can be used in Swift 
    extern "Rust" {
    }

    // Swift-Methods can be used in Rust 
    extern "Swift" {
        fn rustcall_create_key(privateKeyName: String) -> String;
    }
}