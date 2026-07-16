extends Resource

class_name DiceFace

@export var face_name: String = "Face"
@export var result_type: String = "miss"
@export var value: int = 0
@export var label: String = ""
@export var icon: Texture2D

func get_display_name() -> String:
	match result_type:
		"hit":
			return "Hit " + str(value)

		"crit":
			return "Critical " + str(value)

		"block":
			return "Block " + str(value)

		"heal":
			return "Heal " + str(value)

		"gold":
			return "Gold " + str(value)

		"bleed":
			return "Bleed " + str(value)

		"freeze":
			return "Freeze " + str(value)

		"vitality":
			return "Vitality " + str(value)

		"miss":
			return "Miss"

		"dodge":
			return "Dodge"

		"reversal":
			return "Reversal"

		"twist_knife":
			return "Twist Knife"

		"break_focus":
			return "Break Focus"

		"shield_bash":
			return "Shield Bash"

		"pain":
			return "Pain " + str(value)

		"fireball":
			return "Fireball"

		_:
			if !face_name.is_empty():
				return face_name

			return result_type.capitalize()


func get_tooltip(die_data: DiceData = null) -> String:
	var text: String = get_display_name()

	match result_type:
		"hit":
			text += (
				"\nDeals "
				+ str(value)
				+ " damage. Block reduces this damage."
			)

		"crit":
			text += (
				"\nDeals "
				+ str(value)
				+ " damage that ignores Block."
				+ "\nApplies Exposed."
			)

		"block":
			text += (
				"\nGain "
				+ str(value)
				+ " Block."
			)

		"heal":
			text += (
				"\nRestore "
				+ str(value)
				+ " HP."
			)

		"gold":
			text += (
				"\nGain "
				+ str(value)
				+ " Gold."
			)

		"miss":
			text += (
				"\nDoes nothing when rolled."
				+ "\nIncreases Fireball damage on this die."
			)
			

		"bleed":
			text += (
				"\nApply "
				+ str(value)
				+ " Bleed."
				+ "\nBleed deals damage at the end of the round."
				+ "\nBlock can prevent Bleed damage."
			)

		"freeze":
			text += (
				"\nApply "
				+ str(value)
				+ " Freeze."
				+ "\nThe target skips its turn when Freeze is applied."
				+ "\nFrozen enemies can Shatter."
			)

		"dodge":
			text += (
				"\nThe chosen enemy's Critical damage misses."
			)

		"reversal":
			text += (
				"\nReflects the chosen enemy's Critical damage "
				+ "back at that enemy."
			)

		"twist_knife":
			text += (
				"\nConsumes the target's Bleed and immediately "
				+ "deals that much damage."
			)

		"break_focus":
			text += (
				"\nCancels the chosen enemy's healing this turn."
			)

		"vitality":
			text += (
				"\nPermanently increases Max HP by "
				+ str(value)
				+ " and restores the same amount of HP."
			)

		"shield_bash":
			text += (
				"\nDeals damage equal to your current Block."
				+ "\nThen keep half of your Block, rounded up."
			)

		"pain":
			text += (
				"\nDeals "
				+ str(value)
				+ " damage to the player."
			)

		"fireball":
			var miss_count: int = 0

			if die_data != null:
				for die_face in die_data.faces:
					if (
						die_face != null
						and die_face.result_type == "miss"
					):
						miss_count += 1

			text += (
				"\nDeals 1 damage for each Miss face on this die."
			)

			if die_data != null:
				text += (
					"\nCurrent damage: "
						+ str(miss_count)
						+ "."
				)

		_:
			pass

	return text
