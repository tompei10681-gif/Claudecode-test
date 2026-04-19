import SwiftUI
import PencilKit

struct HandwritingCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data?
    let background: DiaryEntry.PageBackground
    let isEditable: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.alwaysBounceVertical = true

        // Tool picker (Apple Pencil toolbar)
        if isEditable {
            let toolPicker = PKToolPicker()
            toolPicker.setVisible(true, forFirstResponder: canvas)
            toolPicker.addObserver(canvas)
            context.coordinator.toolPicker = toolPicker
            canvas.becomeFirstResponder()
        }

        // Restore saved drawing
        if let data = drawingData,
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if let data = drawingData,
           let drawing = try? PKDrawing(data: data),
           drawing.dataRepresentation() != uiView.drawing.dataRepresentation() {
            uiView.drawing = drawing
        }
        uiView.isUserInteractionEnabled = isEditable
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: HandwritingCanvasView
        var toolPicker: PKToolPicker?

        init(_ parent: HandwritingCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let data = canvasView.drawing.dataRepresentation()
            DispatchQueue.main.async {
                self.parent.drawingData = data
            }
        }
    }
}

// MARK: - Page background ruling overlay

struct PageRulingView: View {
    let background: DiaryEntry.PageBackground
    let lineColor = Color(.systemGray4)

    var body: some View {
        GeometryReader { geo in
            switch background {
            case .plain:
                Color.clear

            case .ruled:
                ruledLines(in: geo)

            case .grid:
                gridLines(in: geo)

            case .dotted:
                dottedGrid(in: geo)
            }
        }
    }

    private func ruledLines(in geo: GeometryProxy) -> some View {
        let lineSpacing: CGFloat = 36
        let count = Int(geo.size.height / lineSpacing) + 1
        return ForEach(0..<count, id: \.self) { i in
            let y = CGFloat(i) * lineSpacing + lineSpacing
            Path { path in
                path.move(to: CGPoint(x: 48, y: y))
                path.addLine(to: CGPoint(x: geo.size.width - 16, y: y))
            }
            .stroke(lineColor, lineWidth: 0.5)
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }

    private func gridLines(in geo: GeometryProxy) -> some View {
        let spacing: CGFloat = 28
        let hCount = Int(geo.size.width / spacing) + 1
        let vCount = Int(geo.size.height / spacing) + 1

        return ZStack {
            ForEach(0..<hCount, id: \.self) { i in
                let x = CGFloat(i) * spacing
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                .stroke(lineColor, lineWidth: 0.5)
            }
            ForEach(0..<vCount, id: \.self) { i in
                let y = CGFloat(i) * spacing
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                .stroke(lineColor, lineWidth: 0.5)
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }

    private func dottedGrid(in geo: GeometryProxy) -> some View {
        let spacing: CGFloat = 28
        let hCount = Int(geo.size.width / spacing) + 1
        let vCount = Int(geo.size.height / spacing) + 1

        return ForEach(0..<hCount, id: \.self) { i in
            ForEach(0..<vCount, id: \.self) { j in
                Circle()
                    .fill(lineColor)
                    .frame(width: 2, height: 2)
                    .position(x: CGFloat(i) * spacing, y: CGFloat(j) * spacing)
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }
}
