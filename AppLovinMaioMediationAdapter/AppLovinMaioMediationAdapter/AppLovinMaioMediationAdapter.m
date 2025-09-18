#import "AppLovinMaioMediationAdapter.h"
#import <Maio/Maio-Swift.h>

#define ADAPTER_VERSION @"2.2.0.0.0"

@interface AppLovinMaioMediationAdapterInterstitialAdDelegate : NSObject <MaioInterstitialLoadCallback, MaioInterstitialShowCallback>
@property (nonatomic,   weak) AppLovinMaioMediationAdapter *parentAdapter;
@property (nonatomic, strong) id<MAInterstitialAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(AppLovinMaioMediationAdapter *)parentAdapter andNotify:(id<MAInterstitialAdapterDelegate>)delegate;
@end

@interface AppLovinMaioMediationAdapterRewardedAdDelegate : NSObject <MaioRewardedLoadCallback, MaioRewardedShowCallback>
@property (nonatomic,   weak) AppLovinMaioMediationAdapter *parentAdapter;
@property (nonatomic, strong) id<MARewardedAdapterDelegate> delegate;
@property (nonatomic, assign, getter=hasGrantedReward) BOOL grantedReward;
- (instancetype)initWithParentAdapter:(AppLovinMaioMediationAdapter *)parentAdapter andNotify:(id<MARewardedAdapterDelegate>)delegate;
@end

@interface AppLovinMaioMediationAdapterBannerAdDelegate : NSObject <MaioBannerDelegate>
@property (nonatomic,   weak) AppLovinMaioMediationAdapter *parentAdapter;
@property (nonatomic, strong) id<MAAdViewAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(AppLovinMaioMediationAdapter *)parentAdapter andNotify:(id<MAAdViewAdapterDelegate>)delegate;
@end

@interface AppLovinMaioMediationAdapter ()
@property (nonatomic, strong) MaioInterstitial *interstitialAd;
@property (nonatomic, strong) MaioRewarded *rewardedAd;
@property (nonatomic, strong) MaioBannerView *bannerView;

@property (nonatomic, strong) AppLovinMaioMediationAdapterInterstitialAdDelegate *interstitialAdDelegate;
@property (nonatomic, strong) AppLovinMaioMediationAdapterRewardedAdDelegate *rewardedAdDelegate;
@property (nonatomic, strong) AppLovinMaioMediationAdapterBannerAdDelegate *bannerAdDelegate;
@end

@implementation AppLovinMaioMediationAdapter

#pragma mark - MAAdapter Methods

- (void)initializeWithParameters:(id<MAAdapterInitializationParameters>)parameters
               completionHandler:(void(^)(MAAdapterInitializationStatus initializationStatus, NSString *_Nullable errorMessage))completionHandler
{
    // Maio SDK does not have an API for initialization.
    completionHandler(MAAdapterInitializationStatusDoesNotApply, nil);
}

- (NSString *)SDKVersion
{
    return [[MaioVersion shared] toString];
}

- (NSString *)adapterVersion
{
    return ADAPTER_VERSION;
}

- (void)destroy
{
    [self log: @"Destroy called for adapter %@", self];
    
    self.interstitialAd = nil;
    self.interstitialAdDelegate.delegate = nil;
    self.interstitialAdDelegate = nil;
    
    self.rewardedAd = nil;
    self.rewardedAdDelegate.delegate = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - MAInterstitialAdapter Methods

- (void)loadInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    NSString *zoneID = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading interstitial ad: %@...", zoneID];
    
    self.interstitialAdDelegate = [[AppLovinMaioMediationAdapterInterstitialAdDelegate alloc] initWithParentAdapter: self andNotify: delegate];
    MaioRequest *request = [[MaioRequest alloc] initWithZoneId: zoneID testMode: [parameters isTesting]];
    self.interstitialAd = [MaioInterstitial loadAdWithRequest: request callback: self.interstitialAdDelegate];
}

- (void)showInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    [self log: @"Showing interstitial ad %@", parameters.thirdPartyAdPlacementIdentifier];
    
    if ( self.interstitialAd )
    {
        UIViewController *presentingViewController;
        if ( ALSdk.versionCode >= 11020199 )
        {
            presentingViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
        }
        else
        {
            presentingViewController = [ALUtils topViewControllerFromKeyWindow];
        }
        
        [self.interstitialAd showWithViewContext: presentingViewController callback: self.interstitialAdDelegate];
    }
    else
    {
        [self log: @"Interstitial ad not ready"];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [delegate didFailToDisplayInterstitialAdWithError: [MAAdapterError errorWithCode: -4205
                                                                             errorString: @"Ad Display Failed"
                                                                  thirdPartySdkErrorCode: 0
                                                               thirdPartySdkErrorMessage: @"Interstitial ad not ready"]];
#pragma clang diagnostic pop
    }
}

#pragma mark - MARewardedAdapter Methods

- (void)loadRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    NSString *zoneID = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading rewarded ad: %@...", zoneID];
    
    self.rewardedAdDelegate = [[AppLovinMaioMediationAdapterRewardedAdDelegate alloc] initWithParentAdapter: self andNotify: delegate];
    MaioRequest *request = [[MaioRequest alloc] initWithZoneId: zoneID testMode: [parameters isTesting]];
    self.rewardedAd = [MaioRewarded loadAdWithRequest: request callback: self.rewardedAdDelegate];
}

- (void)showRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    [self log: @"Showing rewarded ad %@", parameters.thirdPartyAdPlacementIdentifier];
    
    if ( self.rewardedAd )
    {
        // Configure reward from server.
        [self configureRewardForParameters: parameters];
        
        UIViewController *presentingViewController;
        if ( ALSdk.versionCode >= 11020199 )
        {
            presentingViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
        }
        else
        {
            presentingViewController = [ALUtils topViewControllerFromKeyWindow];
        }
        
        [self.rewardedAd showWithViewContext: presentingViewController callback: self.rewardedAdDelegate];
    }
    else
    {
        [self log: @"Rewarded ad not ready"];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [delegate didFailToDisplayRewardedAdWithError: [MAAdapterError errorWithCode: -4205
                                                                         errorString: @"Ad Display Failed"
                                                              thirdPartySdkErrorCode: 0
                                                           thirdPartySdkErrorMessage: @"Rewarded ad not ready"]];
#pragma clang diagnostic pop
    }
}

#pragma mark - MAAdViewAdapter Methods

- (void)loadAdViewAdForParameters:(nonnull id<MAAdapterResponseParameters>)parameters adFormat:(nonnull MAAdFormat *)adFormat andNotify:(nonnull id<MAAdViewAdapterDelegate>)delegate
{
    NSString *zoneID = parameters.thirdPartyAdPlacementIdentifier;
    [self log: @"Loading banner ad: %@...", zoneID];

    self.bannerAdDelegate = [[AppLovinMaioMediationAdapterBannerAdDelegate alloc] initWithParentAdapter: self andNotify: delegate];
    self.bannerView = [[MaioBannerView alloc] initWithZoneId: zoneID size: [AppLovinMaioMediationAdapter toMaioSize: adFormat]];
    self.bannerView.delegate = self.bannerAdDelegate;
    self.bannerView.rootViewController = parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
    self.bannerView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.bannerView loadWithTestMode:[parameters isTesting] bidData:nil];
}

#pragma mark - Helper functions

+ (MAAdapterError *)toMaxError:(NSInteger)maioErrorCode
{
    // Maio's error codes are 5 digits but we need to check the first 3 digits to determine the error
    NSInteger maioError = maioErrorCode / 100;
    NSString *maioErrorMessage = @"Unknown";
    MAAdapterError *adapterError = MAAdapterError.unspecified;
    
    switch ( maioError )
    {
        case 101:
            maioErrorMessage = @"NoNetwork";
            adapterError = MAAdapterError.noConnection;
            break;
        case 102:
            maioErrorMessage = @"NetworkTimeout";
            adapterError = MAAdapterError.timeout;
            break;
        case 103:
            maioErrorMessage = @"AbortedDownload";
            adapterError = MAAdapterError.adNotReady;
            break;
        case 104:
            maioErrorMessage = @"InvalidResponse";
            adapterError = MAAdapterError.serverError;
            break;
        case 105:
            maioErrorMessage = @"ZoneNotFound";
            adapterError = MAAdapterError.invalidConfiguration;
            break;
        case 106:
            maioErrorMessage = @"UnavailableZone";
            adapterError = MAAdapterError.invalidConfiguration;
            break;
        case 107:
            maioErrorMessage = @"NoFill";
            adapterError = MAAdapterError.noFill;
            break;
        case 108:
            maioErrorMessage = @"NilArgMaioRequest";
            adapterError = MAAdapterError.badRequest;
            break;
        case 109:
            maioErrorMessage = @"DiskSpaceNotEnough";
            adapterError = MAAdapterError.internalError;
            break;
        case 110:
            maioErrorMessage = @"UnsupportedOsVer";
            adapterError = MAAdapterError.invalidConfiguration;
            break;
        case 201:
            maioErrorMessage = @"Expired";
            adapterError = MAAdapterError.adExpiredError;
            break;
        case 202:
            maioErrorMessage = @"NotReadyYet";
            adapterError = MAAdapterError.adNotReady;
            break;
        case 203:
            maioErrorMessage = @"AlreadyShown";
            adapterError = MAAdapterError.internalError;
            break;
        case 204:
            maioErrorMessage = @"FailedPlayback";
            adapterError = MAAdapterError.webViewError;
            break;
        case 205:
            maioErrorMessage = @"NilArgViewController";
            adapterError = MAAdapterError.missingViewController;
            break;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [MAAdapterError errorWithCode: adapterError.errorCode
                             errorString: adapterError.errorMessage
                  thirdPartySdkErrorCode: maioErrorCode
               thirdPartySdkErrorMessage: maioErrorMessage];
#pragma clang diagnostic pop
}

+ (MaioBannerSize *)toMaioSize:(MAAdFormat *)format
{
    if (format == MAAdFormat.banner) {
        return MaioBannerSize.banner;
    } else if (format == MAAdFormat.mrec) {
        return MaioBannerSize.mediumRectangle;
    } else {
        return nil;
    }
}

@end

@implementation AppLovinMaioMediationAdapterInterstitialAdDelegate

- (instancetype)initWithParentAdapter:(AppLovinMaioMediationAdapter *)parentAdapter andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)didLoad:(MaioInterstitial *)ad
{
    [self.parentAdapter log: @"Interstitial ad loaded: %@", ad.request.zoneId];
    [self.delegate didLoadInterstitialAd];
}

- (void)didFail:(MaioInterstitial *)ad errorCode:(NSInteger)errorCode
{
    MAAdapterError *adapterError = [AppLovinMaioMediationAdapter toMaxError: errorCode];
    
    // Maio's error code will be 1XXXX for load errors and 2XXXX for display errors.
    if ( 10000 <= errorCode && errorCode < 20000 )
    {
        // Failed to load
        [self.parentAdapter log: @"Interstitial ad failed to load with error: %@", adapterError];
        [self.delegate didFailToLoadInterstitialAdWithError: adapterError];
    }
    else if ( 20000 <= errorCode && errorCode < 30000 )
    {
        // Failed to show
        [self.parentAdapter log: @"Interstitial ad failed to display with error: %@", adapterError];
        [self.delegate didFailToDisplayInterstitialAdWithError: adapterError];
    }
    else
    {
        // Unknown error code
        [self.parentAdapter log: @"Interstitial ad failed to load or show due to an unknown error: %@", adapterError];
        [self.delegate didFailToLoadInterstitialAdWithError: adapterError];
    }
}

- (void)didOpen:(MaioInterstitial *)ad
{
    [self.parentAdapter log: @"Interstitial ad shown: %@", ad.request.zoneId];
    [self.delegate didDisplayInterstitialAd];
}

- (void)didClick:(MaioInterstitial *)ad
{
    // NOTE: Maio click callbacks are only fired on the first click for clickable ads.
    [self.parentAdapter log: @"Interstitial ad clicked: %@", ad.request.zoneId];
    [self.delegate didClickInterstitialAd];
}

- (void)didClose:(MaioInterstitial *)ad
{
    [self.parentAdapter log: @"Interstitial ad hidden: %@", ad.request.zoneId];
    [self.delegate didHideInterstitialAd];
}

@end

@implementation AppLovinMaioMediationAdapterRewardedAdDelegate

- (instancetype)initWithParentAdapter:(AppLovinMaioMediationAdapter *)parentAdapter andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)didLoad:(MaioRewarded *)ad
{
    [self.parentAdapter log: @"Rewarded ad loaded: %@", ad.request.zoneId];
    [self.delegate didLoadRewardedAd];
}

- (void)didFail:(MaioRewarded *)ad errorCode:(NSInteger)errorCode
{
    MAAdapterError *adapterError = [AppLovinMaioMediationAdapter toMaxError: errorCode];
    
    // Maio's error code will be 1XXXX for load errors and 2XXXX for display errors.
    if ( 10000 <= errorCode && errorCode < 20000 )
    {
        // Failed to load
        [self.parentAdapter log: @"Rewarded ad failed to load with error: %@", adapterError];
        [self.delegate didFailToLoadRewardedAdWithError: adapterError];
    }
    else if ( 20000 <= errorCode && errorCode < 30000 )
    {
        // Failed to show
        [self.parentAdapter log: @"Rewarded ad failed to display with error: %@", adapterError];
        [self.delegate didFailToDisplayRewardedAdWithError: adapterError];
    }
    else
    {
        // Unknown error code
        [self.parentAdapter log: @"Rewarded ad failed to load or show due to an unknown error: %@", adapterError];
        [self.delegate didFailToLoadRewardedAdWithError: adapterError];
    }
}

- (void)didOpen:(MaioRewarded *)ad
{
    [self.parentAdapter log: @"Rewarded ad shown: %@", ad.request.zoneId];
    [self.delegate didDisplayRewardedAd];
}

- (void)didClick:(MaioRewarded *)ad
{
    // NOTE: Maio click callbacks are only fired on the first click for clickable ads.
    [self.parentAdapter log: @"Rewarded ad clicked: %@", ad.request.zoneId];
    [self.delegate didClickRewardedAd];
}

- (void)didReward:(MaioRewarded *)ad reward:(RewardData *)reward
{
    [self.parentAdapter log: @"User earned reward: %@", reward.value];
    self.grantedReward = YES;
}

- (void)didClose:(MaioRewarded *)ad
{
    if ( [self hasGrantedReward] || [self.parentAdapter shouldAlwaysRewardUser] )
    {
        MAReward *reward = [self.parentAdapter reward];
        [self.parentAdapter log: @"Rewarded user with reward: %@", reward];
        [self.delegate didRewardUserWithReward: reward];
    }
    
    [self.parentAdapter log: @"Rewarded ad hidden: %@", ad.request.zoneId];
    [self.delegate didHideRewardedAd];
}

@end

@implementation AppLovinMaioMediationAdapterBannerAdDelegate

- (instancetype)initWithParentAdapter:(AppLovinMaioMediationAdapter *)parentAdapter andNotify:(id<MAAdViewAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)didLoad:(MaioBannerView *)ad
{
    [self.parentAdapter log: @"Banner ad loaded: %@", ad.zoneId];
    [self.delegate didLoadAdForAdView:ad];
}

- (void)didFailToLoad:(MaioBannerView *)ad errorCode:(NSInteger)errorCode
{
    [self.parentAdapter log: @"Banner ad failed to load with error: %@", errorCode];
    [self.delegate didFailToLoadAdViewAdWithError:[AppLovinMaioMediationAdapter toMaxError:errorCode]];
}

- (void)didMakeImpression:(MaioBannerView *)ad
{
    [self.parentAdapter log: @"Banner ad shown: %@", ad.zoneId];
    [self.delegate didDisplayAdViewAd];
}

- (void)didClick:(MaioBannerView *)ad
{
    [self.parentAdapter log: @"Banner ad clicked: %@", ad.zoneId];
    [self.delegate didClickAdViewAd];
}

- (void)didLeaveApplication:(MaioBannerView *)ad
{
    [self.parentAdapter log: @"Banner ad hidden: %@", ad.zoneId];
    [self.delegate didHideAdViewAd];
}

- (void)didFailToShow:(MaioBannerView *)ad errorCode:(NSInteger)errorCode
{
    [self.parentAdapter log: @"Banner ad failed to show with error: %@", errorCode];
    [self.delegate didFailToDisplayAdViewAdWithError:[AppLovinMaioMediationAdapter toMaxError:errorCode]];
}

@end
