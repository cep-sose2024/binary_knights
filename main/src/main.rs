fn main() {
    let priv_key: String = "3344".to_string(); 
    println!("{}", ffi::rustcall_create_key(priv_key)); 

    if ffi::initializeModule() == true {
        println!("Initialize Module: true"); 
    }else{
        println!("Initialize Module: false")
    }
    println!("LoadKey: {}", ffi::rustcall_load_key("3344".to_string()));
    println!("Encrypted Data: {}", ffi::rustcall_encrypt_data("Hello World".to_string(), "3344".to_string())); 
    println!("Signed Data: {}", ffi::rustcall_sign_data("Hello World".to_string(),"3344".to_string()))
}

#[swift_bridge::bridge]
pub mod ffi{
    // Swift-Methods can be used in Rust 
    extern "Swift" {
        // type SecurityError; 
        fn rustcall_create_key(privateKeyName: String) -> String;
        fn initializeModule() -> bool; 
        fn rustcall_load_key(keyID: String) -> String;
        fn rustcall_encrypt_data(data: String, keyname: String) -> String; 
        fn rustcall_sign_data(content: String, privateKeyName: String) -> String; 
    }
}

// pub enum SecurityError {
//     InitializationError(String)
// }
