//
//  DataViews.swift
//  Denrim
//
//  Created by Markus Moenig on 26/12/21.
//

import SwiftUI

/// DataFloatSliderView
struct DataFloatSliderView: View {
    
    //let model                               : Model
    let groupName                           : String

    var value                               : Binding<Float>
    var valueText                           : Binding<String>
    var range                               : Binding<float2>

    var factor                              : CGFloat = 1

    @State var clipWidth                    : CGFloat = 0
    
    @State var color                        : Color

    init(/*_ model: Model,*/_ name : String,_ value :Binding<Float>,_ valueText :Binding<String>,_ range: Binding<float2>,_ color: Color = Color.accentColor,_ factor: CGFloat = 1)
    {
        //self.model = model
        self.groupName = name
        self.value = value
        self.valueText = valueText
        self.range = range
        self.color = color
        self.factor = factor
        
        //valueText.wrappedValue = String(format: "%.02f", value.wrappedValue)
    }

    var body: some View {
            
        GeometryReader { geom in
            Canvas { context, size in
                context.fill(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8),
                    with: .color(.gray))
                
                var maskedContext = context

                maskedContext.clip(
                    to: Path(roundedRect: CGRect(origin: .zero, size: CGSize(width: getClipWidth(size.width), height: size.height)), cornerRadius: 0))
                
                maskedContext.fill(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8),
                    with: .color(color))

                context.draw(Text(valueText.wrappedValue), at: CGPoint(x: geom.size.width / 2, y: 9), anchor: .center)
                
            }
            .frame(width: geom.size.width, height: 19)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                
                    .onChanged({ info in
                        
                        let offset = Float(info.location.x / geom.size.width)
                
                        let r = range.wrappedValue
                
                        var newValue = r.x + (r.y - r.x) * offset
                        newValue = max(newValue, r.x)
                        newValue = min(newValue, r.y)
                    
                        value.wrappedValue = newValue
                        valueText.wrappedValue = String(format: "%.02f",  newValue)
                        
                        //model.updateSelectedGroup(groupName: groupName)
                    })
                    .onEnded({ info in
                    })
            )
        }
        
        //.onReceive(model.updateDataViews) { _ in
        //    valueText.wrappedValue = String(format: "%.02f", value.wrappedValue)
        //}
    }
    
    func getClipWidth(_ width: CGFloat) -> CGFloat {
        let v = value.wrappedValue
        let r = range.wrappedValue

        let off = CGFloat((v - r.x) / (r.y - r.x))
        return off * width
    }
}

/// DataIntSliderView
struct DataIntSliderView: View {
    
    //let model                               : Model
    let groupName                           : String

    var value                               : Binding<Float>
    var valueText                           : Binding<String>
    var range                               : Binding<float2>

    var factor                              : CGFloat = 1

    @State var clipWidth                    : CGFloat = 0
    
    @State var color                        : Color

    init(/*_ model: Model,*/_ name : String,_ value :Binding<Float>,_ valueText :Binding<String>,_ range: Binding<float2>,_ color: Color = Color.accentColor,_ factor: CGFloat = 1)
    {
        //self.model = model
        self.groupName = name
        self.value = value
        self.valueText = valueText
        self.range = range
        self.color = color
        self.factor = factor
        
        //valueText.wrappedValue = String(format: "%.02f", value.wrappedValue)
    }

    var body: some View {
            
        GeometryReader { geom in
            Canvas { context, size in
                context.fill(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8),
                    with: .color(.gray))
                
                var maskedContext = context

                maskedContext.clip(
                    to: Path(roundedRect: CGRect(origin: .zero, size: CGSize(width: getClipWidth(size.width), height: size.height)), cornerRadius: 0))
                
                maskedContext.fill(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8),
                    with: .color(color))

                context.draw(Text(valueText.wrappedValue), at: CGPoint(x: geom.size.width / 2, y: 9), anchor: .center)
                
            }
            .frame(width: geom.size.width, height: 19)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                
                    .onChanged({ info in
                        
                        let offset = Float(info.location.x / geom.size.width)
                
                        let r = range.wrappedValue
                
                        var newValue = r.x + (r.y - r.x) * offset
                        newValue = max(newValue, r.x)
                        newValue = min(newValue, r.y)
                    
                        value.wrappedValue = Float(Int(newValue))
                        valueText.wrappedValue = String(Int(newValue))
                        
                        //model.updateSelectedGroup(groupName: groupName)
                    })
                    .onEnded({ info in
                    })
            )
        }
        
        //.onReceive(model.updateDataViews) { _ in
        //    valueText.wrappedValue = String(Int(value.wrappedValue))
        //}
    }
    
    func getClipWidth(_ width: CGFloat) -> CGFloat {
        let v = value.wrappedValue
        let r = range.wrappedValue

        let off = CGFloat((v - r.x) / (r.y - r.x))
        return off * width
    }
}
