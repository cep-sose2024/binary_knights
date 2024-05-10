
#![allow(warnings)]

// includings of "Core Foundation"
use core_foundation::base::*;
use core_foundation::dictionary::CFDictionary;
use core_foundation::string::CFString;
use core_foundation::boolean::CFBoolean; 

// Includings of "Security Framework"
use security_framework::access_control::ProtectionMode::{AccessibleWhenPasscodeSetThisDeviceOnly, AccessibleWhenUnlockedThisDeviceOnly}; 
use security_framework::item::Location;
use security_framework::access_control::SecAccessControl; 
use security_framework::key::SecKey;
use security_framework::key::Token;
use security_framework::key::KeyType; 
use security_framework::key::GenerateKeyOptions;
use std::env;

fn create_access_control_object() -> Result<SecAccessControl, security_framework::base::Error> {
    let access = SecAccessControl::create_with_protection(
        Some(AccessibleWhenPasscodeSetThisDeviceOnly),
        1usize << 30
    );
    access.map_err(|err| {
        eprintln!("Fehler beim Erstellen des Zugriffssteuerungsobjekts: {}", err);
        err
    })
}
fn generati_dir(privateKeyName: &str) -> CFDictionary{
    let options = GenerateKeyOptions{
        key_type: Some(KeyType::ec()),
        size_in_bits: Some(256), 
        label: Some(String::from(privateKeyName)), 
        token: Some(Token::SecureEnclave), 
        location: Some(Location::DefaultFileKeychain), 
        // access_control: Some(SecAccessControl::create_with_protection(Some(ProtectionMode::AccessibleWhenPasscodeSetThisDeviceOnly),  1usize << 30)),
        access_control: Some(create_access_control_object().expect("Fehler bei der Erstellung des Access Objektes"))
    }; 

    options.to_dictionary()

}

fn main() {
    env::set_var("RUST_BACKTRACE", "1");
    let dictionary = generati_dir("priVAteK$y"); 
    let key: SecKey = SecKey::generate(dictionary).expect("Fehler bei der Erstellung der Schlüssel: "); 
}
