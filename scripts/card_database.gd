class_name CardDatabase
extends RefCounted

const CARD_BASE_PATH := "res://assets/cards/"

const STAT_KEYS: Array[String] = ["passion", "intuition", "curiosity", "comfort"]

const CARDS: Array[Dictionary] = [
	{
		"id": 0,
		"file": "0. The Fool.webp",
		"name_en": "The Fool",
		"name_zh": "愚者",
		"upright_pips": [1, 2, 5],
		"reversed_pips": [3, 4, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "curiosity", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Passion -1, Comfort -1.",
				"mark_text_zh": "每次你接受：热-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Curiosity -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：奇-1、逸-1。"
			}
		}
	},
	{
		"id": 1,
		"file": "1. The Magician.webp",
		"name_en": "The Magician",
		"name_zh": "魔术师",
		"upright_pips": [1, 2, 3],
		"reversed_pips": [4, 5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Curiosity -1, Comfort -1.",
				"mark_text_zh": "每次你接受：奇-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Intuition -1, Passion -1.",
				"mark_text_zh": "每三次抉择：觉-1、热-1。"
			}
		}
	},
	{
		"id": 2,
		"file": "2. The Priestess.webp",
		"name_en": "The Priestess",
		"name_zh": "女祭司",
		"upright_pips": [1, 3, 5],
		"reversed_pips": [2, 4, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_refuse", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "curiosity", "delta": 1}]}
				],
				"mark_text_en": "Whenever you refuse: Intuition -1, Curiosity +1.",
				"mark_text_zh": "每次你拒绝：觉-1、奇+1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "curiosity", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Intuition -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：觉-1、逸-1。"
			}
		}
	},
	{
		"id": 3,
		"file": "3. The Empress.webp",
		"name_en": "The Empress",
		"name_zh": "皇后",
		"upright_pips": [1, 2, 3, 4],
		"reversed_pips": [5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Comfort -1, Passion -1.",
				"mark_text_zh": "每三次抉择：逸-1、热-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "curiosity", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Comfort -1, Curiosity -1.",
				"mark_text_zh": "每次你接受：逸-1、奇-1。"
			}
		}
	},
	{
		"id": 4,
		"file": "4. The Emperor.webp",
		"name_en": "The Emperor",
		"name_zh": "皇帝",
		"upright_pips": [2, 3, 4],
		"reversed_pips": [1, 5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Comfort -1, Intuition -1.",
				"mark_text_zh": "每次你接受：逸-1、觉-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Passion -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：热-1、逸-1。"
			}
		}
	},
	{
		"id": 5,
		"file": "5. The Hierophant.webp",
		"name_en": "The Hierophant",
		"name_zh": "教皇",
		"upright_pips": [1, 2, 3],
		"reversed_pips": [4, 5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "curiosity", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Intuition -1, Curiosity -1.",
				"mark_text_zh": "每次你接受：觉-1、奇-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Comfort -1, Intuition -1.",
				"mark_text_zh": "每三次抉择：逸-1、觉-1。"
			}
		}
	},
	{
		"id": 6,
		"file": "6. The Lovers.webp",
		"name_en": "The Lovers",
		"name_zh": "恋人",
		"upright_pips": [1, 2, 5],
		"reversed_pips": [3, 4, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Comfort -1, Intuition -1.",
				"mark_text_zh": "每三次抉择：逸-1、觉-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Passion -1, Comfort -1.",
				"mark_text_zh": "每次你接受：热-1、逸-1。"
			}
		}
	},
	{
		"id": 7,
		"file": "7. The Chariot.webp",
		"name_en": "The Chariot",
		"name_zh": "战车",
		"upright_pips": [1, 2, 3, 4],
		"reversed_pips": [5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Passion -1, Comfort -1.",
				"mark_text_zh": "每次你接受：热-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Passion -1, Intuition -1.",
				"mark_text_zh": "每三次抉择：热-1、觉-1。"
			}
		}
	},
	{
		"id": 8,
		"file": "8. Justice.webp",
		"name_en": "Justice",
		"name_zh": "正义",
		"upright_pips": [1, 2, 3],
		"reversed_pips": [4, 5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Intuition -1, Comfort -1.",
				"mark_text_zh": "每次你接受：觉-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Comfort -1, Passion -1.",
				"mark_text_zh": "每三次抉择：逸-1、热-1。"
			}
		}
	},
	{
		"id": 9,
		"file": "9. The Hermit.webp",
		"name_en": "The Hermit",
		"name_zh": "隐者",
		"upright_pips": [1, 3, 5],
		"reversed_pips": [2, 4, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_refuse", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you refuse: Intuition -1, Comfort -1.",
				"mark_text_zh": "每次你拒绝：觉-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Comfort -1, Passion -1.",
				"mark_text_zh": "每三次抉择：逸-1、热-1。"
			}
		}
	},
	{
		"id": 10,
		"file": "10. Wheel of Fortune.webp",
		"name_en": "Wheel of Fortune",
		"name_zh": "命运之轮",
		"upright_pips": [1, 4, 6],
		"reversed_pips": [2, 3, 5],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Curiosity -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：奇-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "curiosity", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Passion -1, Curiosity -1.",
				"mark_text_zh": "每次你接受：热-1、奇-1。"
			}
		}
	},
	{
		"id": 11,
		"file": "11. Strength.webp",
		"name_en": "Strength",
		"name_zh": "力量",
		"upright_pips": [1, 2, 3, 4],
		"reversed_pips": [5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Passion -1, Comfort -1.",
				"mark_text_zh": "每次你接受：热-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Passion -1, Intuition -1.",
				"mark_text_zh": "每三次抉择：热-1、觉-1。"
			}
		}
	},
	{
		"id": 12,
		"file": "12. The Hanged Man.webp",
		"name_en": "The Hanged Man",
		"name_zh": "倒吊人",
		"upright_pips": [2, 3, 4],
		"reversed_pips": [1, 5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_refuse", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}]}
				],
				"mark_text_en": "Whenever you refuse: Comfort -1, Intuition -1.",
				"mark_text_zh": "每次你拒绝：逸-1、觉-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Comfort -1, Passion -1.",
				"mark_text_zh": "每三次抉择：逸-1、热-1。"
			}
		}
	},
	{
		"id": 13,
		"file": "13. Death.webp",
		"name_en": "Death",
		"name_zh": "死神",
		"upright_pips": [4, 5, 6],
		"reversed_pips": [1, 2, 3],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Intuition -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：觉-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "curiosity", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Comfort -1, Curiosity -1.",
				"mark_text_zh": "每次你接受：逸-1、奇-1。"
			}
		}
	},
	{
		"id": 14,
		"file": "14. Temperance.webp",
		"name_en": "Temperance",
		"name_zh": "节制",
		"upright_pips": [1, 2, 3],
		"reversed_pips": [4, 5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Comfort -1, Passion -1.",
				"mark_text_zh": "每次你接受：逸-1、热-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Passion -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：热-1、逸-1。"
			}
		}
	},
	{
		"id": 15,
		"file": "15. The Devil.webp",
		"name_en": "The Devil",
		"name_zh": "恶魔",
		"upright_pips": [5, 6],
		"reversed_pips": [1, 2, 3, 4],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "curiosity", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Curiosity -1, Comfort -1.",
				"mark_text_zh": "每次你接受：奇-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Comfort -1, Passion -1.",
				"mark_text_zh": "每三次抉择：逸-1、热-1。"
			}
		}
	},
	{
		"id": 16,
		"file": "16. The Star.webp",
		"name_en": "The Star",
		"name_zh": "星星",
		"upright_pips": [1, 2, 3, 4],
		"reversed_pips": [5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Intuition -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：觉-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Passion -1, Comfort -1.",
				"mark_text_zh": "每次你接受：热-1、逸-1。"
			}
		}
	},
	{
		"id": 17,
		"file": "17. The Tower.webp",
		"name_en": "The Tower",
		"name_zh": "高塔",
		"upright_pips": [1],
		"reversed_pips": [2, 3, 4, 5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "curiosity", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Intuition -1, Comfort -1.",
				"mark_text_zh": "每次你接受：觉-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Passion -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：热-1、逸-1。"
			}
		}
	},
	{
		"id": 18,
		"file": "18. The Moon.webp",
		"name_en": "The Moon",
		"name_zh": "月亮",
		"upright_pips": [1, 4, 6],
		"reversed_pips": [2, 3, 5],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Intuition -1, Comfort -1.",
				"mark_text_zh": "每次你接受：觉-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "passion", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Comfort -1, Passion -1.",
				"mark_text_zh": "每三次抉择：逸-1、热-1。"
			}
		}
	},
	{
		"id": 19,
		"file": "19. The Sun.webp",
		"name_en": "The Sun",
		"name_zh": "太阳",
		"upright_pips": [1, 2, 3, 4, 5],
		"reversed_pips": [6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Passion -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：热-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Comfort -1, Intuition -1.",
				"mark_text_zh": "每次你接受：逸-1、觉-1。"
			}
		}
	},
	{
		"id": 20,
		"file": "20. Judgement.webp",
		"name_en": "Judgement",
		"name_zh": "审判",
		"upright_pips": [1, 2, 3],
		"reversed_pips": [4, 5, 6],
		"orientations": {
			"upright": {
				"accept": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "curiosity", "delta": 1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"effects": [
					{"trigger": "on_accept", "actions": [{"type": "stat", "stat": "intuition", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Whenever you accept: Intuition -1, Comfort -1.",
				"mark_text_zh": "每次你接受：觉-1、逸-1。"
			},
			"reversed": {
				"accept": [{"type": "stat", "stat": "passion", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": -1}, {"type": "stat", "stat": "intuition", "delta": -1}],
				"refuse": [{"type": "stat", "stat": "intuition", "delta": 1}, {"type": "stat", "stat": "comfort", "delta": 1}, {"type": "stat", "stat": "passion", "delta": -1}],
				"effects": [
					{"trigger": "on_3turn", "actions": [{"type": "stat", "stat": "passion", "delta": -1}, {"type": "stat", "stat": "comfort", "delta": -1}]}
				],
				"mark_text_en": "Every 3 choices: Passion -1, Comfort -1.",
				"mark_text_zh": "每三次抉择：热-1、逸-1。"
			}
		}
	},
	{
		"id": 21,
		"file": "21. The World.webp",
		"name_en": "The World",
		"name_zh": "世界",
		"upright_pips": [],
		"reversed_pips": [],
		"orientations": {
			"upright": null,
			"reversed": null
		}
	}
]


static func get_card(id: int) -> Dictionary:
	if id < 0 or id >= CARDS.size():
		return {}
	return CARDS[id]


static func texture_path(id: int) -> String:
	var card := get_card(id)
	if card.is_empty():
		return ""
	return CARD_BASE_PATH + str(card["file"])


static func card_name(id: int) -> String:
	var card := get_card(id)
	if card.is_empty():
		return "Unknown"
	return str(card["name_en"])


static func orientation_data(id: int, orientation: String) -> Dictionary:
	var card := get_card(id)
	if card.is_empty():
		return {}
	var orientations: Dictionary = card.get("orientations", {})
	return orientations.get(orientation, {})
