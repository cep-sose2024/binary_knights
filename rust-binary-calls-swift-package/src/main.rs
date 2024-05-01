fn main() {
    println!("hello from Rust...");
    let _num = ffi::hello_swift(); 
}

#[swift_bridge::bridge]
mod ffi {
    extern "Rust" {
        fn hello_rust() -> String;
    }

    extern "Swift" {
        fn hello_swift() -> String;
    }
}

fn hello_rust() -> String {
    println!("hello from rust");

  return "hi".to_owned();
}