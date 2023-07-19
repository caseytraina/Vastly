//
//  AuthorProfileView.swift
//  Vastly
//
//  Created by Casey Traina on 8/19/23.
//

import SwiftUI

struct AuthorProfileView: View {
    
    var author: Author
    
    @State private var gradientColor: Color = Color("BackgroundColor")
    @Binding var publisherIsTapped: Bool
    @State private var uiImage: UIImage?

    var body: some View {
        
        ZStack {
            Color.black
                .ignoresSafeArea()
                .opacity(0.75)
                .onTapGesture {
//                    withAnimation {
                        publisherIsTapped = false
//                    }
                }
            GeometryReader { geo in
                ZStack {
                    LinearGradient(colors: [gradientColor, Color("BackgroundColor"), Color("BackgroundColor")], startPoint: .top, endPoint: .bottom)
                        .transition(.opacity)
                        .animation(.linear, value: gradientColor)
                        .ignoresSafeArea()
    //                Color("BackgroundColor")
    //                    .ignoresSafeArea()
                    VStack {
                        HStack{
                            Spacer()
                            Button(action: {
//                                withAnimation {
                                    publisherIsTapped = false
//                                }
                            }, label: {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: screenSize.width * 0.04, weight: .light))
                                
                            })
                            .padding(.trailing)
                            .padding(.top)

                        }
                        
                        VStack {
                            if let image = uiImage {
                                Image(uiImage: image)
                                    .resizable()
//                                    .onAppear {
//                                        gradientColor image.
//                                    }
                                
                            } else {
                                ZStack {
                                    Color("BackgroundColor")
                                    MyText(text: "No Image", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .white)
                                }
                            }
                            
                            
                            //                            AsyncImage(url: author.fileName) { image in
                            //                                image.resizable()
                            //
                            //                            } placeholder: {
                            //                                ZStack {
                            //                                    Color("BackgroundColor")
                            //                                    MyText(text: "No Image", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .white)
                            //                                }
                            //                            }
                        }
                            .frame(width: geo.size.width * 0.35, height: geo.size.width * 0.35)
                            .clipShape(RoundedRectangle(cornerRadius: 0)) // Clips the AsyncImage to a rounded
                            .padding(.top, 30)
                        .padding(.bottom, 10)


                        
                        MyText(text: author.name ?? "Unknown Author", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .white)
                        Spacer()
                        ScrollView(showsIndicators: false) {
                            VStack {
                                MyText(text: author.bio ?? "No Bio Found.", size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                                    .padding(30)
                            }
                        }
                        .frame(maxHeight: geo.size.width * 0.4)
                        Spacer()
                        
                        HStack {
                            if author.website != "" {
                                
                                Button(action: {
                                    openURL(author.website ?? "")
                                }) {
                                    Image(systemName: "link.circle.fill")
                                        .foregroundColor(.white)
                                    //                        .frame(width: geo.size.width * 0.075, height: geo.size.width * 0.075)
                                        .font(.system(size: screenSize.width * 0.09, weight: .medium))
                                }
                                

                            }
                            if author.spotify != "" {
                                
                                Button(action: {
                                    openURL(author.spotify ?? "")
                                }) {
                                    Image("spotify")
                                        .resizable()
                                        .frame(width: geo.size.width * 0.09, height: geo.size.width * 0.09)
                                }
                                .padding(.horizontal)
                            }
                            if author.apple != "" {
                                
                                Button(action: {
                                    openURL(author.apple ?? "")
                                }) {
                                    Image("applePodcasts")
                                        .resizable()
                                        .frame(width: geo.size.width * 0.09, height: geo.size.width * 0.09)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.bottom, 25)
                        
                        
                        
                    }
                }
                .onAppear {
                    fetchImage()
//                    if let url = author.fileName {
//                        fetchImage(from: url) { (fetchedImage) in
//                            guard let image = fetchedImage else {
//                                print("Failed to fetch image.")
//                                return
//                            }
//
//                            if let avgColor = averageColor(of: image) {
//                                gradientColor = avgColor
//                                print(avgColor)
//                            }
//                        }
//                    }
                }
//                .border(.white)
                
                .cornerRadius(20)
                .frame(width: screenSize.width * 0.9, height: screenSize.height * 0.6)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .shadow(color: Color("AccentGray"), radius: 1)
        }
    }
    
    func fetchImage() {
        URLSession.shared.dataTask(with: author.fileName ?? EMPTY_AUTHOR.fileName!) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                    self.gradientColor = image.averageColor ?? .accentColor
                }
            }
        }.resume()
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        UIApplication.shared.open(url)
    }
//
//    func fetchImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
//        URLSession.shared.dataTask(with: url) { (data, response, error) in
//            guard let data = data, let image = UIImage(data: data) else {
//                completion(nil)
//                return
//            }
//            completion(image)
//        }.resume()
//    }
//
    func averageColor(of image: UIImage) -> Color {
        guard let inputImage = CIImage(image: image) else { return Color.clear }
        
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return Color.clear }
        guard let outputImage = filter.outputImage else { return Color.clear }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return Color(red: Double(bitmap[0]) / 255.0, green: Double(bitmap[1]) / 255.0, blue: Double(bitmap[2]) / 255.0, opacity: Double(bitmap[3]) / 255.0)
    }

    
}

//struct AuthorProfileView_Previews: PreviewProvider {
//    
//    
//    
//    static var previews: some View {
//        AuthorProfileView(author: EXAMPLE_AUTHOR)
//    }
//}
extension UIImage {
    var averageColor: Color? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return Color(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255)
    }
}
