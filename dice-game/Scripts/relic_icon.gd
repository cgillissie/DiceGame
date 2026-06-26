extends TextureRect

func setup(relic: RelicData):
	texture = relic.icon
	tooltip_text = relic.relic_name + "\n" + relic.description
