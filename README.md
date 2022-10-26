# random_dungeon_generator
a random dungeon map generator written in x86_64 assembly

Originally written as a final project for an assembly language class in spring of 2022.
The final project was extremly freeform in the sense that it was to write whatver you want of suficient complexity
thus I see no issue with this repository being visible as any attempts to misuse if would be immedietly obvious.

Notes:
  - was originally intended to have paths between the rooms, this was not finished before the deadline but there is some hints of it within the comments
    - I may or may not come back and finish this feature just for fun... depends on what other projects I am working on
  - the implimentation of the random number generator does not appear to randomize the upper half of its space properly, this was never a problem however 
    as the values that were needed were not big enough to require a full 64 bit integer. I imagine this is likely do to me basing it on the original
    mersenne twister paper from 1998 which likely would have been using 32 bit values. As I am not skilled enough in the math required as of yet, I cannot
    make the changes needed to correct for this without risking messing up the random numbers, nor can I verify that this is the actual issue.
