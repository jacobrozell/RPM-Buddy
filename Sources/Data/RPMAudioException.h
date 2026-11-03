#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Runs audio-engine work that raises NSException instead of returning an NSError.
NSString * _Nullable RPMCatchAudioException(NS_NOESCAPE void (^block)(void));

NS_ASSUME_NONNULL_END
