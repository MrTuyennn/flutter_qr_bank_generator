# flutter_qr_bank_generator

Native QR code generation view (Android ZXing / iOS CoreImage) with image
overlay, including a NAPAS bank-transfer payload builder.

## Usage

### Plain content

```dart
QrGeneratorView(
  content: 'https://flutter.dev',
  image: 'https://flutter.dev/favicon.png', // optional center overlay
)
```

`image` accepts any of the following, auto-detected natively:

* a network URL (`http://` / `https://`)
* a base64-encoded image, optionally as a data URI (`data:image/png;base64,...`)
* a Flutter asset path declared in the host app's `pubspec.yaml` (e.g. `assets/logo.png`)

Falls back to the host app's `app_icon` drawable/asset if `image` is omitted
or fails to resolve.

### Bank transfer

Pass a `BankQrData` model to `QrGeneratorView.bank`:

```dart
QrGeneratorView.bank(
  bankData: BankQrData(
    bankBin: '970415',
    accountNumber: '113366668888',
    amount: '79000',      // optional
    content: 'Ung Ho Quy Vac Xin', // optional
  ),
)
```

If you have the fields as a JSON string instead, parse them into the model
first with `BankQrData.fromJson(...)`:

```dart
final bankData = BankQrData.fromJson(jsonString);
QrGeneratorView.bank(bankData: bankData)
```

`amount` and `content` are optional; omitting `amount` produces a static
(amount-less) bank-transfer QR code that the payer fills in themselves.
