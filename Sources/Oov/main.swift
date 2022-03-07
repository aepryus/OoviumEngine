
import Aegean
import OoviumEngine

print("Oovium =====================================================================")

Math.start()

while (true) {
	print("Oov> ", separator: "", terminator: "")
	let response = readLine();
	if let response = response {
		if response == "exit" {break}

		let chain: Chain = Chain(natural: response)
		if let answer = chain.calculate() { print(" = \(Obje(answer).display)") }
	}
}
