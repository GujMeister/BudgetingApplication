import SwiftUI

struct RecurringPage: View {
    @StateObject private var viewModel = RecurringPageViewModel()
    @State private var shouldAnimate = true
    @State private var isEditing = false
    
    let columns = [
        GridItem(.flexible(minimum: 100, maximum: .infinity)),
        GridItem(.flexible(minimum: 100, maximum: .infinity)),
    ]
    
    var body: some View {
        VStack {
            ZStack {
                CustomSegmentedControlViewRepresentable(
                    color: .customLightBlue,
                    controlItems: ["Subscriptions", "Payments", "Overview"],
                    defaultIndex: viewModel.selectedSegmentIndex,
                    segmentChangeCallback: { index in
                        viewModel.selectedSegmentIndex = index
                    },
                    shouldAnimate: $shouldAnimate
                )
                .frame(height: 60)
                .padding(.top, 195)
                
                NavigationRectangleRepresentable(
                    height: 0,
                    color: .customBlue,
                    totalBudgetedMoney: NumberFormatterHelper.shared.format(amount: totalBudgetedMoneyHelper(), baseFont: UIFont(name: "Heebo-SemiBold", size: 36) ?? UIFont(), sizeDifference: 0.6),
                    descriptionLabelText: viewModel.descriptionLabelText
                )
                .edgesIgnoringSafeArea(.top)
                .frame(height: UIScreen.main.bounds.size.height / 5)
            }
            .edgesIgnoringSafeArea(.top)
            
            HStack {
                if viewModel.selectedSegmentIndex != 2 {
                    Menu {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Button(action: {
                                viewModel.selectedTimePeriod = period
                            }) {
                                Text(period.rawValue)
                            }
                        }
                    } label: {
                        Text(viewModel.selectedTimePeriod.rawValue.uppercased())
                            .font(.headline)
                            .foregroundStyle(.black)
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.black)
                    }
                } else {
                    
                }
                
                Spacer()
                
                if viewModel.selectedSegmentIndex == 2 {
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                            .foregroundStyle(.black)
                    }
                } else {
                    Button(action: {
                        if viewModel.selectedSegmentIndex == 0 {
                            presentAddSubscriptionVC()
                        } else if viewModel.selectedSegmentIndex == 1 {
                            presentAddPaymentVC()
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(.black)
                    }
                }
            }
            .padding([.leading, .trailing])
            .padding(.top, -95)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    if viewModel.selectedSegmentIndex == 0 {
                        ForEach(viewModel.filteredSubscriptionOccurrences, id: \.date) { occurrence in
                            RecurringView(
                                emoji: SubscriptionCategory.emoji(for: occurrence.category),
                                amount: occurrence.amount,
                                paymentDescription: occurrence.subscriptionDescription,
                                date: occurrence.date,
                                color: SubscriptionCategory.color(for: occurrence.category)
                            )
                        }
                    } else if viewModel.selectedSegmentIndex == 1 {
                        ForEach(viewModel.filteredPaymentOccurrences, id: \.date) { occurrence in
                            RecurringView(
                                emoji: PaymentsCategory.emoji(for: occurrence.category),
                                amount: occurrence.amount,
                                paymentDescription: occurrence.subscriptionDescription,
                                date: occurrence.date,
                                color: PaymentsCategory.color(for: occurrence.category)
                            )
                        }
                    } else {
                        if isEditing {
                            ForEach(viewModel.allSubscriptionExpenses) { subscription in
                                EditableRecurringView(
                                    amount: subscription.amount,
                                    paymentDescription: subscription.subscriptionDescription,
                                    date: subscription.startDate,
                                    color: subscription.category.color,
                                    deleteAction: {
                                        viewModel.deleteSubscriptionExpense(subscription)
                                    }
                                )
                            }

                            ForEach(viewModel.allPaymentExpenses) { payment in
                                EditableRecurringView(
                                    amount: payment.amount,
                                    paymentDescription: payment.paymentDescription,
                                    date: payment.startDate,
                                    color: payment.category.color,
                                    deleteAction: {
                                        viewModel.deletePaymentExpense(payment)
                                    }
                                )
                            }
                        } else {
                            ForEach(viewModel.allSubscriptionExpenses, id: \.subscriptionDescription) { subscription in
                                RecurringView(
                                    emoji: subscription.category.emoji,
                                    amount: subscription.amount,
                                    paymentDescription: subscription.subscriptionDescription,
                                    date: subscription.startDate,
                                    color: subscription.category.color,
                                    isOverview: true
                                )
                            }
                            ForEach(viewModel.allPaymentExpenses, id: \.paymentDescription) { payment in
                                RecurringView(
                                    emoji: payment.category.emoji,
                                    amount: payment.amount,
                                    paymentDescription: payment.paymentDescription,
                                    date: payment.startDate,
                                    color: payment.category.color,
                                    isOverview: true
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                viewModel.loadOccurrences()
                viewModel.loadAllExpenses()
            }
            .padding(.top, -70)
        }
        .background(
            Color(UIColor.customBackground)
        )
        .onAppear {
            viewModel.loadOccurrences()
            viewModel.loadAllExpenses()
        }
    }
    
    // MARK: - Helper Functions
    private func presentAddSubscriptionVC() {
        let addSubscriptionVC = AddSubscriptionVC()
        addSubscriptionVC.delegate = viewModel as? any AddSubscriptionDelegate
        UIApplication.shared.windows.first?.rootViewController?.present(addSubscriptionVC, animated: true, completion: nil)
    }
    
    private func presentAddPaymentVC() {
        let addPaymentVC = AddPaymentVC()
        addPaymentVC.delegate = viewModel as? any AddPaymentDelegate
        UIApplication.shared.windows.first?.rootViewController?.present(addPaymentVC, animated: true, completion: nil)
    }
    
    private func totalBudgetedMoneyHelper() -> Double {
        if viewModel.selectedSegmentIndex == 2 {
            return viewModel.listTotalBudgeted
        } else {
            return viewModel.totalBudgeted
        }
    }
}
// MARK: - Extracted Views
// MARK: Editable Payment Cell
struct EditableRecurringView: View {
    var amount: Double
    var paymentDescription: String
    var date: Date
    var color: UIColor
    var deleteAction: () -> Void
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(color))
                .frame(width: 10)
                .padding(.vertical, -18)
                .padding(.leading, -18)
            
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(paymentDescription)
                            .font(.custom("Heebo-SemiBold", size: 20))
                            .lineLimit(1)
                            .foregroundColor(.black)
                        
                        Text(PlainNumberFormatterHelper.shared.format(amount: amount))
                            .font(.custom("Inter-Regular", size: 15))
                            .foregroundStyle(.black)
                        
                        Text("Every month on \(Calendar.current.component(.day, from: date))\(daySuffix(for: date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                    }
                    
                    Spacer()
                    
                    Button(action: deleteAction) {
                        Image(systemName: "minus.circle")
                            .resizable()
                            .foregroundColor(.red)
                            .frame(width: 25, height: 25)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray5))
        .cornerRadius(15)
    }
}

// MARK: Payment Cell
struct RecurringView: View {
    var emoji: String
    var amount: Double
    var paymentDescription: String
    var date: Date
    var color: UIColor
    var isOverview: Bool = false
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(color))
                .frame(width: 10)
                .padding(.vertical, -18)
                .padding(.leading, -18)
            
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(paymentDescription)
                            .font(.custom("Heebo-SemiBold", size: 20))
                            .lineLimit(1)
                            .foregroundColor(.black)
                        
                        Text(PlainNumberFormatterHelper.shared.format(amount: amount))
                            .font(.custom("Inter-Regular", size: 15))
                            .foregroundStyle(.black)
                        
                        if isOverview {
                            Text("Every month on \(Calendar.current.component(.day, from: date))\(daySuffix(for: date))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 10)
                        } else {
                            Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 10)
                        }
                    }
                    
                    Spacer()
                    
                    Text(emoji)
                        .font(.system(size: 24))
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(color))
                                .padding(.all, -8)
                        )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray5))
        .cornerRadius(15)
    }
}

// MARK: - Representables
struct CustomSegmentedControlViewRepresentable: UIViewRepresentable {
    var color: UIColor
    var controlItems: [String]
    var defaultIndex: Int
    var segmentChangeCallback: ((Int) -> Void)?
    @Binding var shouldAnimate: Bool
    
    func makeUIView(context: Context) -> CustomSegmentedControlView {
        let view = CustomSegmentedControlView(color: color, controlItems: controlItems, defaultIndex: defaultIndex, segmentChangeCallback: segmentChangeCallback)
        if shouldAnimate {
            view.transform = CGAffineTransform(translationX: 0, y: -50)
            UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: {
                view.transform = .identity
            }, completion: { _ in
                shouldAnimate = false
            })
        }
        return view
    }
    
    func updateUIView(_ uiView: CustomSegmentedControlView, context: Context) {
        uiView.setSelectedIndex(defaultIndex)
    }
}

struct NavigationRectangleRepresentable: UIViewRepresentable {
    let height: CGFloat
    let color: UIColor
    let totalBudgetedMoney: NSAttributedString
    let descriptionLabelText: String
    
    func makeUIView(context: Context) -> NavigationRectangle {
        return NavigationRectangle(
            height: height,
            color: color,
            totalBudgetedMoney: totalBudgetedMoney,
            descriptionLabelText: descriptionLabelText
        )
    }
    
    func updateUIView(_ uiView: NavigationRectangle, context: Context) {
        uiView.totalBudgetedNumberLabel.attributedText = totalBudgetedMoney
        uiView.descriptionLabel.text = descriptionLabelText
    }
}

// MARK: - Preview
struct RecurringPage_Previews: PreviewProvider {
    static var previews: some View {
        RecurringPage()
        
        RecurringView(emoji: "🏠", amount: 1000, paymentDescription: "Vashlijvari", date: Date(), color: .customLightBlue)
            .frame(width: UIScreen.main.bounds.width / 2, height: 150)
        
        EditableRecurringView(amount: 200, paymentDescription: "Vashlijvari", date: Date(), color: .blue, deleteAction: {})
            .frame(width: UIScreen.main.bounds.width / 2, height: 150)
    }
}
