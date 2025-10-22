//
//  ContentView.swift
//  Api_Bridge
//
//  Created by Jose Alejandro Interian Pech on 21/10/25.
//

import SwiftUI
import Foundation

/// Representa a una persona recibida desde el servicio remoto.
struct Persona: Codable, Identifiable {
    let id: Int
    let nombre: String?
    let apellido: String?
    let sexo: String?
    let fh_nac: String?
    let rol: String?
}

/// Pantalla principal que presenta las personas registradas.
struct ContentView: View {
    /// Cliente responsable de interactuar con la API.
    private let apiBridge = ApiBridge()

    /// Decodificador compartido para transformar JSON en modelos.
    private let decoder = JSONDecoder()

    /// Listado con las personas obtenidas del backend.
    @State private var personas: [Persona] = []

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
            .onAppear(perform: loadPersonas)
        }
    }
}

private extension ContentView {
    /// Solicita las personas al backend y actualiza el estado local.
    func loadPersonas() {
        apiBridge.get(endpoint: "/escuela/persona") { response in
            guard
                let text = response,
                let data = text.data(using: .utf8),
                let decoded = try? decoder.decode([Persona].self, from: data)
            else {
                return
            }

            DispatchQueue.main.async {
                personas = decoded
            }
        }
    }
}

#Preview { ContentView() }
