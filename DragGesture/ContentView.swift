
import SwiftUI

struct DrawPoints: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
    var color: Color = .black
    var thickness:CGFloat = 1.0
}

struct DrawPathView: View {
    let drawnPointsArray: [DrawPoints]
    let drawingPoints:DrawPoints
    
    init(drawnPointsArray: [DrawPoints],drawingPoints:DrawPoints) {
        self.drawnPointsArray = drawnPointsArray
        self.drawingPoints = drawingPoints
    }
    
    func draw(drawPoints:DrawPoints)->some View{
        return Path{ path in
            path.addLines(drawPoints.points)
        }.stroke(drawPoints.color,lineWidth: drawPoints.thickness)
    }
    
    var body: some View {
        ZStack {
            ForEach(drawnPointsArray) { data in
                self.draw(drawPoints: data)
            }
            self.draw(drawPoints: self.drawingPoints)
        }
    }
}

struct OverlayView: View {
    let colors:[Color] = [.black,.blue,.gray,.green,.orange,.pink,.purple,.red,.yellow,.white]
    @State private var colorIndex:Int = 1
    @State private var colorString:String = "blue"
    
    @State private var thickness:Int = 5
    
    @State private var drawingPoints: DrawPoints = DrawPoints()
    @State private var drawnPoints: [DrawPoints] = []
    
    var body: some View {
        
        let dragGesture = DragGesture()
            .onChanged{ value in
                self.drawingPoints.points.append(value.location)
                self.drawingPoints.color = self.colors[self.colorIndex]
                self.drawingPoints.thickness = CGFloat(self.thickness)
        }
        .onEnded{ value in
            self.drawnPoints.append(self.drawingPoints)
            self.drawingPoints = DrawPoints()
        }
        
        return
            VStack{
                ZStack{
                    Color.white
                    DrawPathView(drawnPointsArray: drawnPoints, drawingPoints: drawingPoints)
                }.gesture(dragGesture)
                
                HStack(spacing: 5.0){
                    HStack{
                        Stepper(value: $thickness, in: 1...30){
                            Spacer()
                            Text("Thickness:\(self.thickness)")
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        self.colorIndex += 1
                        self.colorIndex %= self.colors.count
                        self.colorString = self.colors[self.colorIndex].description
                    }){
                        Text(self.colorString)
                        .font(.caption)
                        .foregroundColor(.white)
                        Image(systemName: "square.fill")
                            .font(.largeTitle)
                            .foregroundColor(self.colors[self.colorIndex])
                            .padding(15.0)
                        
                    }
                    HStack{
                        Button(action: {
                            if self.drawnPoints.count>0{
                            self.drawnPoints.remove(at: self.drawnPoints.count - 1)
                            }
                        }){
                        Image(systemName: "delete.left.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .padding(15.0)
                        }
                    }
                }
        }
            .padding(20.0)
    }
}

struct ContentView: View {
    var body: some View {
        OverlayView()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
