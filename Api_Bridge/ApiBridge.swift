
//
//  ApiBridge.swift
//  Api_Bridge
//
//  Created by Jose Alejandro Interian Pech on 21/10/25.
//

import Foundation

class ApiBridge {
    let baseUrl = "https://fi.jcaguilar.dev/v1"
    
    func get (endpoint: String, completion: @escaping (String?) -> Void){
        guard let url = URL(string: "\(baseUrl)\(endpoint)") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data")
                completion(nil)
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8){
                completion(responseString)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func post (endpoint: String, body: String, completion: @escaping (String?) -> Void){
        guard let url = URL(string: "\(baseUrl)\(endpoint)") else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) {
            data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data")
                completion(nil)
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8){
                completion(responseString)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    
    func patch(endpoint: String, body: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseUrl)\(endpoint)") else { completion(nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body.data(using: .utf8)
        URLSession.shared.dataTask(with: req) { data,_,_ in
            completion(data.flatMap { String(data:$0, encoding:.utf8) })
        }.resume()
    }


    
}
