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
    @State private var sexo = "Hombre"
    @State private var fechaNacimiento = Date()
    @State private var rol = "Estudiante"
    @FocusState private var focusedField: Field?
    
    @Environment(\.dismiss) private var dismiss

    let persona: Persona?

    init(persona: Persona? = nil) {
        self.persona = persona
        _nombre = State(initialValue: persona?.nombre ?? "")
        _apellido = State(initialValue: persona?.apellido ?? "")
        _sexo = State(initialValue: FormView.displaySexo(persona?.sexo))   // ← aquí
        _fechaNacimiento = State(initialValue: FormView.parseDate(persona?.fh_nac) ?? Date())
        _rol = State(initialValue: persona?.rol ?? "Estudiante")
    }

    enum Field { case nombre, apellido }

    private let sexos = ["Hombre", "Mujer", "Otro"]
    private let roles = ["Estudiante", "Profesor", "Otro"]

    private var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var apellidoLimpio: String { apellido.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !nombreLimpio.isEmpty && !apellidoLimpio.isEmpty }

    private static let isoFormatter = ISO8601DateFormatter()
    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func parseDate(_ text: String?) -> Date? {
        guard let text = text else { return nil }
        if let d = isoFormatter.date(from: text) { return d }
        let fmts = ["yyyy-MM-dd'T'HH:mm:ssXXXXX", "yyyy-MM-dd", "dd/MM/yyyy"]
        let df = DateFormatter(); df.locale = .init(identifier: "en_US_POSIX")
        for f in fmts { df.dateFormat = f; if let d = df.date(from: text) { return d } }
        return nil
    }

    private static func displaySexo(_ s: String?) -> String {
        switch (s ?? "").lowercased() {
        case "h", "hombre": return "Hombre"
        case "m", "mujer":  return "Mujer"
        case "o", "otro":   return "Otro"
        default:            return "Hombre"
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
                        ForEach(sexos, id: \.self, content: Text.init)
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
                    ForEach(roles, id: \.self, content: Text.init)
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
            sexo: FormView.sexoCode(for: sexo),
            fh_nac: FormView.displayDateFormatter.string(from: fechaNacimiento),
            id_rol: FormView.roleId(for: rol)
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

    private static func sexoCode(for display: String) -> String {
        switch display.lowercased() {
        case "hombre": return "h"
        case "mujer": return "m"
        default: return "o"
        }
    }

    private static func roleId(for role: String) -> Int {
        switch role {
        case "Estudiante": return 1
        case "Profesor": return 2
        default: return 3
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
