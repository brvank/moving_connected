extends CanvasLayer

## On-screen directional touch controls overlay.
## Houses the VirtualJoystick control for drag-to-move input.

@onready var joystick: DragJoystick = $VirtualJoystick
