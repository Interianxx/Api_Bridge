//
//  FormView.swift
//  Api_Bridge
//
//  Created by Jose Alejandro Interian Pech on 21/10/25.
//

import SwiftUI



struct FormView: View {
    @State private var nombre = ""
    @State private var apellido = ""
    @State private var sexo = "h"
    @State private var fechaNacimiento = Date()
    @State private var rol = 1
    @FocusState private var focusedField: Field?
    
    @Environment(\.dismiss) private var dismiss

    let persona: Persona?

    init(persona: Persona? = nil) {
        self.persona = persona
        _nombre = State(initialValue: persona?.nombre ?? "")
        _apellido = State(initialValue: persona?.apellido ?? "")
        _sexo = State(initialValue: FormView.initialSexo(persona?.sexo))
        _fechaNacimiento = State(initialValue: FormView.initialDate(persona?.fh_nac))
        _rol = State(initialValue: FormView.initialRol(persona?.rol))
    }

    enum Field { case nombre, apellido }

    private let sexos: [(code: String, label: String)] = [
        ("h", "Hombre"),
        ("m", "Mujer"),
        ("o", "Otro")
    ]

    private let roles: [(id: Int, label: String)] = [
        (1, "Estudiante"),
        (2, "Profesor"),
        (3, "Otro")
    ]

    private var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var apellidoLimpio: String { apellido.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !nombreLimpio.isEmpty && !apellidoLimpio.isEmpty }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func initialDate(_ text: String?) -> Date {
        guard let text = text,
              let date = apiDateFormatter.date(from: text) else {
            return Date()
        }
        return date
    }

    private static func initialSexo(_ value: String?) -> String {
        switch (value ?? "").lowercased() {
        case "m", "mujer": return "m"
        case "o", "otro": return "o"
        default: return "h"
        }
    }

    private static func initialRol(_ value: String?) -> Int {
        switch (value ?? "").lowercased() {
        case "profesor": return 2
        case "otro": return 3
        default: return 1
        }
    }

    var body: some View {
        Form {                                  
            Section("Datos personales") {
                LabeledContent("Nombre") {
                    TextField("", text: $nombre)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .nombre)
                        .onSubmit { focusedField = .apellido }
                }
                LabeledContent("Apellido") {
                    TextField("", text: $apellido)
                        .textContentType(.familyName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .apellido)
                }
                LabeledContent("Sexo") {
                    Picker("", selection: $sexo) {
                        ForEach(sexos, id: \.code) { option in
                            Text(option.label).tag(option.code)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                LabeledContent("Fecha de nacimiento") {
                    DatePicker("", selection: $fechaNacimiento, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }

            Section("Rol") {
                Picker("Selecciona tu rol", selection: $rol) {
                    ForEach(roles, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
            }
        }
        .navigationTitle("Formulario")          // ← usa el stack del padre
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Guardar") {
                    handleGuardar()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }


        }

        .formStyle(.grouped)                    // ← estilo iOS clásico
    }

    private func handleGuardar() {
        guard isValid else {
            print("Formulario inválido")
            return
        }

        let isEdit = persona?.id != nil
        let payload = PersonaBody(
            id_persona: isEdit ? persona!.id : 0,
            nombre: nombreLimpio,
            apellido: apellidoLimpio,
            sexo: sexo,
            fh_nac: FormView.apiDateFormatter.string(from: fechaNacimiento),
            id_rol: rol
        )

        guard let json = try? JSONEncoder().encode(payload),
              let jsonStr = String(data: json, encoding: .utf8) else {
            print("Error al codificar JSON")
            return
        }

        let api = ApiBridge()
        let completion: (String?) -> Void = { _ in
            DispatchQueue.main.async { dismiss() }
        }

        if isEdit {
            api.patch(endpoint: "/escuela/persona", body: jsonStr, completion: completion)
        } else {
            api.post(endpoint: "/escuela/persona", body: jsonStr, completion: completion)
        }
    }

    private struct PersonaBody: Encodable {
        let id_persona: Int
        let nombre: String
        let apellido: String
        let sexo: String
        let fh_nac: String
        let id_rol: Int
    }
}

#Preview { NavigationStack { FormView() } }
