#Tower Stacking Game

This project is a physics based tower stacking game built in Processing using the Box2D for Processing library.  
The player drops blocks from a moving crane and tries to stack them as high and as stable as possible to reach the target height.

#Features
- Realistic physics using the Box2D engine  
- Moving crane with automated trolley system  
- Animated blocks with shadows and wood texture  
- Gradual difficulty increase each level (higher targets and more blocks)  
- Countdown timer to check for tower stability
- Simple particle effects when blocks are dropped  
- Game Over and Level Complete states with UI overlays

#How to Run
1. Open Tower_Final_version.pde in the Processing IDE.  
2. Make sure the Shiffman Box2D library is installed:
   - Go to Sketch -> Import Library -> Manager Libraries
   - Search for “Box2D for Processing” and install it.  
3. Press the Run button to start the game.  

#Controls
- Mouse Click: Drops a block from the crane  
- Keep stacking blocks to reach or exceed the target height  
- If the tower remains stable for a few seconds, you win the level. 
- If blocks fall off or you run out of blocks, then its game over.

#Goal
- Reach the red target line shown on the screen.  
- Maintain tower stability above this line for the countdown duration.  
- Each level becomes slightly harder with more blocks and higher targets.

#Example Output Screenshots 

<img width="734" height="736" alt="image" src="https://github.com/user-attachments/assets/a36fd7ba-03d0-433a-bf41-ca9db28db2a4" />

When the game is first run. 

<img width="743" height="735" alt="image" src="https://github.com/user-attachments/assets/7b461be8-c243-4d62-be1d-5c7f8a439764" />

Boxes are dropped with a button click. Height of boxes, and number of boxes left is displayed on the top left. 

<img width="733" height="735" alt="image" src="https://github.com/user-attachments/assets/ad5eb556-37e6-420a-a57a-120066618d0e" />

After target height is reached, a countdown starts to check for stability. 

<img width="740" height="732" alt="image" src="https://github.com/user-attachments/assets/7a0ce390-dbc4-45a0-82b9-ae45ec8c0f56" />

Once countdown is complete we can move onto the next level. 

<img width="738" height="743" alt="image" src="https://github.com/user-attachments/assets/12aca82e-363e-4d1d-9d1b-f3db8f28987b" />

If target cannot be reached, the game is over and must be restarted. 





