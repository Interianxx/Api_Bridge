//
//  ContentView.swift
//  Api_Bridge
//
//  Created by Jose Alejandro Interian Pech on 21/10/25.
//

import SwiftUI
import Foundation

struct Persona: Codable, Identifiable {
    let id: Int
    let nombre: String?
    let apellido: String?
    let sexo: String?
    let fh_nac: String?
    let rol: String?
}

struct ContentView: View {
    let apiBridge = ApiBridge()
    let decoder = JSONDecoder()

    @State private var personas: [Persona] = []
    @State private var respuesta = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Lista") { // ← estilo similar a FormView
                    ForEach(personas) { persona in
                        NavigationLink(destination: FormView(persona: persona)) {
                            Text("\(persona.nombre ?? "—") \(persona.apellido ?? "")")
                                .lineLimit(1)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)         
            .navigationTitle("Personas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink("Agregar") {
                        FormView() // modo crear
                    }
                }
            }
            .onAppear {
                apiBridge.get(endpoint: "/escuela/persona") { response in
                    guard let text = response,
                          let jsonData = text.data(using: .utf8) else {
                        DispatchQueue.main.async { respuesta = "Respuesta nula o inválida" }
                        return
                    }
                    do {
                        let decoded = try decoder.decode([Persona].self, from: jsonData)
                        DispatchQueue.main.async { personas = decoded }
                    } catch {
                        DispatchQueue.main.async { respuesta = "Malformed JSON: \(error)" }
                    }
                }
            }
        }
    }
}

#Preview { ContentView() }
