
import SwiftUI

struct DrawPoints: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
    var color: Color = .black
    var thickness:CGFloat = 1.0
    var opacity:Double = 0.5
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
            .opacity(drawPoints.opacity)
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
    
    @State private var thickness:Double = 5.0
    @State private var opacity:Double = 0.5
    
    @State private var drawingPoints: DrawPoints = DrawPoints()
    @State private var drawnPoints: [DrawPoints] = []
    
    @State var isPresented: Bool = false
    
    @State private var rect: CGRect = .zero
    @State var uiImage: UIImage? = nil
    
    var body: some View {
        
        let dragGesture = DragGesture()
            .onChanged{ value in
                self.drawingPoints.points.append(value.location)
                self.drawingPoints.color = self.colors[self.colorIndex]
                self.drawingPoints.thickness = CGFloat(self.thickness)
                self.drawingPoints.opacity = self.opacity
        }
        .onEnded{ value in
            self.drawnPoints.append(self.drawingPoints)
            self.drawingPoints = DrawPoints()
        }
        
        return
            VStack{
                ZStack{
                    Image("AH")
                        .resizable()
                        .frame(width: 200, height: 300)
                    DrawPathView(drawnPointsArray: drawnPoints, drawingPoints: drawingPoints)
                        .frame(width: 200, height: 300)
                }.gesture(dragGesture)
                    .background(RectangleGetter(rect: $rect))
                
                VStack(spacing: 5.0){
                    
                    
                    HStack{
                        Text("Thickness:\( Int(self.thickness))")
                            .foregroundColor(.gray)
                        Slider(value: self.$thickness, in: 1...50)
                    }.padding(10)
                    
                    HStack{
                        Text("Opacity:\(String(format:"%.1f", self.opacity))")
                        .foregroundColor(.gray)
                        Slider(value: self.$opacity, in: 0...1)
                    }.padding(10)
                    
                    
                    
                    Button(action: {
                        self.colorIndex += 1
                        self.colorIndex %= self.colors.count
                        self.colorString = self.colors[self.colorIndex].description
                    }){
                        HStack{
                        Text("Color:\(self.colorString)")
                            .foregroundColor(.gray)
                            
                        Spacer()
                        Image(systemName: "square.fill")
                            .font(.largeTitle)
                            .foregroundColor(self.colors[self.colorIndex])
                            
                        }.padding(10.0)
                    }
                    HStack{
                        Button(action: {
                            if self.drawnPoints.count>0{
                                self.drawnPoints.remove(at: self.drawnPoints.count - 1)
                            }
                        }){
                            
                            Text("Undo Drawing")
                            .foregroundColor(.gray)
                                
                            Spacer()
                            Image(systemName: "arrow.uturn.left.square.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                
                        }.padding(10.0)
                    }
                    VStack {
                        Button("present") {
                            self.uiImage = UIApplication.shared.windows[0].rootViewController?.view!.getImage(rect: self.rect)
                            self.isPresented.toggle()
                        }
                    }
                    .sheet(isPresented: $isPresented) {
                        SubContentView(uiImage: self.uiImage!)
                    }
                }
        }
    }
}

struct SubContentView: View {
    let uiImage:UIImage
    @State private var angle:CGFloat = 0.0
    @State private var zIndex:[Double] = [0,-1]
    var body: some View {
        ZStack{
            Image(uiImage: self.uiImage)
                .resizable()
                .frame(width: 200 * 0.99, height: 300 * 0.99)
                .modifier(FlipEffect(index: 0, initialAngle: 0.0, angle: self.angle, zIndex: self.$zIndex[0]))
                .zIndex(self.zIndex[0])
            
            Image("blue_back")
                .resizable()
                .frame(width: 200, height: 300)
                .modifier(FlipEffect(index: 1, initialAngle: 0.0, angle: self.angle, zIndex: self.$zIndex[1]))
                .zIndex(self.zIndex[1])
            
        }.onTapGesture {
            withAnimation(.linear(duration: 3.0)){
                self.angle += .pi
            }
        }
    }
}

struct FlipEffect:GeometryEffect{
    let index:Int
    let initialAngle:CGFloat
    var angle:CGFloat
    
    
    @Binding var zIndex:Double{
        willSet{
            print(newValue)
        }
    }
    
    var animatableData: CGFloat{
        get{angle}
        set{angle = newValue}
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        var transform3d = CATransform3DIdentity
        transform3d.m34 = -1/max(size.width, size.height)
        transform3d = CATransform3DRotate(transform3d, self.angle, 1.0, 5.0, 0.0)
        transform3d = CATransform3DTranslate(transform3d, -size.width/2, -size.height/2, 0.0)
        DispatchQueue.main.async {
            self.zIndex = Double(transform3d.m34)
            if self.index == 1{
                self.zIndex *= -1
            }
        }
        let affineTransform = ProjectionTransform(CGAffineTransform(translationX: size.width/2, y: size.height/2))
        return ProjectionTransform(transform3d).concatenating(affineTransform)
    }
}


struct RectangleGetter: View {
    @Binding var rect: CGRect
    
    var body: some View {
        GeometryReader { geometry in
            self.createView(proxy: geometry)
        }
    }
    
    func createView(proxy: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            self.rect = proxy.frame(in: .global)
        }
        return Rectangle().fill(Color.clear)
    }
}

extension UIView {
    func getImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
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
