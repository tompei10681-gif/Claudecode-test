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

        if isEditable {
            let picker = PKToolPicker()
            picker.setVisible(true, forFirstResponder: canvas)
            picker.addObserver(canvas)
            context.coordinator.toolPicker = picker
            canvas.becomeFirstResponder()
        }

        if let data = drawingData, let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
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

struct PageRulingView: View {
    let background: DiaryEntry.PageBackground
    private let lineColor = Color(.systemGray4)

    var body: some View {
        GeometryReader { geo in
            switch background {
            case .plain:
                Color.clear
            case .ruled:
                ruledLines(geo)
            case .grid:
                gridLines(geo)
            case .dotted:
                dottedGrid(geo)
            }
        }
    }

    private func ruledLines(_ geo: GeometryProxy) -> some View {
        let spacing: CGFloat = 36
        let count = Int(geo.size.height / spacing) + 1
        return Canvas { ctx, size in
            for i in 0..<count {
                let y = CGFloat(i) * spacing + spacing
                var path = Path()
                path.move(to: CGPoint(x: 48, y: y))
                path.addLine(to: CGPoint(x: size.width - 16, y: y))
                ctx.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
        }
    }

    private func gridLines(_ geo: GeometryProxy) -> some View {
        let sp: CGFloat = 28
        return Canvas { ctx, size in
            for i in 0...Int(size.width / sp) {
                var p = Path()
                p.move(to: CGPoint(x: CGFloat(i) * sp, y: 0))
                p.addLine(to: CGPoint(x: CGFloat(i) * sp, y: size.height))
                ctx.stroke(p, with: .color(lineColor), lineWidth: 0.5)
            }
            for j in 0...Int(size.height / sp) {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: CGFloat(j) * sp))
                p.addLine(to: CGPoint(x: size.width, y: CGFloat(j) * sp))
                ctx.stroke(p, with: .color(lineColor), lineWidth: 0.5)
            }
        }
    }

    private func dottedGrid(_ geo: GeometryProxy) -> some View {
        let sp: CGFloat = 28
        return Canvas { ctx, size in
            for i in 0...Int(size.width / sp) {
                for j in 0...Int(size.height / sp) {
                    let rect = CGRect(x: CGFloat(i) * sp - 1, y: CGFloat(j) * sp - 1, width: 2, height: 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(lineColor))
                }
            }
        }
    }
}
