# Rendering

## Desired effects
- Parallax background and foreground
- Multiple cameras
- Palette-based animation
- Sprite-based animation
- Palette-swapped sprites
- Zoomable camera
- Post-processing effects
	- Noise overlay
- Screen transitions
	- Wipe left / right
	- Fade in /  out

## Architecture
- Render layers:
	- 1: bg, 2: normal, 3: fg
- Sprites all have layers assigned for parallax tracking
- Cameras are added to a cameras array in render order
- Renderable game objects have a render() function and a position
	- Standard render function takes sprite and (optional) palette
- Animators are used to set current sprite and palette on renderable game objects
- Renderer global has function pointers to sprite and map-rendering
	- Allows custom sprite- and map-drawing functions to facilitate camera zoom
- Post-processing effects are game-objects that have a post_render() function
- Screen transitions can be post-processing effects
- Camera tracks object within certain bounds.

## Pipeline
- Takes place in Renderer.render()
	- Collect all renderables in an array
	- Y-sort all renderables
	- For each camera
		- For each parallax layer (in back-to-front order)
			- Calculate the parallax-adjusted shoot position based on the camera shoot position
			- If zoom, use custom sprite- and map-drawing functions
			- Render the map with the only the layer-appropriate sprites
			- Render all layer sprites in the render array
	- Collect all post-processing effects in an array
		- Call each post-processing effect in order
