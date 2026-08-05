# SF2-Camera-Overlay

 This gives the ability to enable a custom camera overlay for specific bosses in Slender Fortress 2.



# Requirements
1. CBaseNPC : https://github.com/TF2-DMB/CBaseNPC
2. Slender Fortress Modified 1.8.0 (https://github.com/Mentrillum/Slender-Fortress-Modified-Versions/tree/1-8-0-rewrite)
 
   Note: This has also been tested on an earlier version (1.7.5)

# Video example:

Link : https://www.youtube.com/watch?v=Gb0G-3kY0sw


# How to use:

1. Place in your /scripting/ folder
2. Compile
3. Place in /plugins/
4. Add "camera_overlay" "materials/example/example.vtf" in ANY boss .cfg (SEE BELOW FOR MORE INFO)


# Below is a Example of any random boss cfg.
 * =========================================================================
 *   FILE :   Scream.cfg
 * =========================================================================

 * 		"name" "Scream"
 * 		"type" "2"
 * 		"speed" "1000"
 * 		"model" "models/slender/bosses/scream/scream.mdl"
  		
 *      "camera_overlay"    "materials/slender/overlays/example.vtf"
 
 
 Remember that the material needs downloading, and you need to list it in the profile's existing "mat_download"/"download" section.

 NOTE: Incase two bosses spawn with "camera_overlay" in their cfg file then this plugin will choose the first boss only.
