extern crate crypto_layer; 
use crypto_layer::common::factory::{SecModules, SecurityModule};
use crypto_layer::common::traits::log_config::LogConfig;
use crypto_layer::tpm::core::instance::TpmType;
use crypto_layer::common::error::SecurityModuleError;
use crypto_layer::common::crypto::algorithms::{
    encryption::{AsymmetricEncryption, BlockCiphers},
    hashes::Hash,
};
use crypto_layer::common::crypto::KeyUsage;

fn main() {

    // Creating a TPM Provider
    let key_id = "3344".to_string();
    // let log_setup = LogConfig::setup_logging(&self); 

    // let tpm_provider = SecModules::get_instance(key_id, SecurityModule::Tpm(TpmType::default()), Some())
    // .expect("Failed to create TPM provider");

    // Initializing the TPM Module 
    // match tpm_provider.lock().unwrap().initialize_module() {
    //     Ok(()) => println!("TPM module initialized successfully"),
    //     Err(e) => println!("Failed to initialize TPM module: {:?}", e),
    // }
    
    // let key_algorithm = AsymmetricEncryption::Ecc(EccSchemeAlgorithm::EcDsa(EccCurves::P256));
    // let sym_algorithm = Some(BlockCiphers::Aes(SymmetricMode::Cbc, KeyBits::Bits256));
    // let hash = Some(Hash::Sha2(Sha2Bits::Sha256));
    // let key_usages = vec![KeyUsage::SignEncrypt, KeyUsage::Decrypt];
    
    // match tpm_provider.lock().unwrap().create_key(
    //     "my_key_id",
    //     key_algorithm,
    //     sym_algorithm,
    //     hash,
    //     key_usages,
    // ) {
    //     Ok(()) => println!("Key created successfully"),
    //     Err(e) => println!("Failed to create key: {:?}", e),
    // }

    // // Signing Data
    // let data = b"Hello, world!";

    // match tpm_provider.lock().unwrap().sign_data(data) {
    //     Ok(signature) => println!("Signature: {:?}", signature),
    //     Err(e) => println!("Failed to sign data: {:?}", e),
    // }

    // // Verifying Signature
    // let data = b"Hello, world!";
    // let signature = "Test"; // ... obtained signature ...

    // match tpm_provider.lock().unwrap().verify_signature(data, &signature) {
    //     Ok(valid) => {
    //         if valid {
    //             println!("Signature is valid");
    //         } else {
    //             println!("Signature is invalid");
    //         }
    //     }
    //     Err(e) => println!("Failed to verify signature: {:?}", e),
    // }

    println!("Hello World"); 

}
