fn main() {
    let privKey: String = "3344".to_string(); 
    println!("{}", ffi::rustcall_create_key(privKey)); 

    if ffi::initializeModule() == true {
        println!("Initialize Module: true"); 
    }else{
        println!("Initialize Module: false")
    }
    println!("{}", ffi::rustcall_load_key("3344".to_string()));
}

#[swift_bridge::bridge]
pub mod ffi{
    // Swift-Methods can be used in Rust 
    extern "Swift" {
        // type SecurityError; 
        fn rustcall_create_key(privateKeyName: String) -> String;
        fn initializeModule() -> bool; 
        fn rustcall_load_key(keyID: String) -> String;
    }
}

// pub enum SecurityError {
//     InitializationError(String)
// }
