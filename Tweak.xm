#import "PhotoDock.h"

static void refreshPrefs() {
	NSDictionary *bundleDefaults = [[NSUserDefaults standardUserDefaults]persistentDomainForName:@"com.popsicletreehouse.photodockprefs"];
	isEnabled = [bundleDefaults objectForKey:@"isEnabled"] ? [[bundleDefaults objectForKey:@"isEnabled"]boolValue] : YES;
	dockImage = [UIImage imageWithData:[bundleDefaults valueForKey:@"dockImage"]];
	blurEnabled = [bundleDefaults objectForKey:@"isBlurEnabled"] ? [[bundleDefaults objectForKey:@"isBlurEnabled"]boolValue] : NO;
	blurIntensity = [bundleDefaults objectForKey:@"blurAlpha"] ? [[bundleDefaults objectForKey:@"blurAlpha"]floatValue] : 1.0f;
	blurType = [bundleDefaults objectForKey:@"blurType"] ? [[bundleDefaults objectForKey:@"blurType"]intValue] : 0;
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    refreshPrefs();
}

%hook SBDockView
-(void)layoutSubviews {
	%orig;
	if(isEnabled) {
		[dockImageView removeFromSuperview];
		dockImageView = [[UIImageView alloc] initWithImage:dockImage];
		[dockImageView setFrame: self.backgroundView.bounds];
		[dockImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
		[dockImageView setClipsToBounds: YES];
		dockImageView._cornerRadius = self.backgroundView._cornerRadius;
		[dockImageView setContentMode:UIViewContentModeScaleAspectFill];
		if(blurEnabled) {
			UIBlurEffect *validBlurs[3] = {[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular], [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark], [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]};
			UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:validBlurs[blurType]];
			[blurEffectView setFrame: dockImageView.bounds];
			[blurEffectView setAutoresizingMask: UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
			[blurEffectView setContentMode:UIViewContentModeCenter];
			blurEffectView.alpha = blurIntensity;
			[dockImageView addSubview: blurEffectView];
		}
		[self.backgroundView addSubview: dockImageView];
	}
}
%end

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) PreferencesChangedCallback, CFSTR("com.popsicletreehouse.photodock.prefschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	refreshPrefs();
}