This is a handy little Bash script for interactively tweaking your X11 display settings using xrandr. 

It's designed to let you pick a monitor (output), choose a resolution (mode), optionally select a refresh rate, apply the change, and then confirm it - with an automatic rollback if things go wrong (like if your screen goes black or flickery).

It's safety-conscious, with sanity checks and a timeout-based revert mechanism. 

Pure Bash terminal-based tool. 

Don't forget to make it executable:
```
chmod +x ~/bin/mini-randr.sh
```

If you can add it to somwhere in PATH to make it callable anywhere.
```
mv mini-randr.sh ~/.local/bin/mini-randr
or
sudo mv mini-randr.sh /usr/local/bin/mini-randr #for all users
```


Dependencies:
 - Xorg (obviously)
 - xrandr (should be even more obviously)

It assumes you're on a Linux setup with Xorg (not Wayland).
