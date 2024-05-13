import SwiftUI

struct ContentView: View {
    /**SwiftUI Frontend Variables */
    @State private var encryption_input: String = ""
    @State private var encrypted_value: String = ""
    @State private var decrypted_value: String = ""
    @State private var sign_input: String = ""
    @State private var signature_value: String = ""
    @State private var temp_signature_value: CFData = "".data(using: .utf8)! as CFData
//    @State private var temp_signature_value: String = ""
    @State private var obj_signature_value: CFData = "".data(using: .utf8)! as CFData
    @State private var verify_status = false
    @State private var verify_status_output = ""
    
    /**SwiftUI Backend Variables**/
    private var key_handle = SecureEnclaveManager()
    private var keyPair: SecureEnclaveManager.SEKeyPair?
    
    init() {
        do{
            if try key_handle.initializeModule(){
                print("Modul is initialised. Secure Enclave is available.\n")
            }
        }catch{
            print("\(error)")
        }
        
        do {
            keyPair = try key_handle.create_key("priVAteK$y")
            print("Successful generated KeyPair. \n")
            print("Private Key: "+String((keyPair?.privateKey.hashValue)!))
            print("Public Key: " + String((keyPair?.publicKey.hashValue)!))
            print("\n")
        } catch {
            print("KeyPair konnte nicht generiert werden: \(error)")
        }
       
    }
    
    var body: some View {
        ScrollView{
        VStack(alignment: .leading){
            Text("Encryption & Decryption")
                .font(.title)
                .multilineTextAlignment(.leading)
                .padding(4.0)
            HStack{
                VStack(alignment: .leading){
                    Text("Private Key: "+String((keyPair!.privateKey.hashValue)))
                    Text("Public Key: "+String((keyPair!.publicKey.hashValue)))
                }
            }
            
            VStack(alignment: .leading){
                Text("Text to encrypt")
                    .font(.title2)
                
                HStack{
                    TextField("Text to encrypt", text: $encryption_input)
                        .frame(height: 40.0)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(10)
                    
                    Button("Encrypt"){
                        do{
                            encrypted_value = try key_handle.encrypt_data(data: encryption_input.data(using: .utf8)!, publicKey: keyPair!.publicKey).base64EncodedString()
                            print("Successful encrypted: \(encryption_input) in \(encrypted_value) \n")
                        } catch {
                            print("\(error)")
                        }
                    }
                    .padding(.trailing, 20.0)
                }
            }
            .padding(.top, 5.0)
            
            VStack(alignment: .leading){
                Text("Encrypted Value")
                    .font(.title2)
                HStack{
                    TextField("Encrypted Value", text: $encrypted_value)
                        .frame(height: 40.0)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(10)
                    Button("Decrypt"){
                        do{
                            guard let data = Data(base64Encoded: encrypted_value)
                            else {
                                throw CustomError.runtimeError("Invalid base64 input")
                            }
                                                    
                            guard let temp_decrypted_value = String(data: try key_handle.decrypt_data(data, privateKey: keyPair!.privateKey), encoding: .utf8)
                            else {
                                throw CustomError.runtimeError("Error converting decrypted data to string")
                            }

                            decrypted_value = temp_decrypted_value
                            
                            print("Successful decrypted: \(encrypted_value) in \(decrypted_value) \n")
                            } catch {
                                print("Fehler: \(error)")
                            }
                    }
                    .padding(.trailing, 20.0)
                }
            }
            .padding(.top, 5.0)
            
            VStack(alignment: .leading){
                Text("Decrypted Value")
                    .font(.title2)
                HStack{
                    TextField("Decrypted Value", text: $decrypted_value)
                        .frame(height: 40.0)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(10)
                }
            }
            .padding(.top, 5.0)
            
            Divider()
            
            Text("Sign & Verify")
                .font(.title)
                .multilineTextAlignment(.leading)
                .padding(4.0)
            
            VStack(alignment: .leading){
                Text("Text to sign")
                    .font(.title2)
                HStack{
                    TextField("Text to sign", text: $sign_input)
                        .frame(height: 40.0)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(10)
                    
                    Button("Sign"){
                        do{
                            //String
                            signature_value = ((try key_handle.sign_data(keyPair!.privateKey, sign_input.data(using: String.Encoding.utf8)! as CFData)!) as Data).base64EncodedString(options: [])
                            print("Successfull signed \(sign_input) in \(signature_value) \n")
                        }catch{
                            print("\(error)")
                        }
                    }
                    .padding(.trailing, 20.0)
                }
            }
            .padding(.top, 5.0)
            
            VStack(alignment: .leading){
                Text("Signature")
                    .font(.title2)
                
                HStack{
                    TextField("Signature", text: $signature_value)
                        .frame(height: 40.0)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(10)
                    Button("Verify "){
                        do{
                            var verify_status = try key_handle.verify_signature(keyPair!.publicKey, sign_input, signature_value)
                            
                            if verify_status == false {
                                verify_status_output = "invalid"
                                print("Verify: '\(sign_input)' and '\(signature_value)' is invalid" )
                            }else{
                                verify_status_output = "valid"
                                print("Verify: '\(sign_input)' and '\(signature_value)' is valid" )
                            }
                        }catch{
                            verify_status_output = "invalid"
                            print("\(error)")
                        }
                    }
                }
            }
            .padding(.top, 5.0)
            
            VStack(alignment: .leading){
                Text("Verify Status")
                    .font(.title2)
                TextField("Verify Status", text: $verify_status_output)
                    .frame(height: 40.0)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
                
            }
            .padding(.top, 5.0)
            
            Button("Clear All"){
                encryption_input = ""
                encrypted_value = ""
                decrypted_value = ""
                sign_input = ""
                signature_value = ""
                verify_status = false
                verify_status_output = ""
                print("Everything cleared!")
            }
            .padding(/*@START_MENU_TOKEN@*/.all, 5.0/*@END_MENU_TOKEN@*/)
            .background(Color.red)
            .foregroundColor(.black)
            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            .cornerRadius(10)
        }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

enum CustomError: Error {
        case runtimeError(String)
    }

