# PZSmashAndGrab
Does stealth bore you? Do you want to smash windows, loot houses, and run away before the undead owners ever find out? This mod is for you! Press 'R' to smash windows, climb sheet ropes, clear glass, and open curtains. Adds the ability to mark items as junk and then use a quick loot button to steal all non-junk items quickly. Also makes looting items provide a very slight amount of experience towards nimbleness. Nimbleness now improves the rate at which you clean glass and quick loot items!

# Installation instructions
Download the repository
Copy SmashAndGrab to '~/Zomboid/mods'  (OsX) or 'C:\Users\YOURUSERNAME\Zomboid\mods' (Windows)

# Functionality
This mod provides the following features

- Adds the ability to mark loot and use a quick loot button to grab unmarked loot
- Generates save files for marked loot (currently does not delete these) so they persist between game loads
- Adds a hotkey ('r') to smash windows, clean glass, add sheets, add sheet ropes, close curtains, climb through windows and climb sheet ropes
- Adds nimbleness XP to transfering items and cleaning broken glass (So you get better at stealing as you practice it)
- Removes the 'WalkTo' option because I HATE HITTING WALK TO WHEN I TRY TO HIT A ZOMBIE

# For modders
The code is mostly self explanatory. Use the SmashAndGrabCustomEvent.addListener(functionName) to create listeners for any function
e.g. 
```
SmashAndGrabCustomEvent.addListener("LoadGameScreen:clickPlay")
```

Then create a function (no methods, so the self parameter must be explicit) to be called during when an event is fired. e.g.
```
printMe = function(self) 
    print (self.text)
end
```

Then add a listener to a pre or post event by calling the respective manager e.g.
```
Events.preLoadGameScreen_clickPlay.Add(printMe)
Events.postLoadGameScreen_clickPlay.Add(printMe)
```

# See Code to Learn
- How to add persist mod changes and data for save files between loads/continue
- How to attach events to arbitrary lua functions
- How to detect cells around a player

# Credit

- Project Zomboid team 
- RoboMat for his tutorials
- http://www.inmyshortsleeve.com/2012/03/22/jiberish-abstractmall-smash-and-grab/ for their artwork 

