import SwiftUI
import AppKit

struct ContentView: View {
    @AppStorage("lastProjectPath") private var lastProjectPath: String = ""
    @AppStorage("recentProjectPaths") private var recentProjectPathsRaw: String = ""

    @State private var selectedFolderURL: URL?
    @State private var statusMessage: String = "Elige una carpeta para empezar."

    private let maxRecentProjects = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            selectedProjectCard
            mainButtons
            recentProjectsSection
            statusText
        }
        .padding(24)
        .frame(width: 520)
        .onAppear {
            loadLastProject()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "terminal.fill")
                    .font(.largeTitle)

                Text("OpenCode Launcher")
                    .font(.largeTitle.bold())
            }

            Text("Abre OpenCode rápido en tus proyectos.")
                .foregroundStyle(.secondary)
        }
    }

    private var selectedProjectCard: some View {
        GroupBox {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Proyecto actual")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(projectURL?.path ?? "Ninguna carpeta seleccionada")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private var mainButtons: some View {
        HStack {
            Button {
                chooseFolder()
            } label: {
                Label("Elegir carpeta", systemImage: "folder")
            }

            Button {
                openSelectedProject()
            } label: {
                Label("Abrir", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(projectURL == nil)
        }
    }

    private var recentProjectsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Recientes", systemImage: "clock")
                        .font(.headline)

                    Spacer()

                    Button("Limpiar") {
                        clearRecentProjects()
                    }
                    .disabled(recentProjectURLs.isEmpty)
                }

                if recentProjectURLs.isEmpty {
                    Text("Todavía no hay carpetas recientes.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentProjectURLs, id: \.path) { url in
                        recentProjectRow(url)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func recentProjectRow(_ url: URL) -> some View {
        HStack {
            Button {
                selectProject(url)
            } label: {
                HStack {
                    Image(systemName: "folder")

                    VStack(alignment: .leading, spacing: 2) {
                        Text(url.lastPathComponent)
                            .font(.body)

                        Text(url.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button {
                selectedFolderURL = url
                openSelectedProject()
            } label: {
                Image(systemName: "play.circle.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private var statusText: some View {
        Text(statusMessage)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }

    private var projectURL: URL? {
        if let selectedFolderURL {
            return selectedFolderURL
        }

        guard !lastProjectPath.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: lastProjectPath)
    }

    private var recentProjectURLs: [URL] {
        recentProjectPathsRaw
            .split(separator: "\n")
            .map(String.init)
            .map { URL(fileURLWithPath: $0) }
    }

    private func loadLastProject() {
        guard !lastProjectPath.isEmpty else {
            return
        }

        selectedFolderURL = URL(fileURLWithPath: lastProjectPath)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()

        panel.title = "Elige el proyecto para OpenCode"
        panel.message = "Selecciona la carpeta donde quieres trabajar."
        panel.prompt = "Usar esta carpeta"

        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        if let projectURL {
            panel.directoryURL = projectURL
        }

        let response = panel.runModal()

        guard response == .OK, let url = panel.url else {
            statusMessage = "No se seleccionó ninguna carpeta."
            return
        }

        selectProject(url)
    }

    private func selectProject(_ url: URL) {
        selectedFolderURL = url
        lastProjectPath = url.path
        saveRecentProject(url)
        statusMessage = "Proyecto seleccionado: \(url.lastPathComponent)."
    }

    private func saveRecentProject(_ url: URL) {
        var paths = recentProjectURLs.map(\.path)

        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)

        paths = Array(paths.prefix(maxRecentProjects))

        recentProjectPathsRaw = paths.joined(separator: "\n")
    }

    private func clearRecentProjects() {
        recentProjectPathsRaw = ""
        statusMessage = "Carpetas recientes limpiadas."
    }

    private func openSelectedProject() {
        guard let projectURL else {
            statusMessage = "Primero elige una carpeta."
            return
        }

        saveRecentProject(projectURL)

        do {
            let terminal = try AutoTerminal.findBestAvailable()
            let command = OpenCodeCommand.make(for: projectURL)

            try terminal.open(command: command, projectURL: projectURL)

            statusMessage = "OpenCode abierto en \(terminal.name)."
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Terminal automático

enum AutoTerminal: CaseIterable {
    case ghostty
    case kitty
    case wezTerm
    case alacritty
    case iTerm
    case terminal

    var name: String {
        switch self {
        case .ghostty: return "Ghostty"
        case .kitty: return "Kitty"
        case .wezTerm: return "WezTerm"
        case .alacritty: return "Alacritty"
        case .iTerm: return "iTerm2"
        case .terminal: return "Terminal"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .ghostty: return "com.mitchellh.ghostty"
        case .kitty: return "net.kovidgoyal.kitty"
        case .wezTerm: return "com.github.wez.wezterm"
        case .alacritty: return "org.alacritty"
        case .iTerm: return "com.googlecode.iterm2"
        case .terminal: return "com.apple.Terminal"
        }
    }

    static func findBestAvailable() throws -> AutoTerminal {
        let priority: [AutoTerminal] = [
            .ghostty,
            .kitty,
            .wezTerm,
            .alacritty,
            .iTerm,
            .terminal
        ]

        guard let terminal = priority.first(where: { $0.isInstalled }) else {
            throw LauncherError.noTerminalFound
        }

        return terminal
    }

    private var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        ) != nil
    }

    private var appURL: URL? {
        NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        )
    }

    func open(command: String, projectURL: URL) throws {
        switch self {
        case .ghostty:
            try openAppExecutable(arguments: [
                "--working-directory=\(projectURL.path)",
                "-e",
                "/bin/zsh",
                "-lc",
                command
            ])

        case .kitty:
            try openAppExecutable(arguments: [
                "--directory",
                projectURL.path,
                "/bin/zsh",
                "-lc",
                command
            ])

        case .wezTerm:
            try openAppExecutable(arguments: [
                "start",
                "--cwd",
                projectURL.path,
                "--",
                "/bin/zsh",
                "-lc",
                command
            ])

        case .alacritty:
            try openAppExecutable(arguments: [
                "--working-directory",
                projectURL.path,
                "-e",
                "/bin/zsh",
                "-lc",
                command
            ])

        case .iTerm:
            try openWithAppleScript(
                """
                tell application id "com.googlecode.iterm2"
                    activate
                    create window with default profile
                    tell current session of current window
                        write text \(command.appleScriptQuoted)
                    end tell
                end tell
                """
            )

        case .terminal:
            try openWithAppleScript(
                """
                tell application "Terminal"
                    activate
                    do script \(command.appleScriptQuoted)
                end tell
                """
            )
        }
    }

    private func openAppExecutable(arguments: [String]) throws {
        guard let appURL,
              let bundle = Bundle(url: appURL),
              let executableURL = bundle.executableURL else {
            throw LauncherError.executableNotFound(name)
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        try process.run()
    }

    private func openWithAppleScript(_ source: String) throws {
        var error: NSDictionary?

        guard let script = NSAppleScript(source: source) else {
            throw LauncherError.appleScriptCreationFailed
        }

        script.executeAndReturnError(&error)

        if let error {
            throw LauncherError.appleScriptFailed(error.description)
        }
    }
}

// MARK: - Comando

enum OpenCodeCommand {
    static func make(for projectURL: URL) -> String {
        let path = projectURL.path.shellEscaped

        return """
        cd \(path) && export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH" && opencode; echo; echo "OpenCode terminó. Puedes cerrar esta ventana."; exec /bin/zsh -l
        """
    }
}

// MARK: - Errores

enum LauncherError: LocalizedError {
    case noTerminalFound
    case executableNotFound(String)
    case appleScriptCreationFailed
    case appleScriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .noTerminalFound:
            return "No se encontró ninguna terminal compatible."

        case .executableNotFound(let appName):
            return "No se encontró el ejecutable de \(appName)."

        case .appleScriptCreationFailed:
            return "No se pudo crear el AppleScript."

        case .appleScriptFailed(let message):
            return message
        }
    }
}

// MARK: - Helpers

extension String {
    var shellEscaped: String {
        "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    var appleScriptQuoted: String {
        let escaped = self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return "\"\(escaped)\""
    }
}
