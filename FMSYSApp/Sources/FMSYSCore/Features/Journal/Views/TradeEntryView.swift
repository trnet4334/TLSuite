import SwiftUI

public struct TradeEntryView: View {
    @State private var viewModel: TradeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var asset = ""
    @State private var direction: Direction = .long
    @State private var assetCategory: AssetCategory = .forex
    @State private var entryPriceText = ""
    @State private var stopLossText = ""
    @State private var takeProfitText = ""
    @State private var positionSizeText = ""

    public init(viewModel: TradeViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }

    private var isValid: Bool {
        !asset.isEmpty
        && Double(entryPriceText) != nil
        && Double(stopLossText) != nil
        && Double(takeProfitText) != nil
        && Double(positionSizeText) != nil
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Asset") {
                    TextField("e.g. EUR/USD", text: $asset)

                    Picker("Category", selection: $assetCategory) {
                        ForEach([AssetCategory.forex, .crypto, .stocks, .futures, .options, .commodities], id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }

                    Picker("Direction", selection: $direction) {
                        Text("Long").tag(Direction.long)
                        Text("Short").tag(Direction.short)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Prices") {
                    HStack {
                        Text("Entry Price")
                        Spacer()
                        TextField("0.00000", text: $entryPriceText)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Stop Loss")
                        Spacer()
                        TextField("0.00000", text: $stopLossText)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Take Profit")
                        Spacer()
                        TextField("0.00000", text: $takeProfitText)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("Position Size")
                        Spacer()
                        TextField("1.0", text: $positionSizeText)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
            }
            .navigationTitle("New Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let entry = Double(entryPriceText),
                              let sl = Double(stopLossText),
                              let tp = Double(takeProfitText),
                              let size = Double(positionSizeText) else { return }
                        viewModel.createTrade(
                            asset: asset.uppercased(),
                            assetCategory: assetCategory,
                            direction: direction,
                            entryPrice: entry,
                            stopLoss: sl,
                            takeProfit: tp,
                            positionSize: size
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
