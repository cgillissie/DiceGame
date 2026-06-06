extends Button
class_name BountyButton

@onready var bounty_label: Label = $BountyLabel

var bounty_data: BountyData

func setup(bounty: BountyData):
	bounty_data = bounty
	text = ""
	bounty_label.text = bounty.bounty_name + "\n" + bounty.description
