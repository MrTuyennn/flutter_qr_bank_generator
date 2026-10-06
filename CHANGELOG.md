## 1.0.1

* `BankQrData` validates `bankBin`, `accountNumber`, `amount`, and `content`, throwing `ArgumentError` on invalid input instead of silently fixing it up.

## 0.0.1

* Native QR code view (Android ZXing / iOS CoreImage) with optional center image overlay — `image` accepts a network URL, a base64 string/data URI, or a Flutter asset path.
* NAPAS bank-transfer payload builder, via `QrGeneratorView.bank(bankData: BankQrData(...))`.
