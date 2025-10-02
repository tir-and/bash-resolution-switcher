This is a handy little Bash script for interactively tweaking your X11 display settings using xrandr. 

It's designed to let you pick a monitor (output), choose a resolution (mode), optionally select a refresh rate, apply the change, and then confirm it - with an automatic rollback if things go wrong (like if your screen goes black or flickery).

It's safety-conscious, with sanity checks and a timeout-based revert mechanism. 

Pure Bash terminal-based tool. 

Dependencies:
 - Xorg (obviously)
 - xrandr (should be even more obviously)

It assumes you're on a Linux setup with Xorg (not Wayland).
