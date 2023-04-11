extends Resource

class_name CardEffectMetadata

# Used in DUPLICATE_CARD to modify original card.
@export var original_card_change: CardChange
# Used in DUPLICATE_CARD to modify copied card.
@export var copied_card_change: CardChange
# Used in DUPLICATE_CARD to filter selection.
@export var card_filter: CardFilter
# Used in ADD_CARD.
@export var card: Card
# Used in ADD_RELIC.
@export var relic: Relic

func card_filter_description():
	if card_filter:
		return card_filter.get_description()
	return "cards"
