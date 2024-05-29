fn main() {
    println!("\n"); 
    let priv_key: String = "3344".to_string(); 
    println!("{}", ffi::rustcall_create_key(priv_key)); 
    println!("\n"); 
    if ffi::initializeModule() == true {
        println!("Initialize Module: true"); 
    }else{
        println!("Initialize Module: false")
    }
    println!("\n"); 
    println!("Loaded Key Hash: {}", ffi::rustcall_load_key("3344".to_string()));
    println!("\n"); 
    println!("Encrypted Data: {}", ffi::rustcall_encrypt_data("Hello World".to_string(), "3344".to_string()));
    println!("\n"); 
    let signed_data = ffi::rustcall_sign_data("Hello World".to_string(),"3344".to_string()); 
    println!("Signed Data: {}", signed_data); 
    println!("\n");
    println!("Verify Signature: {}", ffi::rustcall_verify_data("3344".to_string(), "Hello World".to_string(), signed_data.to_string())); 
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
        fn rustcall_verify_data(publicKeyName: String, content: String, signature: String) -> String; 
    }
}
