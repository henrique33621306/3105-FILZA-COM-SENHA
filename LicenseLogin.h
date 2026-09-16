#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Starts the license gate and invokes the completion once per process after
/// the server has accepted the saved or newly entered key.
FOUNDATION_EXPORT void FSStartLicenseLogin(void (^authenticatedHandler)(void));

NS_ASSUME_NONNULL_END
