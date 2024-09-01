import MEGADesignToken
import MEGAUI
import UIKit

final class NodeDescriptionViewCell: UITableViewCell {
    private let textView: AutoGrowingTextView

    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    var viewModel: NodeDescriptionCellViewModel? {
        didSet {
            guard let viewModel else { return }
            if let description = viewModel.description() {
                textView.text = description.text
                textView.textColor = textColor(isPlaceholderText: description.isPlaceholder)
            }

            textView.isEditable = !viewModel.editingDisabled
            updateInsets(viewModel.textViewEdgeInsets)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textView = AutoGrowingTextView(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        guard let viewModel else { return .zero }

        // Actual width available for the text view is cell width - textview insets
        var targetSize = targetSize
        targetSize.width -= viewModel.textViewEdgeInsets.left + viewModel.textViewEdgeInsets.right

        // Height required is height it takes for the width + textview insets
        var size = textView.sizeThatFits(targetSize)
        size.height += viewModel.textViewEdgeInsets.top + viewModel.textViewEdgeInsets.bottom
        
        return size
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        selectionStyle = .none
        backgroundColor = TokenColors.Background.page
        wrap(textView, inside: contentView)
        configure(textView: textView)
    }

    private func configure(textView: UITextView) {
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.returnKeyType = .done
        textView.delegate = self
        if #available(iOS 17.0, *) {
            textView.inlinePredictionType = .no
        }
    }

    private func textColor(isPlaceholderText: Bool) -> UIColor {
        UIColor.isDesignTokenEnabled()
        ? isPlaceholderText ? TokenColors.Text.secondary : TokenColors.Text.primary
        : isPlaceholderText ? UIColor.secondaryLabel : UIColor.label
    }

    private func wrap(_ textView: UITextView, inside content: UIView) {
        textView.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(textView)

        topConstraint = contentView.topAnchor.constraint(equalTo: textView.topAnchor)
        bottomConstraint = contentView.bottomAnchor.constraint(equalTo: textView.bottomAnchor)
        leadingConstraint = contentView.leadingAnchor.constraint(equalTo: textView.leadingAnchor)
        trailingConstraint = contentView.trailingAnchor.constraint(equalTo: textView.trailingAnchor)

        topConstraint?.isActive = true
        bottomConstraint?.isActive = true
        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
    }

    private func updateInsets(_ insets: UIEdgeInsets) {
        topConstraint?.constant = -insets.top
        bottomConstraint?.constant = insets.bottom
        leadingConstraint?.constant = -insets.left
        trailingConstraint?.constant = insets.right
        layoutIfNeeded()
    }
}

extension NodeDescriptionViewCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        viewModel?.isTextViewFocused(true)
        textView.textColor = textColor(isPlaceholderText: false)

        if let description = viewModel?.description(),
           description.isPlaceholder,
           textView.text == description.text {
            textView.text = nil
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        viewModel?.isTextViewFocused(false)
        if textView.text?.isEmpty == true,
            let placeholderText = viewModel?.placeholderText {
            textView.text = placeholderText
            textView.textColor = textColor(isPlaceholderText: true)
        }
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let textViewText = textView.text ?? ""
        guard viewModel?.shouldEndEditing(for: text) == false else {
            textView.endEditing(true)
            viewModel?.saveDescription(textViewText)
            return false
        }

        guard viewModel?.shouldChangeTextIn(in: range, currentText: textViewText, replacementText: text) == true else {
            let replacementText = viewModel?.truncateAndReplaceText(in: range, of: textViewText, with: text)
            textView.text = replacementText ?? textViewText
            viewModel?.descriptionUpdated(textView.text)
            return false
        }

        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        viewModel?.descriptionUpdated(textView.text)
    }
}