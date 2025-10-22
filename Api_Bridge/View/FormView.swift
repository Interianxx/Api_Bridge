//
//  FormView.swift
//  Api_Bridge
//
//  Created by Jose Alejandro Interian Pech on 21/10/25.
//

import SwiftUI



/// Vista que permite crear o editar una instancia de `Persona`.
struct FormView: View {
    /// Texto ingresado en el campo «Nombre».
    @State private var nombre = ""
    /// Texto ingresado en el campo «Apellido».
    @State private var apellido = ""
    /// Selección actual del segmento «Sexo».
    @State private var sexo = "Hombre"
    /// Fecha capturada en el selector de nacimiento.
    @State private var fechaNacimiento = Date()
    /// Opción elegida en el selector de rol.
    @State private var rol = "Estudiante"
    /// Controla cuál campo de texto tiene foco dentro del formulario.
    @FocusState private var focusedField: Field?

    /// Acción de entorno utilizada para cerrar la vista al finalizar.
    @Environment(\.dismiss) private var dismiss

    /// Persona recibida cuando el formulario se utiliza en modo edición.
    let persona: Persona?

    /// Inicializa el formulario precargando la información existente (si aplica).
    init(persona: Persona? = nil) {
        self.persona = persona
        _nombre = State(initialValue: persona?.nombre ?? "")
        _apellido = State(initialValue: persona?.apellido ?? "")
        _sexo = State(initialValue: FormView.displaySexo(persona?.sexo))   // ← aquí
        _fechaNacimiento = State(initialValue: FormView.parseDate(persona?.fh_nac) ?? Date())
        _rol = State(initialValue: persona?.rol ?? "Estudiante")
    }

    /// Campos de texto que pueden requerir foco del teclado.
    enum Field { case nombre, apellido }

    /// Opciones visibles para la selección de sexo.
    private let sexos = ["Hombre", "Mujer", "Otro"]
    /// Opciones visibles para la selección de rol.
    private let roles = ["Estudiante", "Profesor", "Otro"]

    /// Versión sin espacios del nombre para validaciones y envío.
    private var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// Versión sin espacios del apellido para validaciones y envío.
    private var apellidoLimpio: String { apellido.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// Indicador que valida la presencia de nombre y apellido.
    private var isValid: Bool { !nombreLimpio.isEmpty && !apellidoLimpio.isEmpty }

    /// Formateador reutilizable para fechas en formato ISO-8601.
    private static let isoFormatter = ISO8601DateFormatter()
    /// Formateador que produce la cadena esperada por el backend (`yyyy-MM-dd`).
    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Intenta convertir distintos formatos de fecha en un objeto `Date`.
    private static func parseDate(_ text: String?) -> Date? {
        guard let text = text else { return nil }
        if let d = isoFormatter.date(from: text) { return d }
        let fmts = ["yyyy-MM-dd'T'HH:mm:ssXXXXX", "yyyy-MM-dd", "dd/MM/yyyy"]
        let df = DateFormatter(); df.locale = .init(identifier: "en_US_POSIX")
        for f in fmts { df.dateFormat = f; if let d = df.date(from: text) { return d } }
        return nil
    }

    /// Traduce los códigos almacenados en la base al texto mostrado en el formulario.
    private static func displaySexo(_ s: String?) -> String {
        switch (s ?? "").lowercased() {
        case "h", "hombre": return "Hombre"
        case "m", "mujer":  return "Mujer"
        case "o", "otro":   return "Otro"
        default:            return "Hombre"
        }
    }

    /// Construye la jerarquía visual del formulario de captura.
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

    /// Arma la petición HTTP para guardar o actualizar la persona.
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
        // Una vez que la petición responde, cerramos el formulario.
        let completion: (String?) -> Void = { _ in
            DispatchQueue.main.async { dismiss() }
        }

        if isEdit {
            api.patch(endpoint: "/escuela/persona", body: jsonStr, completion: completion)
        } else {
            api.post(endpoint: "/escuela/persona", body: jsonStr, completion: completion)
        }
    }

    /// Convierte la selección de sexo a la codificación esperada por la API.
    private static func sexoCode(for display: String) -> String {
        switch display.lowercased() {
        case "hombre": return "h"
        case "mujer": return "m"
        default: return "o"
        }
    }

    /// Obtiene el identificador de rol que espera el backend para cada opción.
    private static func roleId(for role: String) -> Int {
        switch role {
        case "Estudiante": return 1
        case "Profesor": return 2
        default: return 3
        }
    }

    /// Modelo intermedio que se codifica a JSON para enviar a la API.
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
