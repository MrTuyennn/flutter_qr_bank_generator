import SwiftUI

struct QrCodeView: View {
    @ObservedObject var model = QrCodeModel()

    var body: some View {
        VStack {
            Image(uiImage: model.qrcode ?? UIImage())
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
        }
    }
}
