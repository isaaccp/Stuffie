extends Resource

class_name CardEffectMetadata

# Used in DUPLICATE_CARD to modify original card.
@export var original_card_change: CardChange
# Used in DUPLICATE_CARD to modify copied card.
@export var copied_card_change: CardChange
# Used in DUPLICATE_CARD to filter selection.
# TODO: Remove the *_ATTACKS cards and replace them by use of filter.
@export var card_filter: CardFilter

func card_filter_condition():
	if card_filter:
		return card_filter.condition()
	return func(c: Card): return true

func card_filter_description():
	if card_filter:
		return card_filter.get_description()
	return "cards"
