fn main() {
    //This Teststring is Used in Encrypt, Sign and Verify
    let testString = "Hello World"; 

    // Modul gets initialized. When initialization was successfull than the process proceed.
    println!("\n"); 
    if ffi::initializeModule() == true {
        println!("Initialize Module: true"); 
        println!("\n"); 

        let priv_key: String = "3344".to_string(); 
        println!("{}", ffi::rustcall_create_key(priv_key)); 
        println!("\n"); 

        println!("Loaded Key Hash: {}", ffi::rustcall_load_key("3344".to_string()));
        println!("\n");

        let encrypted_data = ffi::rustcall_encrypt_data(testString.to_string(), "3344".to_string()); 
        println!("Encrypted Data of {}:  {}", testString.to_string(), encrypted_data);
        println!("\n"); 

        let decrypted_data = ffi::rustcall_decrypt_data(encrypted_data, "3344".to_string()); 
        println!("Decrypted Data: {}", decrypted_data); 
        println!("\n"); 

        let signed_data = ffi::rustcall_sign_data(testString.to_string(),"3344".to_string()); 
        println!("Signed Data: {}", signed_data); 
        println!("\n");

        println!("Verify Signature: {}", ffi::rustcall_verify_data("3344".to_string(), testString.to_string(), signed_data.to_string())); 
        println!("\n"); 
    }else{
        println!("Initialize Module: false")
    }
    
}

#[swift_bridge::bridge]
pub mod ffi{
    // Swift-Methods can be used in Rust 
    extern "Swift" {
        fn rustcall_create_key(privateKeyName: String) -> String;
        fn initializeModule() -> bool; 
        fn rustcall_load_key(keyID: String) -> String;
        fn rustcall_encrypt_data(data: String, keyname: String) -> String; 
        fn rustcall_decrypt_data(data: String, privateKeyName: String) -> String; 
        fn rustcall_sign_data(content: String, privateKeyName: String) -> String;
        fn rustcall_verify_data(publicKeyName: String, content: String, signature: String) -> String; 
    }
}
