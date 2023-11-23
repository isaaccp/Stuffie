# Stuffie

A 3D fantasy deckbuilding roguelite!

To play:
- Download Godot 4.x
- Check out this repository somewhere in your computer
- Import the project in Godot
- Press play

Alternatively, you can just go to: https://isaaccp.itch.io/dungeoncrawler where an HTML5 version is uploaded.

## Gameplay

The game is playable for about 1-2 hours.

There are two classes: [warrior](docs/characters/warrior.md) and [wizard](
docs/characters/wizard.md).

The warrior has the most cards, including unlocking of cards based on game progress.
The wizard has a few less cards but enough to be playable. Cards are not organized in tiers yet for the wizard, so you get everything from the beginning.

There is no tutorial or similar but hopefully it's standard enough that is easy to pick up.

You have energy that is used to play cards and move points that are used to move around (2 sideways, 3 diagonal). You get previews of how much damage your cards will make and how much damage you'd get during enemy turn if you were to end your turn now.

Pressing 'Left Alt' gives you a rough view of how many enemies can attack into a certain tile (this is not 100% accurate as is possible that enemies block each other or unblock each other after they move). The damage preview should be 100% accurate.

There are a sequence of stages with battles, rests, events, blacksmith, etc. Cards can be upgraded and usually have two paths forward.

When you start the game you choose one of the classes and before reaching the boss of the first level you'll unlock the second character and will control two characters.

## Collaborate

I would love to further improve the game but there are many ways forward (more characters, more cards, better card balance, more monsters, better level design, etc) and it's hard for me to keep pushing it forward, so I think it's unlikely I'll improve further on my own.

If you have any good ideas or want to partner up to keep working on it, I am happy to pick it back up at any point and continue improving it, it's just hard to do it alone :) As of now I haven't added any license, but I am happy to make it AGPL or something.

Of course, bug reports are also welcome and I'd likely address it. 
