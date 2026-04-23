import SwiftUI
import PencilKit

struct HandwritingCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data?
    let isEditable: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.alwaysBounceVertical = true

        if let data = drawingData, let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        if isEditable {
            let picker = PKToolPicker()
            context.coordinator.toolPicker = picker
            picker.addObserver(canvas)
            // Defer until view is in the hierarchy
            DispatchQueue.main.async {
                picker.setVisible(true, forFirstResponder: canvas)
                canvas.becomeFirstResponder()
            }
        }
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.isUserInteractionEnabled = isEditable
        if let data = drawingData,
           let drawing = try? PKDrawing(data: data),
           drawing.dataRepresentation() != uiView.drawing.dataRepresentation() {
            uiView.drawing = drawing
        }
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: HandwritingCanvasView
        var toolPicker: PKToolPicker?

        init(_ parent: HandwritingCanvasView) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let data = canvasView.drawing.dataRepresentation()
            DispatchQueue.main.async { self.parent.drawingData = data }
        }
    }
}

// Use a single Canvas view for all backgrounds to avoid SwiftUI type-mismatch errors
struct PageRulingView: View {
    let background: DiaryEntry.PageBackground
    private let lineColor = Color(.systemGray4)

    var body: some View {
        Canvas { ctx, size in
            switch background {
            case .plain:
                break

            case .ruled:
                let spacing: CGFloat = 36
                let count = Int(size.height / spacing) + 2
                for i in 0..<count {
                    let y = CGFloat(i) * spacing + spacing
                    var path = Path()
                    path.move(to: CGPoint(x: 48, y: y))
                    path.addLine(to: CGPoint(x: size.width - 16, y: y))
                    ctx.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                }

            case .grid:
                let sp: CGFloat = 28
                let cols = Int(size.width / sp) + 2
                let rows = Int(size.height / sp) + 2
                for i in 0..<cols {
                    var p = Path()
                    p.move(to: CGPoint(x: CGFloat(i) * sp, y: 0))
                    p.addLine(to: CGPoint(x: CGFloat(i) * sp, y: size.height))
                    ctx.stroke(p, with: .color(lineColor), lineWidth: 0.5)
                }
                for j in 0..<rows {
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: CGFloat(j) * sp))
                    p.addLine(to: CGPoint(x: size.width, y: CGFloat(j) * sp))
                    ctx.stroke(p, with: .color(lineColor), lineWidth: 0.5)
                }

            case .dotted:
                let sp: CGFloat = 28
                let cols = Int(size.width / sp) + 2
                let rows = Int(size.height / sp) + 2
                for i in 0..<cols {
                    for j in 0..<rows {
                        let rect = CGRect(
                            x: CGFloat(i) * sp - 1,
                            y: CGFloat(j) * sp - 1,
                            width: 2, height: 2
                        )
                        ctx.fill(Path(ellipseIn: rect), with: .color(lineColor))
                    }
                }
            }
        }
    }
}
