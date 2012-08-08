# iFuga


iOS component for displaying a fullscreen image gallery
Supports orientation changes

## Installation
iFuga is available via cocoapods. If you're not familiar with it, see [here](https://github.com/CocoaPods/CocoaPods).
Once you have cocoapods installed and ready, add to your project's `Podfile` following line
``` ruby
pod 'iFuga', '~>1.1'
```
For more options in Podfile, please see official [documentation](https://github.com/CocoaPods/CocoaPods/wiki/A-Podfile).

## Usage
To be able to show a fullscreen presentation of image from inside your viewController you 
should have an instance of `FGController`. Creating an instance is pretty straightforward:
``` objective-c
_fgController = [[FGController alloc] initWithDelegate:self];
```
Next, in an method catching user's action or whereever you want to show a fullscreen image, call either
``` objective-c
[_fgController showImage:desiredImage];
```
or
``` objective-c
[_fgController showImage:desiredImage fromThumbnail:self.imageView];
```
By default, iFuga supports all interface orientations regardless whether calling viewController suports them or not.
To restrict iFuga to turn to certain orientation, implement it's delegate method `canRotateToInterfaceOrientation:` as desired,
for example:
``` objective-c
-(BOOL)canRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}
```
## Contact
iFuga was created by [@gavrix](http://twitter.com/gavrix).<br/>
Also, please drop by my [blog](http://gavrix.wordpress.com)

## License
iFuga is available under the MIT license. See LICENSE for more info.


