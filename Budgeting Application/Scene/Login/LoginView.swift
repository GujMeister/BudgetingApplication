//
//  LoginView.swift
//  Budgeting Application
//
//  Created by Luka Gujejiani on 12.07.24.
//

import SwiftUI

struct LoginView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: LoginPageViewModel
    @AppStorage("userName") private var userName: String = ""

    @State private var passcode = ""
    @State private var isConfirmingPasscode = false
    @State private var topPasswordText = "Welcome"
    @State private var bottomPasswordText = "Create your 4-digit PIN to access your personal budgeting application"
    @State private var showText = false

    // MARK: - View
    var body: some View {
        VStack(spacing: 48) {
            VStack(spacing: 24) {
                Text(topPasswordText)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .opacity(showText ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1)) {
                            showText = true
                        }
                    }

                Text(bottomPasswordText)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)

            PasscodeIndicatorView(passcode: $passcode)

            Spacer()

            NumberPadView(passcode: $passcode)
                .onChange(of: passcode) { newPasscode in
                    if newPasscode.count == 4 {
                        handlePasscodeEntry(newPasscode)
                    }
                }
        }
        .padding()
        .onAppear {
            if viewModel.isPasscodeSet {
                topPasswordText = "Welcome back \(userName)"
                bottomPasswordText = "Enter your 4-digit PIN to log in to your personal budgeting application"
            }
        }
    }

    private func handlePasscodeEntry(_ enteredPasscode: String) {
        if !viewModel.isPasscodeSet {
            if isConfirmingPasscode {
                if viewModel.temporaryPasscode == enteredPasscode {
                    viewModel.setPasscode(enteredPasscode)
                    switchToMainTabBar()
                } else {
                    isConfirmingPasscode = false
                    passcode = ""
                    topPasswordText = "Enter Passcode"
                    presentAlert(title: "Error", message: "Passcodes do not match.")
                }
            } else {
                viewModel.temporaryPasscode = enteredPasscode
                isConfirmingPasscode = true
                passcode = ""
                topPasswordText = "Confirm Passcode"
                bottomPasswordText = "Repeat Your Passcode"
            }
        } else {
            if viewModel.isPasscodeCorrect(enteredPasscode) {
                switchToMainTabBar()
            } else {
                passcode = ""
                presentAlert(title: "Try Again", message: "Incorrect passcode.")

            }
        }
    }

    private func switchToMainTabBar() {
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.switchToMainTabBar()
        }
    }
}

#Preview {
    LoginView(viewModel: LoginPageViewModel())
}

// MARK: - Extracted Views
struct NumberPadView: View {
    // MARK: Properties
    @Binding var passcode: String
    @State private var scaleEffect: [Int: CGFloat] = [:]

    private let columns: [GridItem] = [
        .init(),
        .init(),
        .init()
    ]

    // MARK: View
    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(1...9, id: \.self) { index in
                Button {
                    addValue(index)
                    animateButton(index)
                } label: {
                    Text("\(index)")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                }
                .scaleEffect(scaleEffect[index] ?? 1.0)
                .animation(.easeInOut(duration: 0.1), value: scaleEffect[index])
            }

            Button {
                removeValue()
                animateButton(-1)
            } label: {
                Image(systemName: "delete.backward")
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
            }
            .scaleEffect(scaleEffect[-1] ?? 1.0)
            .animation(.easeInOut(duration: 0.1), value: scaleEffect[-1])

            Button {
                addValue(0)
                animateButton(0)
            } label: {
                Text("0")
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
            }
            .scaleEffect(scaleEffect[0] ?? 1.0)
            .animation(.easeInOut(duration: 0.1), value: scaleEffect[0])
        }
        .foregroundStyle(.primary)
    }

    private func addValue(_ value: Int) {
        if passcode.count < 4 {
            passcode += "\(value)"
        }
    }

    private func removeValue() {
        if !passcode.isEmpty {
            passcode.removeLast()
        }
    }

    private func animateButton(_ index: Int) {
        scaleEffect[index] = 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scaleEffect[index] = 1.0
        }
    }
}


struct PasscodeIndicatorView: View {
    // MARK: Properties
    @Binding var passcode: String

    // MARK: View
    var body: some View {
        HStack(spacing: 32) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(passcode.count > index ? .primary : Color.white)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Circle()
                            .stroke(.black, lineWidth: 1.0)
                    }
            }
        }
    }
}
