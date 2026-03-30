import SwiftUI

public struct TradeEntryView: View {
    @Environment(LanguageManager.self) private var lang
    let initialCategory: JournalCategory
    let viewModel: TradeViewModel
    let onDismiss: () -> Void

    @State private var selectedCategory: JournalCategory
    @State private var asset = ""
    @State private var direction: Direction = .long

    // Common
    @State private var entryPriceText = ""
    @State private var exitPriceText = ""
    @State private var positionSizeText = ""
    @State private var notesText = ""

    // Stocks
    @State private var stopLossText = ""

    // Forex
    @State private var pipValueText = ""
    @State private var lotSizeText = ""
    @State private var exposureText = ""

    // Crypto
    @State private var leverageText = ""
    @State private var fundingRateText = ""
    @State private var walletText = ""

    // Options
    @State private var strikeText = ""
    @State private var expirationDate = Date()
    @State private var costBasisText = ""

    public init(
        initialCategory: JournalCategory,
        viewModel: TradeViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.initialCategory = initialCategory
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        let cat = initialCategory == .all ? JournalCategory.stocksETFs : initialCategory
        self._selectedCategory = State(wrappedValue: cat)
    }

    private var isValid: Bool {
        !asset.trimmingCharacters(in: .whitespaces).isEmpty && Double(entryPriceText) != nil
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Glass backdrop — tap outside to dismiss
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Modal card
            VStack(spacing: 0) {
                modalHeader
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        categorySwitcher
                        assetAndDirectionRow
                        executionDetailsSection
                        notesSection
                    }
                    .padding(24)
                }
                Divider()
                modalFooter
            }
            .frame(width: 560)
            .frame(maxHeight: 700)
            .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25), radius: 40, x: 0, y: 20)
            // Prevent backdrop tap from propagating through card
            .contentShape(Rectangle())
            .onTapGesture {}
        }
    }

    // MARK: - Header

    private var modalHeader: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.fmsPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.fmsPrimary.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("journal.entry.title", bundle: lang.bundle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("journal.entry.subtitle", bundle: lang.bundle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(width: 28, height: 28)
                    .background(Color.fmsSurface, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Category Switcher

    private var categorySwitcher: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("journal.entry.category", bundle: lang.bundle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 2) {
                ForEach(
                    [JournalCategory.stocksETFs, .forex, .options, .crypto],
                    id: \.self
                ) { cat in
                    Button(cat.rawValue) {
                        selectedCategory = cat
                    }
                    .buttonStyle(.plain)
                    .font(.system(
                        size: 12,
                        weight: selectedCategory == cat ? .bold : .medium
                    ))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        selectedCategory == cat ? Color.fmsBackground : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .foregroundStyle(
                        selectedCategory == cat ? Color.fmsPrimary : Color.fmsMuted
                    )
                }
            }
            .padding(4)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Asset + Direction

    private var assetAndDirectionRow: some View {
        HStack(spacing: 16) {
            // Asset ticker
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel(String(localized: "journal.entry.asset_ticker", bundle: lang.bundle))
                HStack(spacing: 6) {
                    TextField(assetPlaceholder, text: $asset)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsOnSurface)
                        .autocorrectionDisabled()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
                .padding(10)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.fmsMuted.opacity(0.15), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity)

            // Direction / Call-Put toggle
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel(String(localized: "journal.entry.direction", bundle: lang.bundle))
                HStack(spacing: 2) {
                    Button {
                        direction = .long
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                            Text(selectedCategory == .options
                                 ? String(localized: "journal.entry.direction.call", bundle: lang.bundle)
                                 : String(localized: "journal.entry.direction.long", bundle: lang.bundle))
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            direction == .long ? Color.fmsPrimary : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                        .foregroundStyle(
                            direction == .long ? Color.fmsBackground : Color.fmsMuted
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        direction = .short
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            Text(selectedCategory == .options
                                 ? String(localized: "journal.entry.direction.put",   bundle: lang.bundle)
                                 : String(localized: "journal.entry.direction.short", bundle: lang.bundle))
                                .font(.system(size: 11, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            direction == .short ? Color.fmsLoss : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                        .foregroundStyle(
                            direction == .short ? Color.white : Color.fmsMuted
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var assetPlaceholder: String {
        switch selectedCategory {
        case .stocksETFs, .all: return "e.g. AAPL"
        case .forex:            return "e.g. EUR/USD"
        case .crypto:           return "e.g. BTC/USDT"
        case .options:          return "e.g. AAPL"
        }
    }

    // MARK: - Execution Details

    private var executionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsPrimary)
                Text("journal.entry.execution_details", bundle: lang.bundle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .tracking(0.5)
            }
            Divider()
            switch selectedCategory {
            case .stocksETFs, .all: stocksFields
            case .forex:            forexFields
            case .crypto:           cryptoFields
            case .options:          optionsFields
            }
        }
    }

    private var stocksFields: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            entryField(label: String(localized: "journal.entry.field.entry_price",         bundle: lang.bundle), prefix: "$", text: $entryPriceText, placeholder: "0.00")
            entryField(label: String(localized: "journal.entry.field.exit_price_optional",  bundle: lang.bundle), prefix: "$", text: $exitPriceText,  placeholder: "0.00")
            entryField(label: String(localized: "journal.entry.field.quantity_shares",      bundle: lang.bundle), text: $positionSizeText, placeholder: "0")
            entryField(label: String(localized: "journal.entry.field.stop_loss",            bundle: lang.bundle), prefix: "$", text: $stopLossText,   placeholder: "0.00")
        }
    }

    private var forexFields: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            entryField(label: String(localized: "journal.entry.field.entry_price",   bundle: lang.bundle), prefix: "$", text: $entryPriceText, placeholder: "1.0850")
            entryField(label: String(localized: "journal.entry.field.exit_price",    bundle: lang.bundle), prefix: "$", text: $exitPriceText,  placeholder: "1.0920")
            entryField(label: String(localized: "journal.entry.field.pip_value",     bundle: lang.bundle), text: $pipValueText,   placeholder: "10.00")
            entryField(label: String(localized: "journal.entry.field.lot_size",      bundle: lang.bundle), text: $lotSizeText,    placeholder: "1.0")
            entryField(label: String(localized: "journal.entry.field.exposure",      bundle: lang.bundle), text: $exposureText,   placeholder: "150000")
            entryField(label: String(localized: "journal.entry.field.position_size", bundle: lang.bundle), text: $positionSizeText, placeholder: "1")
        }
    }

    private var cryptoFields: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            entryField(label: String(localized: "journal.entry.field.entry_price",          bundle: lang.bundle), prefix: "$", text: $entryPriceText, placeholder: "0.00")
            entryField(label: String(localized: "journal.entry.field.exit_price",           bundle: lang.bundle), prefix: "$", text: $exitPriceText,  placeholder: "0.00")
            entryField(label: String(localized: "journal.entry.field.leverage",             bundle: lang.bundle), suffix: "x", text: $leverageText,   placeholder: "1")
            entryField(label: String(localized: "journal.entry.field.funding_rate",         bundle: lang.bundle), suffix: "%", text: $fundingRateText, placeholder: "0.01")
            entryField(label: String(localized: "journal.entry.field.position_size",        bundle: lang.bundle), text: $positionSizeText, placeholder: "0")
            entryField(label: String(localized: "journal.entry.field.wallet_address",       bundle: lang.bundle), text: $walletText,        placeholder: "0x...")
        }
    }

    private var optionsFields: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            entryField(label: String(localized: "journal.entry.field.strike_price",        bundle: lang.bundle), prefix: "$", text: $strikeText,       placeholder: "0.00")
            expirationField
            entryField(label: String(localized: "journal.entry.field.quantity_contracts",  bundle: lang.bundle), text: $positionSizeText,  placeholder: "1")
            entryField(label: String(localized: "journal.entry.field.cost_basis",          bundle: lang.bundle), prefix: "$", text: $costBasisText,    placeholder: "0.00")
            entryField(label: String(localized: "journal.entry.field.entry_price_premium", bundle: lang.bundle), prefix: "$", text: $entryPriceText,   placeholder: "0.00")
            entryField(label: String(localized: "journal.entry.field.exit_price_optional", bundle: lang.bundle), prefix: "$", text: $exitPriceText,    placeholder: "0.00")
        }
    }

    private var expirationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(String(localized: "journal.entry.field.expiration_date", bundle: lang.bundle))
            DatePicker("", selection: $expirationDate, displayedComponents: .date)
                .labelsHidden()
                .padding(8)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.fmsMuted.opacity(0.15), lineWidth: 1)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("journal.entry.notes_reflection", bundle: lang.bundle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
            TextEditor(text: $notesText)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsOnSurface)
                .frame(minHeight: 80)
                .padding(10)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.fmsMuted.opacity(0.15), lineWidth: 1)
                )
                .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Footer

    private var modalFooter: some View {
        HStack {
            Spacer()
            Button(String(localized: "common.cancel", bundle: lang.bundle)) { onDismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fmsMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
            Button(String(localized: "journal.entry.save_trade", bundle: lang.bundle)) { saveTrade() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    isValid ? Color.fmsPrimary : Color.fmsMuted.opacity(0.3),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .foregroundStyle(isValid ? Color.fmsBackground : Color.fmsMuted)
                .disabled(!isValid)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func entryField(
        label: String,
        prefix: String? = nil,
        suffix: String? = nil,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(label)
            HStack(spacing: 4) {
                if let prefix {
                    Text(prefix)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsMuted)
                }
                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsOnSurface)
                if let suffix {
                    Text(suffix)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            .padding(8)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.fmsMuted.opacity(0.15), lineWidth: 1)
            )
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.fmsMuted)
    }

    // MARK: - Save

    private func saveTrade() {
        guard let entryPrice = Double(entryPriceText) else { return }
        let exitPrice = Double(exitPriceText)
        let positionSize = Double(positionSizeText) ?? 1

        viewModel.createTrade(
            asset: asset.trimmingCharacters(in: .whitespaces).uppercased(),
            journalCategory: selectedCategory,
            direction: direction,
            entryPrice: entryPrice,
            exitPrice: exitPrice,
            positionSize: positionSize,
            notes: notesText.isEmpty ? nil : notesText,
            pipValue: Double(pipValueText),
            lotSize: Double(lotSizeText),
            exposure: Double(exposureText),
            leverage: Double(leverageText),
            fundingRate: Double(fundingRateText),
            walletAddress: walletText.isEmpty ? nil : walletText,
            strikePrice: Double(strikeText),
            expirationDate: selectedCategory == .options ? expirationDate : nil,
            costBasis: Double(costBasisText)
        )
        onDismiss()
    }
}
