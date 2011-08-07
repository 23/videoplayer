The Gemius branch is not a stand-alone player, but is designed to be used for tracking with the Gemius Flash framework (the framework itself is not distributed with the branch, and must be obtained from Gemius). 

To use the change set with a given player, follow these instructions after cloning the the git repository.

Check out of the branch you want to work with Gemius:

    git checkout master
    git checkout squares
    git checkout anglic
    git checkout ...

Merge in the change set from the `gemius` branch:
  
    git merge gemius

Download and place `gSmAS3.swc` from the Gemius Flash framework in the `./libs` folder.