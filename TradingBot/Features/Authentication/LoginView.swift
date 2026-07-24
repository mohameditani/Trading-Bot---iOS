import SwiftUI

struct LoginView: View {
    let session: SessionController
    @State private var username = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case username, password
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(AppColors.pnlPositive)
                    Text("Trading Bot")
                        .font(.largeTitle.bold())
                    Text("Sign in to your dashboard")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                }

                CardView {
                    VStack(spacing: 16) {
                        TextField("Username", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .username)
                            .accessibilityIdentifier("usernameField")
                        Divider()
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .accessibilityIdentifier("passwordField")
                    }
                }

                if let error = session.errorMessage {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.pnlNegative)
                        .accessibilityIdentifier("loginError")
                }

                Button {
                    focusedField = nil
                    Task { await session.login(username: username, password: password) }
                } label: {
                    Text("Sign In")
                        .font(AppTypography.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(username.isEmpty || password.isEmpty)
                .accessibilityIdentifier("signInButton")

                Spacer()
                Spacer()
            }
            .padding(24)
            .background(AppColors.screenBackground)
            .onSubmit {
                focusedField = focusedField == .username ? .password : nil
            }
        }
    }
}
