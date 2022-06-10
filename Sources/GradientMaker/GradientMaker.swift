//
//  GradientMakerView.swift
//  NailMaker
//
//  Created by Russell Savage on 2/20/22.
//

import SwiftUI
import Combine

enum ViewUtils {
    static var safeKeyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
    } 
    
    static func when(hasChild: UIView, timeout: Double = 10.0, onComplete: @escaping (UIView)->Void) {
        guard timeout > 0 else { print("ViewUtils.when(hasChild:) timed out!"); return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.00001) {
            if let child = hasChild.subviews.first {
                onComplete(child)
            } else {
                Self.when(hasChild: hasChild, timeout: timeout - 0.00001, onComplete: onComplete)
            }
        }
    }
}

private class ColorPickerChooser {
    
    private class InternalPicker: UIColorPickerViewController {
        
        var onAppear: ((UIView)-> Void)?
        
        override func viewDidAppear(_ animated: Bool) {
            ViewUtils.when(hasChild: self.view) { self.onAppear?($0) }
            
            super.viewDidAppear(animated)
        }
    }
    
    internal static var shared = ColorPickerChooser()
    
    private var cancellable: AnyCancellable? = nil
    private var pickerView: InternalPicker?
    
    private var firstViewController: UIViewController? {
        let root = ViewUtils.safeKeyWindow?.rootViewController
        return root?.presentedViewController ?? root?.navigationController?.topViewController
    }
    
    public func presentColorPicker(color: Color, y: CGFloat, onUpdate: @escaping (Color) -> Void) {
        let picker = InternalPicker()
        self.pickerView = picker
        picker.selectedColor = UIColor(color)

        cancellable = picker.publisher(for: \.selectedColor)
            .sink { color in
                DispatchQueue.main.async {
                    let newColor = Color(color)
                    onUpdate(newColor)
                }
            }

        guard let viewController = firstViewController else { return }
        viewController.view.addSubview(picker.view)
        viewController.addChild(picker)
        
        picker.view.translatesAutoresizingMaskIntoConstraints = false
        picker.view.leftAnchor.constraint(equalTo: viewController.view.leftAnchor).isActive = true
        picker.view.rightAnchor.constraint(equalTo: viewController.view.rightAnchor).isActive = true
        picker.view.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: y).isActive = true
        picker.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor).isActive = true

        picker.onAppear = {[weak self] view in
            guard let self = self else { return }
            let closeButton = UIButton(type: .close)
            closeButton.addTarget(self, action: #selector(self.closeChooser), for: .touchUpInside)
            view.addSubview(closeButton)

            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            closeButton.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            closeButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            closeButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        }
    }
    
    @objc
    private func closeChooser() {
        pickerView?.removeFromParent()
        pickerView?.view.removeFromSuperview()
    }
}

struct GradientMakerView: View {
    @State var stop: Gradient.Stop
    
    let onUpdate: (Gradient.Stop) -> Void

    @State private var startX: CGFloat = 0
    @State private var drag = CGSize.zero
    @State private var backgroundColor: Color = .pink
    
    var body: some View {

        GeometryReader { geometry in
            Circle()
                .onAppear(perform: {
                    startX = (geometry.size.width - 40) * stop.location
                })
                .foregroundColor(stop.color)
                .frame(width: 40, height: 40)
                .shadow(radius: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 40 / 2.0).stroke(Color.white, lineWidth: 2.0)
                )
                .offset(x: min(max(startX + drag.width, 0.0), geometry.size.width-40), y: 0)
                .animation(Animation.spring().speed(2))
                .gesture(
                    DragGesture().onChanged{ (value) in
                        drag = value.translation
                        let loc = startX + drag.width
                        let adjusted = (loc / (geometry.size.width - 40))
                        stop.location = min(max(adjusted, 0.0), 1.0)
                        
                        onUpdate(stop)
                    }.onEnded { _ in
                        startX = startX + drag.width
                        drag = .zero
                    }
                ).onTapGesture {
                    let y = geometry.frame(in: .global).minY
                    ColorPickerChooser.shared.presentColorPicker(color: stop.color, y: y) { color in
                        stop.color = color
                        onUpdate(stop)
                    }
                }
        }
    }
    
}

public struct GradientMaker: View {
    
    let onUpdate: ([Gradient.Stop]) -> Void
    @State var stops: [Gradient.Stop]
    
    public init(stops: [Gradient.Stop], onUpdate: @escaping ([Gradient.Stop]) -> Void) {
        self.stops = stops
        self.onUpdate = onUpdate
    }

    public var body: some View {
        let gradient = Gradient(stops: stops)
        VStack {
//            let arrStr = stops.map{ "\($0.location)" }
//            let joinedString = arrStr.joined(separator: ",")
//            Text("\(joinedString)")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(minWidth: 0, idealWidth: 300, maxWidth: .infinity, minHeight: 0, idealHeight: 40, maxHeight: 40)
                
                ForEach(stops.indices, id: \.self) { i in
                    GradientMakerView(stop: stops[i], onUpdate:{ stop in
                        stops[i] = stop
     
                        onUpdate(stops)
                    })
                }
            }
        }
    }
}

struct GradientPickerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GradientMaker(stops: [
                Gradient.Stop(color: Color.red, location: 0.0),
                Gradient.Stop(color: Color.yellow, location: 1.0)],
                               onUpdate: { _ in })
        }
    }
}
