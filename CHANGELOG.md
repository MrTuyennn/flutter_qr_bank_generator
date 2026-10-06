## 1.0.4

* Added `QrGeneratorImage` — renders the QR as a plain `Image.memory` widget (same bytes as `downloadQrCode`/`shareQrCode`) instead of a native platform view. Unlike `QrGeneratorView`, it can be captured with a `RepaintBoundary`/`RenderRepaintBoundary.toImage()` screenshot.
* Added `downloadImageBytes()`/`shareImageBytes()` — save or share arbitrary PNG bytes (e.g. a custom screenshot) without generating a QR.

## 1.0.3

* Fix some bug.

## 1.0.2

* Added `downloadQrCode()` and `shareQrCode()` — generate a QR (same rendering as `QrGeneratorView`, no widget required) and save it to the gallery or open the native share sheet. Android uses `MediaStore`/`FileProvider`; iOS uses `PHPhotoLibrary`/`UIActivityViewController` (requires `NSPhotoLibraryAddUsageDescription` in the host app's `Info.plist`).
* Added `QrData` and `QrGeneratorView.from`. `downloadQrCode`/`shareQrCode` default to the `QrData` of the most recently rendered `QrGeneratorView`, so you don't need to pass content/image again after displaying it; pass `data:` explicitly when multiple QR codes are on screen at once.
* Removed the black border around the center image overlay on Android (icon now sits on a plain white circle, matching iOS).

## 1.0.1

* `BankQrData` validates `bankBin`, `accountNumber`, `amount`, and `content`, throwing `ArgumentError` on invalid input instead of silently fixing it up.

## 0.0.1

* Native QR code view (Android ZXing / iOS CoreImage) with optional center image overlay — `image` accepts a network URL, a base64 string/data URI, or a Flutter asset path.
* NAPAS bank-transfer payload builder, via `QrGeneratorView.bank(bankData: BankQrData(...))`.
