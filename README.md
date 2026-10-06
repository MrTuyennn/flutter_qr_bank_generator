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

### QrGeneratorView vs. QrGeneratorImage

There are two widgets to render a QR code:

* **`QrGeneratorView`** (default) — a native platform view
  (`AndroidView`/`UiKitView`). Paints instantly, but being a native view, it
  **can't be captured** with a `RepaintBoundary`/`RenderRepaintBoundary.toImage()`
  screenshot (it shows up blank).
* **`QrGeneratorImage`** — the same bytes `downloadQrCode`/`shareQrCode`
  produce, displayed with a plain `Image.memory`. Renders asynchronously
  (there's a brief loading gap — customize it with `loadingBuilder`/
  `errorBuilder`), but being a normal Flutter widget, it **can** be
  captured with a `RepaintBoundary`.

Both take the same constructors (`content:`, `.bank(bankData:)`,
`.from(data:)`). Use `QrGeneratorView` by default; switch to
`QrGeneratorImage` only where you need to screenshot the QR together with
other Flutter content.

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

`BankQrData` validates its fields and throws an `ArgumentError` if any rule
is violated — invalid values are rejected, never silently fixed up:

* `bankBin` — required, trimmed, exactly 6 digits.
* `accountNumber` — required, trimmed, digits only, 6–19 characters (leading
  zeros preserved).
* `amount` — optional (omit for a static QR); if given, digits only, no
  separators/decimals/currency symbols, 1–13 digits, and greater than 0.
* `content` — optional; trimmed with repeated whitespace collapsed to a
  single space, at most 25 characters, letters/digits/spaces only (no
  Vietnamese diacritics or special characters).

### Download / share

`downloadQrCode`/`shareQrCode` regenerate the exact same QR (content/image)
natively. Once a `QrGeneratorView` has rendered on screen, you don't need to
pass its content again — they default to the content of the most recently
rendered `QrGeneratorView`:

```dart
QrGeneratorView.bank(bankData: bankData, image: 'https://example.com/logo.png')
...
await downloadQrCode(); // save a PNG to the photo gallery
await shareQrCode(text: 'My QR'); // open the share sheet
```

Both also take an optional `fileName` (defaults to `'qrcode'`); `shareQrCode`
additionally takes an optional `text` caption. Both return `true` on success.

Platform requirements:

* **Android** — no setup needed. Saving uses `MediaStore` (no runtime
  permission on API 29+); the plugin declares `WRITE_EXTERNAL_STORAGE` with
  `maxSdkVersion="28"` for older devices.
* **iOS** — add `NSPhotoLibraryAddUsageDescription` to your app's
  `Info.plist` (required by `downloadQrCode`, which asks for photo-library
  add-only access).
