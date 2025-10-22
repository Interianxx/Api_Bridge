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

    private var isValid: Bool {
        !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apellido.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func parseDate(_ text: String?) -> Date? {
        guard let text = text else { return nil }
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: text) { return d }
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
                    // validar
                    guard !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          !apellido.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    else { print("Formulario inválido"); return }

                    func sexoCode(_ s: String) -> String {
                        switch s.lowercased() { case "hombre": return "h"; case "mujer": return "m"; default: return "o" }
                    }
                    func formatDate(_ d: Date) -> String {
                        let f = DateFormatter(); f.locale = .init(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
                        return f.string(from: d)
                    }
                    func roleId(_ r: String) -> Int {
                        switch r { case "Estudiante": return 1; case "Profesor": return 2; default: return 3 }
                    }

                    struct PersonaBody: Encodable {
                        let id_persona: Int
                        let nombre: String
                        let apellido: String
                        let sexo: String
                        let fh_nac: String
                        let id_rol: Int
                    }

                    let isEdit = (persona?.id != nil)
                    let body = PersonaBody(
                        id_persona: isEdit ? persona!.id : 0,
                        nombre: nombre,
                        apellido: apellido,
                        sexo: sexoCode(sexo),
                        fh_nac: formatDate(fechaNacimiento),
                        id_rol: roleId(rol)
                    )

                    guard let json = try? JSONEncoder().encode(body),
                          let jsonStr = String(data: json, encoding: .utf8) else {
                        print("Error al codificar JSON"); return
                    }

                    let api = ApiBridge()
                    let send: (@escaping (String?) -> Void) -> Void = { done in
                        if isEdit {
                            api.patch(endpoint: "/escuela/persona", body: jsonStr, completion: done)
                        } else {
                            api.post(endpoint: "/escuela/persona", body: jsonStr, completion: done)
                        }
                    }

                    send { _ in
                        DispatchQueue.main.async { dismiss() } // regresa a la lista
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }


        }

        .formStyle(.grouped)                    // ← estilo iOS clásico
    }
}

#Preview { NavigationStack { FormView() } }
