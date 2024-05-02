#[allow(warnings)]
fn main() {
    let pubKey: String = "1234".to_string(); 
    let privKey: String = "3344".to_string(); 
    println!("{}", ffi::rustcall_generateKeyPair(pubKey, privKey)); 
}

#[swift_bridge::bridge]
mod ffi {
    // Rust-Methods can be used in Swift 
    extern "Rust" {
    }

    // Swift-Methods can be used in Rust 
    extern "Swift" {
        fn rustcall_generateKeyPair(publicKeyName: String, privateKeyName: String) -> String;
    }
}