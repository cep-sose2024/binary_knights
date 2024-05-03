//
//  ContentView.swift
//  binaryknights
//
//  Created by Kiwan Taylan Cakir on 27.04.24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var input: String = "Hello World!"
    @State private var decryptedText: String = "-"
    @State var encryptedText: String = "None"
    let enclaveManager = SecureEnclaveManager()
    var SEkeyPair: SecureEnclaveManager.SEKeyPair?
    
    init() {
        do {
            SEkeyPair = try enclaveManager.generateKeyPair("public", "priVAteK$y")
            print("Done")
        } catch {
            print("Blabla")
        }
    }
    
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Binary Knights")
                .padding(.bottom, 30.0)
            Text("Enter the text or Key 🔒")
            TextField("Text to encrypt", text: $input)
                .disableAutocorrection(true)
                .frame(width: 250)
                .padding(5)
            
            Text("Decrypted key 🔒")
            TextField("Decrypted key 🔓:", text: $decryptedText)
                .padding(.vertical, 16)
            Text(decryptedText)
                .font(.system(size: 12))
            
            
            Text("Key of Secure Enclave 🔒")
            TextField("Key of Secure Enclave 🔓:", text: $encryptedText)
                .font(.system(size: 12))
            
            
            HStack{
                Button("Encrypt") {
                    do{
                        print("private Key: "+String((SEkeyPair?.privateKey.hashValue)!))
                        encryptedText = try enclaveManager.encrypt(data: input.data(using: .utf8)!, publicKey: SEkeyPair!.publicKey).base64EncodedString()
                    } catch {
                        print("Unbehandelter Error!")
                    }
                    //encryptedText=enclaveManager.sayHello()
                    //                    Logik-Methodenaufruf aus Klasse SecureEnclavemanager
                }.padding(.vertical, 8).padding(.horizontal).cornerRadius(8)
                
                Button("Decrypt") {
                    do{
                        print("private Key: "+String((SEkeyPair?.privateKey.hashValue)!))
                        //                        decryptedText =
                        print(try enclaveManager.decrypt(input.data(using: .utf8)!, privateKey: SEkeyPair!.privateKey))
                        
                        
                    } catch {
                        print("Unbehandelter Fehler: \(error)")
                    }
                }.padding(.vertical, 8).padding(.horizontal).cornerRadius(8)
                
                Button("Switch") {
                    input = encryptedText
                }
            }
        }
    }
}
#Preview {
    ContentView()
}
