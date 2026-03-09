import SwiftUI

/// Six-digit OTP input field with individual digit boxes.
public struct OTPFieldView: View {
    @Binding var code: String
    let onComplete: (String) -> Void

    private let length = 6

    public init(code: Binding<String>, onComplete: @escaping (String) -> Void = { _ in }) {
        self._code = code
        self.onComplete = onComplete
    }

    public var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<length, id: \.self) { index in
                digitBox(at: index)
            }
        }
        .overlay {
            // Hidden text field captures input
            TextField("", text: $code)
                .opacity(0.01)
                .onChange(of: code) { _, new in
                    let filtered = String(new.filter { $0.isNumber }.prefix(length))
                    if filtered != new { code = filtered }
                    if filtered.count == length { onComplete(filtered) }
                }
        }
    }

    private func digitBox(at index: Int) -> some View {
        let digits = Array(code)
        let char: String = index < digits.count ? String(digits[index]) : ""
        let isActive = index == code.count

        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.fmsPrimary : Color.fmsMuted.opacity(0.4), lineWidth: isActive ? 2 : 1)
                .frame(width: 44, height: 52)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
            Text(char)
                .font(.title2.bold())
                .foregroundStyle(Color.fmsOnSurface)
        }
    }
}
