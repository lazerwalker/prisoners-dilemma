# Prisoner's Dilemma Example

This is a very simple iterated [prisoner's dilemma](https://en.wikipedia.org/wiki/Prisoner%27s_dilemma) game for two players, each playing on their own iOS device.

It is meant to demonstrate how to use Apple's Multipeer Connectivity framework, and accompanies [this blog post](http://blog.lazerwalker.com/blog/2014/09/03/making-multiplayer-ios-games-with-apple-multipeer-connectivity/).

## Try it out!

1. Clone this repo. 
2. Open the `.xcworkspace` file. 
3. Run on two physical devices (the simulator often exhibits unexpeced behavior with the multipeer conectivity framework).


## Check out the code!
For the sake of making this example easier to follow along with, all game logic and non-boilerplate code is encapsulated in a single [view controller](https://github.com/lazerwalker/prisoners-dilemma/blob/master/Prisoners%20Dilemma/ViewController.m). The `Main.storyboard` file contains the layout of the game's single view, but all other logic lives in that file.

## Dependencies
This project uses [ReactiveCocoa](http://reactivecocoa.io). It's been set up via [CocoaPods](https://cocoapods.org), but because the Pods folder is versioned you shouldn't need to worry about that other than needing to open the game's workspace file rather than its project file in Xcode.


## License
MIT License. See the LICENSE file in this repo for details.
