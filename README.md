# gsom_pawns

The aim of this addon is to provide a framework for characters with various
movement styles. This addon does NOT handle user input, but it provides an easy
way to relay your (or AI) input to pawns.

The concept of a Pawn is derived from **Unreal Engine**
[where](https://dev.epicgames.com/documentation/en-us/unreal-engine/pawn-in-unreal-engine):

> A Pawn is the physical representation of a player or AI entity within the world. [...]
    represents the physical location, rotation, etc. of a player or entity within the game.

Here the idea is the same, although the implementation is very different - the Godot-way.


## GsomPawn

This node is the key part of the framework. It expects
to be a child of `Node3D` - your character, that you are going to script later.
For this `GsomPawn` node, you have to choose a `scene` that represents its body.
The `scene` must be a `PackedScene`, where root is a `Node3D`. Any descendant of `Node3D`
is fine, and can **optionally** have `linear_velocity` and
`angular_velocity` properties (as physics nodes would).

Example structure:

```gdscript
MainScene
|---Controller # not a child of pawn or character
|   |---Camera # <-- the actual camera is inside controller
|   |---Hud
|   |---EscMenu
|
|---Character # <-- this is yours, attach a script here
    |---GsomPawn # <-- this is the GsomPawn node
    |   |   [GsomPawn.scene] # <-- your scene defines the body
    |   |---PawnHandler1
    |   |---PawnHandler2
    |   |---PawnHandler3 # <-- these extend GsomPawnHandler
    |   
    |---Mesh # anything else that you need for a character
    |---AudioStep
```

