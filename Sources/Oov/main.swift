import Aegean
import Darwin.POSIX
import Foundation
import OoviumEngine

Math.start()

let isNotRunningInXcode: Bool = ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"]?.contains("com.apple.dt.Xcode") == false

func enableRawMode() {
    guard isNotRunningInXcode else { return }
    var raw = termios()
    tcgetattr(STDIN_FILENO, &raw)
    raw.c_lflag &= ~(UInt(ICANON | ECHO))
    raw.c_cc.17 = 0 // VMIN
    raw.c_cc.16 = 1 // VTIME
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
}
func disableRawMode() {
    guard isNotRunningInXcode else { return }
    var term = termios()
    tcgetattr(STDIN_FILENO, &term)
    term.c_lflag |= UInt(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &term)
}
func readChar() -> UInt8? {
    var char: UInt8 = 0
    let bytesRead = read(STDIN_FILENO, &char, 1)
    return bytesRead == 1 ? char : nil
}
func formatForExpression(_ obje: Obje) -> String {
    let display = obje.display
    switch obje.def {
        case is VectorDef:
            return "Vector(\(display.replacingOccurrences(of: " ", with: "")))"
        case is ComplexDef:
            let hasI: Bool = display.contains("i")
            let real: String
            let imag: String
            if let index = display.loc(of: "+", after: 1) {
                real = display[0...(index-1)]
                imag = (index+1) <= (display.count-2) ? display[(index+1)...(display.count-2)] : "1"
            } else if let index = display.loc(of: "-", after: 1) {
                real = display[0...(index-1)]
                imag = (index+1) <= (display.count-2) ? display[index...(display.count-2)] : "1"
            } else {
                real = hasI ? "0" : display
                imag = !hasI ? "0" : display.count == 1 ? "1" : display[...(display.count-2)]
            }
            return "Complex(\(real),\(imag))"
        case is StringDef:
            return "\"\(display)\""
        default:
            return display
    }
}

if CommandLine.arguments.count > 1 {

    let natural: String = CommandLine.arguments.dropFirst().joined(separator: " ")
    let chain: Chain = Chain(natural: natural)
    if let answer = chain.compile().calculate() { print(" = \(Obje(answer).display)") }

} else {
    
    print("Oovium =====================================================================")

    var previousObje: Obje?
        
    enableRawMode()
    defer { disableRawMode() }
    
    while true {
        print("Oov> ", terminator: "")
        fflush(stdout)
        var input = ""
        
        if isNotRunningInXcode {
            while true {
                guard let char = readChar() else { continue }
                
                if char == 9 { // Tab key
                    if let prev = previousObje {
                        let formattedPrev = formatForExpression(prev)
                        input += "prev"
                        print(formattedPrev, terminator: "")
                        fflush(stdout)
                    }
                } else if char == 10 { // Enter key
                    print()
                    break
                } else if char == 127 { // Backspace
                    if !input.isEmpty {
                        input.removeLast()
                        print("\u{8} \u{8}", terminator: "")
                        fflush(stdout)
                    }
                } else {
                    input.append(Character(UnicodeScalar(char)))
                    print(String(UnicodeScalar(char)), terminator: "")
                    fflush(stdout)
                }
            }
        } else { input = readLine()! }
        
        if input == "exit" { break }
        
        let chain = Chain(natural: input)
        let chainExe: ChainExe = chain.compile()
        var vars: [String:Obje] = [:]
        vars["prev"] = previousObje
        if let answer = chainExe.calculate(vars: vars) {
            let obje = Obje(answer)
            print(" = \(obje.display)")
            previousObje = obje
        }
    }
}
