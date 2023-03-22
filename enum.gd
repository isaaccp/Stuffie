extends Object

class_name Enum

enum CharacterId {
	NO_CHARACTER,
	WARRIOR,
	WIZARD,
}

enum EnemyId {
	SKELETON_WARRIOR,
	SKELETON_ARCHER,
	SKELETON_MAGE,
}

enum StatsLevel {
	OVERALL,
	GAME_RUN,
	STAGE,
	TURN,
	MAX,
}

enum TargetMode {
	# Targets self.
	SELF,
	# Targets ally.
	ALLY,
	# Targets self or ally.
	SELF_ALLY,
	# Needs to target an enemy.
	ENEMY,
	# Can target any location within range.
	AREA,
}

# Animation to play on target tiles when cast.
enum TargetAnimationType {
	NO_ANIMATION,
	SLASH,
	PROJECTILE,
	BUFF,
	DEBUFF,
	FIRE,
	ARCANE,
}
