#Tower Stacking Game

This project is a physics based tower stacking game built in Processing using the Box2D for Processing library.
The player drops blocks from a moving crane and tries to stack them as high and as stable as possible to reach the target height.

#Features

Realistic physics using the Box2D engine
Moving crane with automated trolley system
Animated blocks with shadows and wood texture
Gradual difficulty increase each level (higher targets and more blocks)
Countdown timer to check for tower stability
Simple particle effects when blocks are dropped
Game Over and Level Complete states with UI overlays
#How to Run

Open Tower_Final_version.pde in the Processing IDE.
Make sure the Shiffman Box2D library is installed:
Go to Sketch -> Import Library -> Manager Libraries
Search for “Box2D for Processing” and install it.
Press the Run button to start the game.
#Controls

Mouse Click: Drops a block from the crane
Keep stacking blocks to reach or exceed the target height
If the tower remains stable for a few seconds, you win the level.
If blocks fall off or you run out of blocks, then its game over.
#Goal

Reach the red target line shown on the screen.
Maintain tower stability above this line for the countdown duration.
Each level becomes slightly harder with more blocks and higher targets.
#Example Output Screenshots

image
When the game is first run.

image
Boxes are dropped with a button click. Height of boxes, and number of boxes left is displayed on the top left.

image
After target height is reached, a countdown starts to check for stability.

image
Once countdown is complete we can move onto the next level.

image
If target cannot be reached, the game is over and must be restarted.
