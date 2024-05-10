# Swift-Rust Bridge Attempts Documentation

## Attempts with Security.framework:

Attempted with the crate mentioned above, but unsuccessful. Understanding how the bindings access iOS and macOS remained elusive despite attempts. For instance, there was an attempt to write a `create_key()` method using the crate, but no key could be generated even though the code compiled successfully. Additionally, documentation is deficient, lacking examples of how an implementation of this crate could look like.

## Attempts with bindgen and cbindgen:

Both FFIs were implemented individually, but not in conjunction. To establish bidirectional communication between Rust and Swift and iOS/macOS devices, the implementation of both FFIs is necessary. However, this resulted in Xcode failing to compile the code, thus preventing access to macOS/iOS devices.

![cbindgen & bindgen](pictures/cbindgen_bindgen.png)


## Attempts with swift-rust-bridge:

The above-mentioned Swift Rust bridge could successfully communicate bidirectionally between Rust and Swift. However, due to the implementation, Xcode could not compile, thus hindering access to the device's Secure Enclave.

## Other Attempts:

### Dioxus:

An interesting Rust implementation on iOS and macOS. Testing and informing were planned, but this approach was discarded as the approach should now be via Swift - otherwise, it's a very large cross-platform, like Flutter (not meeting requirements).

### EllipticCurveKeyPair:

A very good overview of Secure Enclave functions. However, this Swift version (Swift 3) is too old to make it executable in the current Xcode. The structure was nonetheless examined and understood to build the current prototype.

### flutter-rust-ffi:

Testing Rust code execution accessing the Secure Enclave. The problem here was that the Secure Enclave could neither be initialized nor could the Rust code be executed on an iPhone.

### hello_rust_ffi_plugin:

A Rust FFI plugin implemented from the initial prototype (Flutter-Rust-Bridge). The idea was abandoned as has been done with Swift.

### SecureEnclaveCrypto:

A very detailed overview of all functions we also need to implement. However, it's unfortunately very old and not usable. Nonetheless, I could derive the structure from it and understand the communication.

### uniffi-rs:

An approach to implementing bridges that we wanted to examine more closely after the milestone (time constraints).

### rust-binary-calls-swift-package:

An own Swift project where we manually implemented a Rust bridge (independent of tutorials), with bidirectional communication between Swift and Rust already functioning. However, this was abandoned as we tried it via Swift only (execution on an iPhone currently works, but calling Swift methods in Rust does not).
