import SwiftUI

struct ContentView: View {
    /**SwiftUI Frontend Variables */
    @State private var encryption_input: String = ""
    @State private var encrypted_value: String = ""
    @State private var decrypted_value: String = ""
    @State private var sign_input: String = ""
    @State private var signature_value: String = ""
    @State private var temp_signature_value: CFData = "".data(using: .utf8)! as CFData
    @State private var obj_signature_value: CFData = "".data(using: .utf8)! as CFData

    @State private var verify_status: String = ""
    
    /**SwiftUI Backend Variables**/
    let key_handle = SecureEnclaveManager()
    var keyPair: SecureEnclaveManager.SEKeyPair?
    
    init() {
        do {
            keyPair = try key_handle.create_key("priVAteK$y")
            print("Successful generated KeyPair")
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
                    Text("Private Key: \(1232465468)")
                    Text("Public Key: \(135454346)")
                }
                
                Button("Generate \nKeys🔑"){
                    /**Generate Key implementation**/
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
                            print(keyPair!.privateKey.hashValue as Any)
                            print("private Key: "+String((keyPair?.privateKey.hashValue)!))
                            encrypted_value = try key_handle.encrypt_data(data: encryption_input.data(using: .utf8)!, publicKey: keyPair!.publicKey).base64EncodedString()
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
                            //print("private Key: "+String((SEkeyPair?.privateKey.hashValue)!))
                                                    
                            guard let data = Data(base64Encoded: encrypted_value)
                            else {
                                throw CustomError.runtimeError("Invalid base64 input")
                            }
                                                    
                            var deText = try key_handle.decrypt_data(data, privateKey: keyPair!.privateKey)


                            guard let temp_decrypted_value = String(data: deText, encoding: .utf8)
                            else {
                                throw CustomError.runtimeError("Error converting decrypted data to string")
                            }
                            
                            decrypted_value = temp_decrypted_value
                            
                            } catch {
                                print("Unbehandelter Fehler: \(error)")
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
                            temp_signature_value = try key_handle.signing_data(keyPair!.privateKey, sign_input.data(using: String.Encoding.utf8)! as CFData)!
                            signature_value = String(temp_signature_value.hashValue)
                            print("Signature = " + String(signature_value))
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
                            if try key_handle.verify_signature(keyPair!.publicKey, sign_input, temp_signature_value) && signature_value == String(temp_signature_value.hashValue){
                                verify_status = "valid"
                                print("Signature is valid \(signature_value)" )
                            }else{
                                verify_status = "invalid"
                                print("Signature is invalid")
                            }
                        }catch{
                            print("\(error)")
                        }
                    }
                }
            }
            .padding(.top, 5.0)
            
            VStack(alignment: .leading){
                Text("Verify Status")
                    .font(.title2)
                TextField("Verify Status", text: $verify_status)
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
                verify_status = ""
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


