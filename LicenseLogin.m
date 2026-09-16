@import UIKit;
@import Security;

#import "LicenseLogin.h"

static NSString *const FSAPIBaseURL = @"https://licenseshop-he9jxzob.manus.space";
static NSString *const FSValidationPath = @"/api/v1/licenses/validate";
static NSString *const FSKeychainService = @"com.yangjiii.3105.license";
static NSString *const FSPurchaseURL = @"https://chat.whatsapp.com/EBQf7teedZJCgRTNztqEv4?s=cl&p=i&mlu=4&ilr=4";

static NSData *FSKeychainRead(void) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: FSKeychainService,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    return status == errSecSuccess ? CFBridgingRelease(result) : nil;
}

static BOOL FSKeychainSave(NSString *key) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: FSKeychainService
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
    NSMutableDictionary *item = query.mutableCopy;
    item[(__bridge id)kSecValueData] = [key dataUsingEncoding:NSUTF8StringEncoding];
    item[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    return SecItemAdd((__bridge CFDictionaryRef)item, NULL) == errSecSuccess;
}

static void FSKeychainDelete(void) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: FSKeychainService
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

static UIWindow *FSActiveWindow(void) {
    for (UIWindow *window in UIApplication.sharedApplication.windows)
        if (window.isKeyWindow) return window;
    for (UIWindow *window in UIApplication.sharedApplication.windows)
        if (!window.hidden) return window;
    return nil;
}

@interface FSLicenseLoginViewController : UIViewController <UITextFieldDelegate>
@property(nonatomic, strong) UITextField *keyField;
@property(nonatomic, strong) UIButton *loginButton;
@property(nonatomic, strong) UIActivityIndicatorView *spinner;
@property(nonatomic, strong) UILabel *errorLabel;
@property(nonatomic, copy) void (^authenticatedHandler)(void);
@property(nonatomic) BOOL checking;
@end

@implementation FSLicenseLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];

    UIView *content = [UIView new];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 22;
    stack.alignment = UIStackViewAlignmentFill;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:stack];

    UIView *header = [self headerView];
    UIView *panel = [self loginPanel];
    UIView *verse = [self verseView];
    UILabel *privacy = [self label:@"🔒\nSua licença é validada neste dispositivo. A chave é armazenada no Keychain e nunca é exibida novamente."
                                  size:12 weight:UIFontWeightRegular color:UIColor.secondaryLabelColor];
    privacy.numberOfLines = 0;
    privacy.textAlignment = NSTextAlignmentCenter;

    [stack addArrangedSubview:header];
    [stack addArrangedSubview:panel];
    [stack addArrangedSubview:verse];
    [stack addArrangedSubview:privacy];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor],
        [content.heightAnchor constraintGreaterThanOrEqualToAnchor:scroll.frameLayoutGuide.heightAnchor],
        [stack.topAnchor constraintEqualToAnchor:content.topAnchor constant:30],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:content.leadingAnchor constant:22],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:content.trailingAnchor constant:-22],
        [stack.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [stack.widthAnchor constraintLessThanOrEqualToConstant:470],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:content.bottomAnchor constant:-30]
    ]];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 350 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self.keyField becomeFirstResponder];
    });
}

- (UIView *)headerView {
    UIStackView *header = [[UIStackView alloc] init];
    header.axis = UILayoutConstraintAxisVertical;
    header.spacing = 9;
    header.alignment = UIStackViewAlignmentCenter;

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]];
    icon.tintColor = UIColor.systemBlueColor;
    icon.contentMode = UIViewContentModeCenter;
    icon.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.12];
    icon.layer.cornerRadius = 18;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [icon.widthAnchor constraintEqualToConstant:58], [icon.heightAnchor constraintEqualToConstant:58]
    ]];

    UILabel *title = [self label:@"Bem-vindo à Ayam Store" size:28 weight:UIFontWeightBold color:UIColor.labelColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.numberOfLines = 0;
    UILabel *subtitle = [self label:@"Dono da loja  ·  Criador: Jesus Cristo" size:13 weight:UIFontWeightMedium color:UIColor.secondaryLabelColor];
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.numberOfLines = 0;
    [header addArrangedSubview:icon];
    [header addArrangedSubview:title];
    [header addArrangedSubview:subtitle];
    return header;
}

- (UIView *)loginPanel {
    UIView *panel = [UIView new];
    panel.backgroundColor = UIColor.systemBackgroundColor;
    panel.layer.cornerRadius = 23;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = [UIColor.separatorColor colorWithAlphaComponent:0.35].CGColor;
    panel.layer.shadowColor = UIColor.blackColor.CGColor;
    panel.layer.shadowOpacity = 0.06;
    panel.layer.shadowRadius = 16;
    panel.layer.shadowOffset = CGSizeMake(0, 7);

    UIStackView *box = [[UIStackView alloc] init];
    box.axis = UILayoutConstraintAxisVertical;
    box.spacing = 12;
    box.translatesAutoresizingMaskIntoConstraints = NO;
    [panel addSubview:box];

    UILabel *heading = [self label:@"Acesso exclusivo" size:20 weight:UIFontWeightBold color:UIColor.labelColor];
    UILabel *hint = [self label:@"Insira sua chave para continuar" size:15 weight:UIFontWeightRegular color:UIColor.secondaryLabelColor];
    UILabel *fieldLabel = [self label:@"CHAVE DE LICENÇA" size:12 weight:UIFontWeightBold color:UIColor.secondaryLabelColor];

    self.keyField = [UITextField new];
    self.keyField.placeholder = @"Digite sua chave";
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.returnKeyType = UIReturnKeyGo;
    self.keyField.delegate = self;
    self.keyField.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    self.keyField.layer.cornerRadius = 15;
    self.keyField.layer.borderWidth = 1;
    self.keyField.layer.borderColor = [UIColor.separatorColor colorWithAlphaComponent:0.45].CGColor;
    self.keyField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.keyField.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *left = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 52)];
    UIImageView *keyIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.horizontal.fill"]];
    keyIcon.tintColor = UIColor.systemBlueColor;
    keyIcon.frame = CGRectMake(14, 17, 18, 18);
    [left addSubview:keyIcon];
    self.keyField.leftView = left;
    self.keyField.leftViewMode = UITextFieldViewModeAlways;
    [self.keyField.heightAnchor constraintEqualToConstant:52].active = YES;

    self.errorLabel = [self label:@"" size:13 weight:UIFontWeightMedium color:UIColor.systemRedColor];
    self.errorLabel.numberOfLines = 0;
    self.errorLabel.hidden = YES;

    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loginButton setTitle:@"Entrar" forState:UIControlStateNormal];
    [self.loginButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    self.loginButton.backgroundColor = UIColor.systemBlueColor;
    self.loginButton.layer.cornerRadius = 15;
    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loginButton.heightAnchor constraintEqualToConstant:52].active = YES;
    [self.loginButton addTarget:self action:@selector(validateEnteredKey) forControlEvents:UIControlEventTouchUpInside];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.color = UIColor.whiteColor;

    UIButton *purchase = [UIButton buttonWithType:UIButtonTypeSystem];
    [purchase setTitle:@"🛒  Comprar acesso                                      ↗" forState:UIControlStateNormal];
    purchase.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    purchase.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    purchase.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.08];
    purchase.layer.cornerRadius = 14;
    purchase.layer.borderWidth = 1;
    purchase.layer.borderColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.22].CGColor;
    purchase.translatesAutoresizingMaskIntoConstraints = NO;
    [purchase.heightAnchor constraintEqualToConstant:46].active = YES;
    [purchase addTarget:self action:@selector(openPurchase) forControlEvents:UIControlEventTouchUpInside];

    for (UIView *view in @[heading, hint, fieldLabel, self.keyField, self.errorLabel, self.loginButton, purchase])
        [box addArrangedSubview:view];
    [box setCustomSpacing:4 afterView:heading];
    [box setCustomSpacing:16 afterView:hint];
    [box setCustomSpacing:8 afterView:fieldLabel];
    [box setCustomSpacing:16 afterView:self.keyField];
    [box setCustomSpacing:16 afterView:self.loginButton];

    [NSLayoutConstraint activateConstraints:@[
        [box.topAnchor constraintEqualToAnchor:panel.topAnchor constant:20],
        [box.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:20],
        [box.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-20],
        [box.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-20]
    ]];
    return panel;
}

- (UIView *)verseView {
    UIStackView *verse = [[UIStackView alloc] init];
    verse.axis = UILayoutConstraintAxisVertical;
    verse.spacing = 8;
    verse.alignment = UIStackViewAlignmentCenter;
    UILabel *quote = [self label:@"“" size:28 weight:UIFontWeightSemibold color:UIColor.systemBlueColor];
    UILabel *text = [self label:@"Tudo quanto tem fôlego louve ao Senhor. Louvai ao Senhor!" size:18 weight:UIFontWeightSemibold color:UIColor.labelColor];
    text.font = [UIFont italicSystemFontOfSize:18];
    text.textAlignment = NSTextAlignmentCenter;
    text.numberOfLines = 0;
    UILabel *reference = [self label:@"SALMOS 150:6" size:12 weight:UIFontWeightBold color:UIColor.systemBlueColor];
    [verse addArrangedSubview:quote];
    [verse addArrangedSubview:text];
    [verse addArrangedSubview:reference];
    return verse;
}

- (UILabel *)label:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    return label;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self validateEnteredKey];
    return NO;
}

- (void)validateEnteredKey {
    NSString *key = [self.keyField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (key.length == 0 || self.checking) return;
    [self validateKey:key savedKey:NO];
}

- (void)validateSavedKey:(NSString *)key {
    self.keyField.text = key;
    [self validateKey:key savedKey:YES];
}

- (void)validateKey:(NSString *)key savedKey:(BOOL)savedKey {
    self.checking = YES;
    self.errorLabel.hidden = YES;
    self.loginButton.enabled = NO;
    [self.loginButton setTitle:@"Validando..." forState:UIControlStateNormal];
    [self.spinner startAnimating];

    NSURL *base = [NSURL URLWithString:FSAPIBaseURL];
    NSURL *url = [NSURL URLWithString:FSValidationPath relativeToURL:base].absoluteURL;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"FilzaSlop-iOS" forHTTPHeaderField:@"User-Agent"];
    NSString *device = UIDevice.currentDevice.identifierForVendor.UUIDString ?: [NSString stringWithFormat:@"ios-%@-%@", UIDevice.currentDevice.systemVersion, UIDevice.currentDevice.model];
    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.2.0";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{
        @"licenseKey": key, @"deviceFingerprint": device, @"appVersion": version
    } options:0 error:nil];

    [[[NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration]
      dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        id decoded = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSDictionary *json = [decoded isKindOfClass:NSDictionary.class] ? decoded : nil;
        BOOL accepted = !error && [http isKindOfClass:NSHTTPURLResponse.class] &&
            http.statusCode >= 200 && http.statusCode < 300 && [json[@"valid"] boolValue];
        id rawMessage = json[@"message"] ?: json[@"reason"];
        NSString *message = [rawMessage isKindOfClass:NSString.class] ? rawMessage : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.checking = NO;
            self.loginButton.enabled = YES;
            [self.loginButton setTitle:@"Entrar" forState:UIControlStateNormal];
            [self.spinner stopAnimating];
            if (accepted) {
                if (!FSKeychainSave(key)) {
                    [self showError:@"Não foi possível salvar a licença com segurança."];
                    return;
                }
                void (^handler)(void) = self.authenticatedHandler;
                [self dismissViewControllerAnimated:YES completion:handler];
                return;
            }
            if (!error && ([http statusCode] == 401 || [http statusCode] == 403 || json)) {
                FSKeychainDelete();
            }
            NSString *fallback = error ? @"Não foi possível conectar ao servidor de licenças."
                                       : @"A licença não foi aceita.";
            [self showError:message.length ? message : fallback];
            if (savedKey) self.keyField.text = @"";
        });
    }] resume];
}

- (void)showError:(NSString *)message {
    self.errorLabel.text = [@"⚠️  " stringByAppendingString:message];
    self.errorLabel.hidden = NO;
}

- (void)openPurchase {
    NSURL *url = [NSURL URLWithString:FSPurchaseURL];
    if (url) [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

@end

static FSLicenseLoginViewController *gLoginController;
static BOOL gAuthenticatedHandlerRan = NO;

static void FSPresentLicenseController(void (^handler)(void), NSUInteger attempts) {
    UIWindow *window = FSActiveWindow();
    if (!window.rootViewController) {
        if (attempts > 0) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 250 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            FSPresentLicenseController(handler, attempts - 1);
        });
        return;
    }
    gLoginController = [FSLicenseLoginViewController new];
    gLoginController.modalPresentationStyle = UIModalPresentationFullScreen;
    gLoginController.modalInPresentation = YES;
    gLoginController.authenticatedHandler = ^{
        if (!gAuthenticatedHandlerRan) {
            gAuthenticatedHandlerRan = YES;
            handler();
        }
        gLoginController = nil;
    };
    [window.rootViewController presentViewController:gLoginController animated:NO completion:^{
        NSData *data = FSKeychainRead();
        NSString *saved = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
        if (saved.length) [gLoginController validateSavedKey:saved];
    }];
}

void FSStartLicenseLogin(void (^authenticatedHandler)(void)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        FSPresentLicenseController([authenticatedHandler copy], 40);
    });
}
