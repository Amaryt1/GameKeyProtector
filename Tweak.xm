#import <UIKit/UIKit.h>

// دالة التحقق من المفتاح المتوافقة مع موقعك (DAY / WEE / MON)
static BOOL validateKey(NSString *key) {
    if (!key || key.length == 0) return NO;
    
    // التحقق من البادئات التي يولدها موقعك
    if ([key hasPrefix:@"DAY-"] || [key hasPrefix:@"WEE-"] || [key hasPrefix:@"MON-"]) {
        return YES;
    }
    return NO;
}

@interface GameKeyProtector : NSObject
+ (void)checkLicenseKey;
@end

@implementation GameKeyProtector

+ (void)checkLicenseKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedKey = [defaults stringForKey:@"AppActivationKey"];
    
    // إذا كان المفتاح مخزناً ومصادقاً عليه مسبقاً، تخطي الشاشة
    if (savedKey && validateKey(savedKey)) {
        return;
    }

    dispatch_async(dispatch_get_main_async(), ^{
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        UIViewController *rootVC = window.rootViewController;
        
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }

        // نافذة إدخال المفتاح (Dialog)
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"تفعيل التطبيق الحصري"
                                                                        message:@"الرجاء إدخال مفتاح التفعيل الصالح من موقعك للاستمرار:"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"أدخل المفتاح هنا (مثال: DAY-XXXX)";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        
        UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"تحقق وتفعيل" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *textField = alert.textFields.firstObject;
            NSString *enteredKey = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if (validateKey(enteredKey)) {
                // حفظ المفتاح لكي لا يطلبه في كل مرة
                [defaults setObject:enteredKey forKey:@"AppActivationKey"];
                [defaults synchronize];
                
                UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"نجاح التفعيل"
                                                                                      message:@"تم التحقق من المفتاح بنجاح. استمتع باللعبة!"
                                                                               preferredStyle:UIAlertControllerStyleAlert];
                [successAlert addAction:[UIAlertAction actionWithTitle:@"موافق" style:UIAlertActionStyleDefault handler:nil]];
                [rootVC presentViewController:successAlert animated:YES completion:nil];
            } else {
                // المفتاح خاطئ -> إغلاق التطبيق فوراً
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"خطأ في التفعيل"
                                                                                    message:@"المفتاح غير صالح أو منتهي الصلاحية! سيتم إغلاق التطبيق الآن."
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                [errorAlert addAction:[UIAlertAction actionWithTitle:@"خروج" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                    exit(0);
                }]];
                [rootVC presentViewController:errorAlert animated:YES completion:nil];
            }
        }];
        
        [alert addAction:submitAction];
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

@end

// تشغيل الفحص تلقائياً بعد تشغيل اللعبة بـ ثانيتين
%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_async(), ^{
            [GameKeyProtector checkLicenseKey];
        });
    }];
}
