# schalkje – custom oh-my-posh theme

Tokyo-night style powerline prompt: OS, user, path, git (colour changes with state), right side with execution time / node / python / clock, and a `❯` on line two that turns red after a failed command.

## Try it
```powershell
omp-list schalkje -Preview   # preview
omp-set schalkje             # apply (picked up automatically by the switcher)
```

## Tweak it
Each entry in `segments` is one block. Change `background`/`foreground` (hex), `template` (what text shows), or add segments from https://ohmyposh.dev/docs/configuration/segment. Edit, re-run the preview, repeat.


## Prompt description

Create 3 variations and take the input below into account:

- schalkje
- schalkje-lean
- schalkje-full

Each of these themes get's their own folder; 

On the themes folder, create a readme with instructions, possibilities and resources that you use creating the themes, like:
- https://ohmyposh.dev/docs/configuration/segment
- https://ohmyposh.dev/docs/configuration/colors
- https://ohmyposh.dev/docs/configuration/block
etc

Each of the themes have a readme, describing how the theme is build, so we can tweak the readme, to regenerate the theme


### Elements
- cpu usage
- memory x/yGB
- current time
- duration
- identification of elevated like in in Powerlevel10k_rainbow

- git folder

### Layout
The prompt can be multiline

I really like the feel of wholespace;
- the fact that the prompt changes after send if nice; but I want the usefull information to stick around; e.g. the folder can go; but time, duration, cpu, mem, branch should stick around 
- I like the blocks with the separators
- I do not like the long folder with the heart at the end, I rather have an extra line with >

The place where I start typing is close to the left side, like with lambdageneration and Powerlevel10k_rainbow

I likethe color scheme from lambdageneration, but need you creativity to fit this in with the blocks and colors of wholespace


