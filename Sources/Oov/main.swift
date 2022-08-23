
import Aegean
import OoviumEngine

print("Oovium =====================================================================")

Math.start()

while true {
	print("Oov> ", separator: "", terminator: "")
    let response: String? = readLine()
	if let response = response {
        guard response != "exit" else { break }

		let chain: Chain = Chain(natural: response)
		if let answer = chain.calculate() { print(" = \(Obje(answer).display)") }
	}
}
