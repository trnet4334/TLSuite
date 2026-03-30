import SwiftUI

public struct DailyChecklistCard: View {
    @Bindable var viewModel: ChecklistViewModel
    @State private var editingId: UUID?
    @Environment(LanguageManager.self) private var lang

    public init(viewModel: ChecklistViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsPrimary)
                Text("dashboard.checklist.title", bundle: lang.bundle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button {
                    viewModel.add(title: String(localized: "dashboard.checklist.new_item_placeholder", bundle: lang.bundle))
                    editingId = viewModel.items.last?.id
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.fmsPrimary)
                        .frame(width: 24, height: 24)
                        .background(Color.fmsPrimary.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            if viewModel.items.isEmpty {
                Text("dashboard.checklist.empty_hint", bundle: lang.bundle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.items) { item in
                        ChecklistRow(
                            item: item,
                            isEditing: editingId == item.id,
                            onToggle: { viewModel.toggle(id: item.id) },
                            onRename: { newTitle in
                                viewModel.rename(id: item.id, title: newTitle)
                                editingId = nil
                            },
                            onTapLabel: { editingId = item.id },
                            onDelete: { viewModel.delete(id: item.id) }
                        )
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ChecklistRow: View {
    let item: ChecklistItem
    let isEditing: Bool
    let onToggle: () -> Void
    let onRename: (String) -> Void
    let onTapLabel: () -> Void
    let onDelete: () -> Void

    @State private var editText = ""
    @FocusState private var isFocused: Bool
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        HStack(spacing: 10) {
            Button { onToggle() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.isChecked ? Color.fmsPrimary : Color.clear)
                        .frame(width: 16, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            item.isChecked ? Color.fmsPrimary : Color.fmsMuted.opacity(0.6),
                            lineWidth: 1.5
                        )
                        .frame(width: 16, height: 16)
                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.fmsBackground)
                    }
                }
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField(String(localized: "dashboard.checklist.item_title_placeholder", bundle: lang.bundle), text: $editText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsOnSurface)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onAppear {
                        editText = item.title
                        isFocused = true
                    }
                    .onSubmit { onRename(editText) }
            } else {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(item.isChecked ? Color.fmsMuted : Color.fmsOnSurface.opacity(0.85))
                    .strikethrough(item.isChecked, color: Color.fmsMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture { onTapLabel() }
            }

            Button { onDelete() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.fmsMuted.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }
}
