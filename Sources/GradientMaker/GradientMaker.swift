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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .leastNonzeroMagnitude) {
            if let child = hasChild.subviews.first {
                onComplete(child)
            } else {
                Self.when(hasChild: hasChild, timeout: timeout - .leastNonzeroMagnitude, onComplete: onComplete)
            }
        }
    }
}

private class ColorPickerChooser {
    
    internal static var shared = ColorPickerChooser()
    
    private var cancellable: AnyCancellable? = nil
    private var pickerView: UIColorPickerViewController?
    private var background: UIView?
    
    private var firstViewController: UIViewController? {
        guard let root = ViewUtils.safeKeyWindow?.rootViewController else { return nil }
        return root.presentedViewController ?? root.navigationController?.topViewController ?? root
    }
    
    public func presentColorPicker(on: UIViewController? = nil, color: Color, offsetY: CGFloat, onUpdate: @escaping (Color) -> Void) {
        guard pickerView == nil else { closeChooser(); return }
        let picker = UIColorPickerViewController()
        self.pickerView = picker
        picker.selectedColor = UIColor(color)

        cancellable = picker.publisher(for: \.selectedColor)
            .sink { color in
                DispatchQueue.main.async {
                    let newColor = Color(color)
                    onUpdate(newColor)
                }
            }

        guard let viewController = on ?? firstViewController else { return }
        viewController.view.addSubview(picker.view)
        viewController.addChild(picker)
        
        picker.view.translatesAutoresizingMaskIntoConstraints = false
        picker.view.widthAnchor.constraint(equalToConstant: 500).isActive = true
        picker.view.heightAnchor.constraint(equalToConstant: 700).isActive = true
        if offsetY > viewController.view.frame.size.height * 0.5 { // below mid-screen
            picker.view.bottomAnchor.constraint(equalTo: viewController.view.topAnchor, constant: offsetY).isActive = true
        } else { // above mid-screen
            picker.view.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: offsetY + 20).isActive = true
        }
        
        ViewUtils.when(hasChild: picker.view) {[weak self] view in
            guard let self = self else { return }
            
            // background
            let background = UIView()
            background.backgroundColor = .systemGray
            background.layer.borderWidth = 2
            background.layer.borderColor = UIColor.systemGray.cgColor
            background.layer.cornerRadius = 20
            background.layer.masksToBounds = true
            viewController.view.insertSubview(background, belowSubview: picker.view)

            background.translatesAutoresizingMaskIntoConstraints = false
            background.topAnchor.constraint(equalTo: picker.view.topAnchor).isActive = true
            background.rightAnchor.constraint(equalTo: picker.view.rightAnchor).isActive = true
            background.leftAnchor.constraint(equalTo: picker.view.leftAnchor).isActive = true
            background.bottomAnchor.constraint(equalTo: picker.view.bottomAnchor).isActive = true
            background.isUserInteractionEnabled = true
            let captureTaps = UITapGestureRecognizer(target: self, action: #selector(self.closeChooser))
            captureTaps.cancelsTouchesInView = true
            background.addGestureRecognizer(captureTaps)
            self.background = background
                        
            let closeButton = UIButton(type: .close)
            closeButton.isUserInteractionEnabled = true
            closeButton.backgroundColor = .systemBackground
            closeButton.addTarget(self, action: #selector(self.closeChooser), for: .touchUpInside)
            view.addSubview(closeButton)

            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 2).isActive = true
            closeButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -2).isActive = true
            closeButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            closeButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
            closeButton.layer.cornerRadius = 20
            closeButton.layer.masksToBounds = true
        }
    }
    
    @objc
    private func closeChooser() {
        pickerView?.removeFromParent()
        pickerView?.view.removeFromSuperview()
        pickerView = nil
        background?.removeFromSuperview()
        background = nil
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
                    ColorPickerChooser.shared.presentColorPicker(color: stop.color, offsetY: y) { color in
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
        VStack {
            GradientMaker(stops: [
                Gradient.Stop(color: Color.red, location: 0.0),
                Gradient.Stop(color: Color.yellow, location: 1.0)],
                               onUpdate: { _ in })
            Spacer(minLength: 400)
            Spacer()
            GradientMaker(stops: [
                Gradient.Stop(color: Color.red, location: 0.0),
                Gradient.Stop(color: Color.yellow, location: 1.0)],
                               onUpdate: { _ in })
        }
    }
}
