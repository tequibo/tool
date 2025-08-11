import SwiftUI
import CompactSlider
struct ConsoleView: View {
	@ObservedObject var viewModel: SharedObject

	@State private var inputText: String = ""
	@State private var logMessages: [String] = []

	var body: some View {
		VStack(alignment: .center) {
			VStack(alignment: .leading) {
//				Slider(value: $viewModel.steps, in: 0...550){
////					Text("Steps")
//				}
//				.accentColor(.cyan)
//				.background(.white)
				
				Text("RECORD")
				Text("Q - movement ")
				Text("W - rotation")
				Text("tab - scale ")
				
				Text("§ - settings ")
				Text("1 - debug ")
				Text("F - circle radius")
				
//				Text("FPS: \(GLOBAL)")
				
//
					
				CompactSlider(value: $viewModel.steps, in: 1...550, step: 1) {
					Text("Steps")
					Spacer()
					Text("\(Int(viewModel.steps))")
				}.compactSliderStyle(.custom)
				CompactSlider(value: $viewModel.loopTime, in: 0...155, step: 1) {
					Text("Time")
					Spacer()
					Text("\(Int(viewModel.loopTime))")
				}.compactSliderStyle(.custom)
				CompactSlider(value: $viewModel.fpsExport, in: 1...120, step: 1) {
					Text("frames per second export")
					Spacer()
					Text("\(Int(viewModel.fpsExport))")
				}.compactSliderStyle(.custom)
				CompactSlider(value: $viewModel.offsetRatio, in: 0.0001...0.5, step: 0.001) {
					Text("offset: \(viewModel.offsetRatio)")
					Spacer()
					Text("\(viewModel.offsetRatio)")
				}.compactSliderStyle(.custom)
			}.padding()
			VStack(alignment: .leading) {
				Text("frames to export: \(viewModel.fpsExport*viewModel.loopTime)").foregroundStyle(.gray)
			}
			VStack(alignment: .leading) {
				Text(": \(viewModel.output)").foregroundStyle(.gray)
			}
			ScrollView {
				VStack(alignment: .leading, spacing: 0) {
					ForEach(logMessages, id: \.self) { message in
						Text(message).foregroundStyle(.gray)
							.padding(.horizontal)
					}
				}
			}
			.foregroundColor(Color.gray)
			.frame(maxWidth: 200, maxHeight: 200, alignment: .leading)
			.padding()

			HStack {
				TextField("Enter command", text: $inputText, onCommit: processCommand)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.frame(maxWidth: 200, maxHeight: 50, alignment: .leading)

//				Button("Send", action: processCommand)
			}
			.padding()
		}
//		.background(.white)
		.frame(maxWidth: .infinity, alignment: .center) // Align the outer VStack to the left edge
//		.padding(.leading) // Optional: add padding if you want some space from the edge
		
	}

	

	private func processCommand() {
		if inputText.isEmpty {
			return
		}
		
		let components = inputText.components(separatedBy: " ")
		let command = components.first ?? ""
		let arguments = components.dropFirst().joined(separator: " ")

		switch command {
		case "p": // Assume the rest is the prompt
			viewModel.prompt = arguments
			logMessage("Prompt set to: \(viewModel.prompt)")
		case "t":
			if let loopTime = TimeInterval(arguments) {
				viewModel.loopTime = loopTime
				logMessage("loop time set to: \(loopTime)")
			} else {
				logMessage("Invalid loop time value: \(arguments)")
			}
		case "f":
			if let frames = Int(arguments) {
				viewModel.fpsExport = Double(frames)
				logMessage("frames set to: \(frames)")
			} else {
				logMessage("Invalid steps value: \(arguments)")
			}
		case "s":
			if let steps = Double(arguments) {
				viewModel.steps = steps
				logMessage("Steps set to: \(steps)")
			} else {
				logMessage("Invalid steps value: \(arguments)")
			}
		case "a":
			if let angle = Float(arguments) {
				viewModel.angle = angle/360*Float.tau
				logMessage("Angle set to: \(angle)")
			} else {
				logMessage("Invalid steps value: \(arguments)")
			}
		default:
			logMessage("Unknown command: \(command)")
		}

		inputText = ""
	}





	private func logMessage(_ message: String) {
		logMessages.append(message)
		print(message)
	}
}
public struct CustomCompactSliderStyle: CompactSliderStyle {
	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundColor(
				configuration.isHovering || configuration.isDragging ? .black : .black
			)
			.background(
				Color.white
			)
			.accentColor(.cyan)
			.clipShape(RoundedRectangle(cornerRadius: 4))
	}
}

public extension CompactSliderStyle where Self == CustomCompactSliderStyle {
	static var `custom`: CustomCompactSliderStyle { CustomCompactSliderStyle() }
}
