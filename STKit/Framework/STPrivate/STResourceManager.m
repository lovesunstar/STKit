//
//  STResourceManager.m
//  STKit
//
//  Created by SunJiangting on 14-5-11.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STResourceManager.h"
#import "Foundation+STKit.h"

extern NSString *const STImageResourceRefreshControlArrowBase64String;
extern NSString *const STImageResourceAccessoryDataZeroBase64String;
extern NSString *const STImageResourceNavigationItemBackBase64String;
extern NSString *const STImageResourceViewControllerShadowBase64String;

extern NSString *const STImageResourceImagePickerSelectedBase64String;
extern NSString *const STImageResourceImagePickerLockedBase64String;

/// WebView
extern NSString *const STImageResourceWebViewBackNormalBase64String;
extern NSString *const STImageResourceWebViewBackHighlightedBase64String;
extern NSString *const STImageResourceWebViewBackDisabledBase64String;

extern NSString *const STImageResourceWebViewForwardNormalBase64String;
extern NSString *const STImageResourceWebViewForwardHighlightedBase64String;
extern NSString *const STImageResourceWebViewForwardDisabledBase64String;

extern NSString *const STImageResourceWebViewRefreshNormalBase64String;
extern NSString *const STImageResourceWebViewRefreshHighlightedBase64String;
extern NSString *const STImageResourceWebViewRefreshDisabledBase64String;
/// PayViewController
extern NSString *const STImageResourcePaySelectedBase64String;
extern NSString *const STImageResourcePayDeselectedBase64String;
extern NSString *const STImageResourcePayPlatformAliBase64String;
extern NSString *const STImageResourcePayPlatformWXBase64String;
extern NSString *const STImageResourcePlaceholderBase64String;
extern NSString *const STImageResourceSaveToAlbumBase64String;

@implementation STResourceManager

static NSCache *_imageCache;
+ (UIImage *)imageWithResourceID:(NSString *)resourceID {
    if (resourceID.length == 0) {
        return nil;
    }
    if ([[self imageCache] objectForKey:resourceID]) {
        return [[self imageCache] objectForKey:resourceID];
    }
    NSData *imageData = [NSData dataWithBase64EncodedString:[self base64StringWithResourceID:resourceID]];
    UIImage *image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
    if (image) {
        [[self imageCache] setObject:image forKey:resourceID];
    }
    return image;
}

+ (NSCache *)imageCache {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _imageCache = [[NSCache alloc] init];
    });
    return _imageCache;
}

+ (NSString *)base64StringWithResourceID:(NSString *)resourceID {
    static NSDictionary *resourceTable;
    if (!resourceTable) {
        resourceTable = @{
            STImageResourceRefreshControlArrowID : STImageResourceRefreshControlArrowBase64String,
            STImageResourceAccessoryDataZeroID : STImageResourceAccessoryDataZeroBase64String,
            STImageResourceNavigationItemBackID : STImageResourceNavigationItemBackBase64String,
            STImageResourceViewControllerShadowID : STImageResourceViewControllerShadowBase64String,

            STImageResourceImagePickerSelectedID : STImageResourceImagePickerSelectedBase64String,
            STImageResourceImagePickerLockedID : STImageResourceImagePickerLockedBase64String,
            STImageResourceWebViewBackNormalID : STImageResourceWebViewBackNormalBase64String,
            STImageResourceWebViewBackHighlightedID : STImageResourceWebViewBackHighlightedBase64String,
            STImageResourceWebViewBackDisabledID : STImageResourceWebViewBackDisabledBase64String,

            STImageResourceWebViewForwardNormalID : STImageResourceWebViewForwardNormalBase64String,
            STImageResourceWebViewForwardHighlightedID : STImageResourceWebViewForwardHighlightedBase64String,
            STImageResourceWebViewForwardDisabledID : STImageResourceWebViewForwardDisabledBase64String,

            STImageResourceWebViewRefreshNormalID : STImageResourceWebViewRefreshNormalBase64String,
            STImageResourceWebViewRefreshHighlightedID : STImageResourceWebViewRefreshHighlightedBase64String,
            STImageResourceWebViewRefreshDisabledID : STImageResourceWebViewRefreshDisabledBase64String,
            STImageResourcePaySelectedID : STImageResourcePaySelectedBase64String,
            STImageResourcePayDeselectedID : STImageResourcePayDeselectedBase64String,
            STImageResourcePayPlatformAliID : STImageResourcePayPlatformAliBase64String,
            STImageResourcePayPlatformWXID : STImageResourcePayPlatformWXBase64String,
            STImageResourcePlaceholderID : STImageResourcePlaceholderBase64String,
            STImageResourceSaveToAlbumID : STImageResourceSaveToAlbumBase64String
        };
    }
    return [resourceTable valueForKey:resourceID];
}
@end

NSString *const STImageResourceRefreshControlArrowID = @"STImageResourceRefreshControlArrowID";
NSString *const STImageResourceAccessoryDataZeroID = @"STImageResourceAccessoryDataZeroID";
NSString *const STImageResourceNavigationItemBackID = @"STImageResourceNavigationItemBackID";
NSString *const STImageResourceViewControllerShadowID = @"STImageResourceViewControllerShadowID";

NSString *const STImageResourceImagePickerSelectedID = @"STImageResourceImagePickerSelectedID";
NSString *const STImageResourceImagePickerLockedID = @"STImageResourceImagePickerLockedID";

NSString *const STImageResourceWebViewBackNormalID = @"STImageResourceWebViewBackNormalID";
NSString *const STImageResourceWebViewBackHighlightedID = @"STImageResourceWebViewBackHighlightedID";
NSString *const STImageResourceWebViewBackDisabledID = @"STImageResourceWebViewBackDisabledID";

NSString *const STImageResourceWebViewForwardNormalID = @"STImageResourceWebViewForwordNormalID";
NSString *const STImageResourceWebViewForwardHighlightedID = @"STImageResourceWebViewForwardHighlightedID";
NSString *const STImageResourceWebViewForwardDisabledID = @"STImageResourceWebViewForwardDisabledID";

NSString *const STImageResourceWebViewRefreshNormalID = @"STImageResourceWebViewRefreshNormalID";
NSString *const STImageResourceWebViewRefreshHighlightedID = @"STImageResourceWebViewRefreshHighlightedID";
NSString *const STImageResourceWebViewRefreshDisabledID = @"STImageResourceWebViewRefreshDisabledID";

NSString *const STImageResourcePaySelectedID = @"STImageResourcePaySelectedID";
NSString *const STImageResourcePayDeselectedID = @"STImageResourcePayDeselectedID";
NSString *const STImageResourcePayPlatformAliID = @"STImageResourcePayPlatformAliID";
NSString *const STImageResourcePayPlatformWXID = @"STImageResourcePayPlatformWXID";

NSString *const STImageResourcePlaceholderID = @"STImageResourcePlaceholderID";
NSString *const STImageResourceSaveToAlbumID = @"STImageResourceSaveToAlbumID";

NSString *const STImageResourceRefreshControlArrowBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAeAAAAUAgGAAAADmLFvgAACkdpQ0NQUGhvdG9zaG9wIElDQyBwcm9maWxlAACdU3dYk/cWPt/"
    @"3ZQ9WQtjwsZdsgQAiI6wIyBBZohCSAGGEEBJAxYWIClYUFRGcSFXEgtUKSJ2I4qAouGdBiohai1VcOO4f3Ke1fXrv7e371/u855zn/"
    @"M55zw+AERImkeaiagA5UoU8Otgfj09IxMm9gAIVSOAEIBDmy8JnBcUAAPADeXh+dLA//AGvbwACAHDVLiQSx+H/"
    @"g7pQJlcAIJEA4CIS5wsBkFIAyC5UyBQAyBgAsFOzZAoAlAAAbHl8QiIAqg0A7PRJPgUA2KmT3BcA2KIcqQgAjQEAmShHJAJAuwBgVYFSLALAwgCgrEAiLgTArgGAWbYyRwKAvQUAdo5YkA"
    @"9AYACAmUIszAAgOAIAQx4TzQMgTAOgMNK/4KlfcIW4SAEAwMuVzZdL0jMUuJXQGnfy8ODiIeLCbLFCYRcpEGYJ5CKcl5sjE0jnA0zODAAAGvnRwf44P5Dn5uTh5mbnbO/0xaL+a/"
    @"BvIj4h8d/+vIwCBAAQTs/v2l/l5dYDcMcBsHW/a6lbANpWAGjf+V0z2wmgWgrQevmLeTj8QB6eoVDIPB0cCgsL7SViob0w44s+/zPhb+CLfvb8QB7+23rwAHGaQJmtwKOD/"
    @"XFhbnauUo7nywRCMW735yP+x4V//Y4p0eI0sVwsFYrxWIm4UCJNx3m5UpFEIcmV4hLpfzLxH5b9CZN3DQCshk/ATrYHtctswH7uAQKLDljSdgBAfvMtjBoLkQAQZzQyefcAAJO/"
    @"+Y9AKwEAzZek4wAAvOgYXKiUF0zGCAAARKCBKrBBBwzBFKzADpzBHbzAFwJhBkRADCTAPBBCBuSAHAqhGJZBGVTAOtgEtbADGqARmuEQtMExOA3n4BJcgetwFwZgGJ7CGLyGCQRByAgTYS"
    @"E6iBFijtgizggXmY4EImFINJKApCDpiBRRIsXIcqQCqUJqkV1II/" @"ItchQ5jVxA+pDbyCAyivyKvEcxlIGyUQPUAnVAuagfGorGoHPRdDQPXYCWomvRGrQePYC2oqfRS+"
    @"h1dAB9io5jgNExDmaM2WFcjIdFYIlYGibHFmPlWDVWjzVjHVg3dhUbwJ5h7wgkAouAE+wIXoQQwmyCkJBHWExYQ6gl7CO0EroIVwmDhDHCJyKTqE+0JXoS+"
    @"cR4YjqxkFhGrCbuIR4hniVeJw4TX5NIJA7JkuROCiElkDJJC0lrSNtILaRTpD7SEGmcTCbrkG3J3uQIsoCsIJeRt5APkE+S+8nD5LcUOsWI4kwJoiRSpJQSSjVlP+"
    @"UEpZ8yQpmgqlHNqZ7UCKqIOp9aSW2gdlAvU4epEzR1miXNmxZDy6Qto9XQmmlnafdoL+l0ugndgx5Fl9CX0mvoB+nn6YP0dwwNhg2Dx0hiKBlrGXsZpxi3GS+"
    @"ZTKYF05eZyFQw1zIbmWeYD5hvVVgq9ip8FZHKEpU6lVaVfpXnqlRVc1U/1XmqC1SrVQ+rXlZ9pkZVs1DjqQnUFqvVqR1Vu6k2rs5Sd1KPUM9RX6O+X/"
    @"2C+mMNsoaFRqCGSKNUY7fGGY0hFsYyZfFYQtZyVgPrLGuYTWJbsvnsTHYF+xt2L3tMU0NzqmasZpFmneZxzQEOxrHg8DnZnErOIc4NznstAy0/"
    @"LbHWaq1mrX6tN9p62r7aYu1y7Rbt69rvdXCdQJ0snfU6bTr3dQm6NrpRuoW623XP6j7TY+t56Qn1yvUO6d3RR/Vt9KP1F+rv1u/"
    @"RHzcwNAg2kBlsMThj8MyQY+hrmGm40fCE4agRy2i6kcRoo9FJoye4Ju6HZ+M1eBc+ZqxvHGKsNN5l3Gs8YWJpMtukxKTF5L4pzZRrmma60bTTdMzMyCzcrNisyeyOOdWca55hvtm82/"
    @"yNhaVFnMVKizaLx5balnzLBZZNlvesmFY+"
    @"VnlW9VbXrEnWXOss623WV2xQG1ebDJs6m8u2qK2brcR2m23fFOIUjynSKfVTbtox7PzsCuya7AbtOfZh9iX2bfbPHcwcEh3WO3Q7fHJ0dcx2bHC866ThNMOpxKnD6VdnG2ehc53zNRemS5"
    @"DLEpd2lxdTbaeKp26fesuV5RruutK10/"
    @"Wjm7ub3K3ZbdTdzD3Ffav7TS6bG8ldwz3vQfTw91jicczjnaebp8LzkOcvXnZeWV77vR5Ps5wmntYwbcjbxFvgvct7YDo+PWX6zukDPsY+Ap96n4e+pr4i3z2+I37Wfpl+B/ye+zv6y/"
    @"2P+L/hefIW8U4FYAHBAeUBvYEagbMDawMfBJkEpQc1BY0FuwYvDD4VQgwJDVkfcpNvwBfyG/ljM9xnLJrRFcoInRVaG/"
    @"owzCZMHtYRjobPCN8Qfm+m+UzpzLYIiOBHbIi4H2kZmRf5fRQpKjKqLupRtFN0cXT3LNas5Fn7Z72O8Y+pjLk722q2cnZnrGpsUmxj7Ju4gLiquIF4h/"
    @"hF8ZcSdBMkCe2J5MTYxD2J43MC52yaM5zkmlSWdGOu5dyiuRfm6c7Lnnc8WTVZkHw4hZgSl7I/5YMgQlAvGE/"
    @"lp25NHRPyhJuFT0W+oo2iUbG3uEo8kuadVpX2ON07fUP6aIZPRnXGMwlPUit5kRmSuSPzTVZE1t6sz9lx2S05lJyUnKNSDWmWtCvXMLcot09mKyuTDeR55m3KG5OHyvfkI/"
    @"lz89sVbIVM0aO0Uq5QDhZML6greFsYW3i4SL1IWtQz32b+"
    @"6vkjC4IWfL2QsFC4sLPYuHhZ8eAiv0W7FiOLUxd3LjFdUrpkeGnw0n3LaMuylv1Q4lhSVfJqedzyjlKD0qWlQyuCVzSVqZTJy26u9Fq5YxVhlWRV72qX1VtWfyoXlV+"
    @"scKyorviwRrjm4ldOX9V89Xlt2treSrfK7etI66Trbqz3Wb+vSr1qQdXQhvANrRvxjeUbX21K3nShemr1js20zcrNAzVhNe1bzLas2/KhNqP2ep1/XctW/a2rt77ZJtrWv913e/"
    @"MOgx0VO97vlOy8tSt4V2u9RX31btLugt2PGmIbur/mft24R3dPxZ6Pe6V7B/ZF7+tqdG9s3K+/"
    @"v7IJbVI2jR5IOnDlm4Bv2pvtmne1cFoqDsJB5cEn36Z8e+NQ6KHOw9zDzd+Zf7f1COtIeSvSOr91rC2jbaA9ob3v6IyjnR1eHUe+t/9+7zHjY3XHNY9XnqCdKD3x+eSCk+OnZKeenU4/"
    @"PdSZ3Hn3TPyZa11RXb1nQ8+ePxd07ky3X/fJ897nj13wvHD0Ivdi2yW3S609rj1HfnD94UivW2/rZffL7Vc8rnT0Tes70e/Tf/pqwNVz1/"
    @"jXLl2feb3vxuwbt24m3Ry4Jbr1+Hb27Rd3Cu5M3F16j3iv/L7a/eoH+g/qf7T+sWXAbeD4YMBgz8NZD+8OCYee/pT/04fh0kfMR9UjRiONj50fHxsNGr3yZM6T4aeypxPPyn5W/"
    @"3nrc6vn3/3i+0vPWPzY8Av5i8+/rnmp83Lvq6mvOscjxx+8znk98ab8rc7bfe+477rfx70fmSj8QP5Q89H6Y8en0E/3Pud8/vwvJNfOtgAAACBjSFJNAAB6JQAAgIMAAPn/"
    @"AACA6QAAdTAAAOpgAAA6mAAAF2+SX8VGAAAACXBIWXMAAAsTAAALEwEAmpwYAAABB0lEQVTt1FGnwzAYxvHKPl2VqkpFoqr9KGMXdTjpXmOMMcbhcL7cuR0juwpbtrRptb16/uSqr/"
    @"enRKIIIYQQQmhMcRxvicgkSbJbFdZa34jIaK1vq8JEZOwBDBgwYMCAAQMGDBgwYMALw1mWfRORkVKeGWObuWG7Xyl1efnQtu2/"
    @"XVRV1c8QPgYWQpzsbNd195fdaZp+PS8bwkPhZ5SIjBDi9DZUFMUxFA+BXbT3Z1y8ruvfT8NDsIuWZXkdvDsheB88CQ3FfbCU8jwZtXHODz78EzwL6sObpvljjG1c2EWVUpfJaB/"
    @"uIrOjPtx3ZkVD8UVQW57n+9VRH/728C+Zfds554cIIYQQQmhsD23BI9cAAAAASUVORK5CYII=";

NSString *const STImageResourceAccessoryDataZeroBase64String =
    @"iVBORw0KGgoAAAANSUhEUgAAAFoAAABaCAMAAAAPdrEwAAAAA3NCSVQICAjb4U/gAAACQFBMVEX////////39/fv7+/m5ubW1tbMzMzFxcW1tbWtra2lpaZ7e3tzc3NaWlr////"
    @"f39+1tbWtra2lpaZmZmZaWlr////f39/W1tbFxcWMjIyEhIR7e3tra2tmZmZaWlr///97e3tzc3Nra2tmZmZaWlr////39/fv7+/FxcW9vb2UlJSPj5CMjIxzc3Nra2tmZmZaWlr////"
    @"39/ff39+tra2ZmZmPj5CMjIx/f4Bra2tmZmZaWlr////v7+/FxcW9vb2goKFzc3Nra2tmZmb////39/fm5ubf39+lpaaZmZmPj5B/f4B7e3tra2tmZmb////39/"
    @"fW1talpaaZmZmUlJSMjIx7e3tzc3Nra2tmZmb////v7+/W1tbMzMzFxcW9vb2ZmZmUlJSMjIx/f4BmZmb////39/fv7+/m5ubf39/MzMzFxcW1tbWZmZmPj5CEhIR/f4Bra2tmZmb////"
    @"39/fW1ta1tbWUlJSPj5CMjIyEhIR7e3tzc3Nra2tmZmb////39/fv7+/m5ubf39/W1tbMzMzFxcW9vb21tbWtra2lpaagoKGZmZmEhIR/f4B7e3tzc3Nra2tmZmb////39/fv7+/"
    @"m5ubf39/W1tbMzMy9vb21tbWtra2lpaagoKGZmZmUlJSPj5CMjIyEhIR/f4B7e3tzc3Nra2tmZmb////39/fv7+/m5ubf39/"
    @"W1tbMzMzFxcW9vb21tbWtra2lpaagoKGZmZmUlJSPj5CMjIyEhIR/"
    @"f4B7e3tzc3Nra2tmZmYZlakDAAAAqXRSTlMAERERERERERERERERESIiIiIiIiIzMzMzMzMzMzMzREREREREVVVVVVVVVVVVVVVVZmZmZmZmZmZmZmZ3d3d3d3d3d4iIiIiIiIiIiIiImZ"
    @"mZmZmZmZmZmZmqqqqqqqqqqqqqqru7u7u7u7u7u7u7u7u7zMzMzMzMzMzMzMzM3d3d3d3d3d3d3d3d3d3d3d3d3d3u7u7u7u7u7u7u7u7u7u7u7u7u7u7uVGp1HwAAAAlwSFlzAAALEgAA"
    @"CxIB0t1+/"
    @"AAAABd0RVh0Q3JlYXRpb24gVGltZQAyMDEzLjIuMjfhvQHfAAAAHHRFWHRTb2Z0d2FyZQBBZG9iZSBGaXJld29ya3MgQ1M1cbXjNgAAABxpRE9UAAAAAgAAAAAAAAAtAAAAKAAAAC0AAAA"
    @"tAAAE0dhHj/oAAASdSURBVFjDrJbtaxxFHMdnKFisZKoN0zel3SIdX1g0rLRgmxVtu+qL0luk0IdVKNSuFYq1uCr0RTIKPiG0JplYQqF9U5LLmXiXJubmYWfSf80XM/"
    @"twyV7uLjrvbuc7n/3ed34z+wNg8Bg7Ntm4NT23/GLrxfLc9K3G5LEx8H+ME43prS1jtNZZlmWZ1tqYra3pxon/"
    @"yr3eNEZnSikppRRCSCmlUirTxjSv750+dmHWGK2UFELw6hBCSKW0MbMXxvYGbhqtpOylVvhSKm2ae4CfbRqt+"
    @"nJzutKmeXY08NGp7WBRju3wqaMjkBs9YCG6G2vt1ZVWq9Vqray219a7JV9IpU1jWPD4lMkKsBAbnZUWY4wxSimljDHGWiudjYIuZGamxociTzS1KpZtdv5ijNI0TZLYjiRJU0oZW+"
    @"lsFiqlmxNDkM8YnVsWm+0Wo2kSR2EY+D4hhBDfD8IwipOUslY7hwupzZmB5Esmk07fbTNGkzgKfOJhjPKBsUf8IIoTyli76+"
    @"AyM5cGkK8ZlZOfz7M0iQLfwwhBCAsJhBAh7PlBlKRsfi1nK3NtEFk4y6uMJlFAMKpQQYWPMAmihLJVl4pQu/"
    @"o+X5DX53NwX3EOn18v2Of7it8qyGssjcNdwTk8jFPWKdhv91EeWXI7KDo0jXxvANjCPT9KaVu4vVw6Uis7MJOT2zQJCYZDnQKISZjQv3P2zIE60VVtybJN44AgOOTZhcgLYtp2a/"
    @"XVGslxF7Rco3HgDU3O2R3p4j6+Q7B/JhOccy42aBx4aKR7EnlBTG2diGxm//bpczYO0f1hZDIA0Atiautb6nPbJg8tuTgeJaOTAUBekDxykSwd6p27Yk3Lx2m4BzIAyAuTxxahr/"
    @"TMvGpNi24akRF2sLqXJPq2K6zt16ozF53phdjHeyEDALEfLzjbFyvP9y0600no7Y0MAPTCxNn+Y1/5+KQz/XNEyqDHGnPLy99M7tJO9AoQiX5ytk+WL7xnTfMkKOOYaBqttTbT430/"
    @"dL0CiIPc9r2CcnDRlUfF9OtGKymlVHr2lVryTgEi0S8WtHgwN31aS865ULdL0y/"
    @"PuI+6ULXXQp0A4uALKTjnUp92HHjT5vG0Yvpdd1dxLtTSSzXoOgEi0RObyE2HRg8V55zLX0vT8POsaGKkfrOmHuoEEAc2EfXQeoSHXR5f+oVp9LUqm6/sg50FWS9A/"
    @"qfKJnIYAgAAPJUJzrmQUVHTEH9VWaneRzsPSK0AeqEQnHORnbLoy/ZNTyt54BvVle/UoGsFEAdPbAKXIQAAoLsW/VuZB8Qflg2j/"
    @"N2vQdcLkP+9Rd9FAACA7tvo75AKOviuKAB+uw5dL0Dkji2J+wgAAPED+6LPyusDYj9esLbE5o/"
    @"V0z9AAL1PbAQPMAQAes8s+uPKnYdIlP75fFPwfzqsevoHCSD+yKKfeRAA6GWScy6y9yoEiP04Za1Wi9E0JKj+Dq0RQBxkgnMuM4e29dJTBxD7UZJSmvbrSPoIkG9PtkUTh+"
    @"7dLIhJEEVR2LdvqBcg4tAEAoBy9Lb/DRH2iOf17/tqBSUaVX68gXY0uhDC3T46NYLcqCII/AsAAP//LWVH6gAABTBJREFUrZf7b1RFFMdnjK9EO7/"
    @"UiY8IE8SJmihwQ6Kx3miwQ6KG9BKjAW6C0dghkfALHYiKbEfFhIAkPAYiUIhASJdd22637XYe987yr/"
    @"nD3N3ePrbdQs+Pd+d87tnvnjnnuwDRB0ZrbbK9CDx9oL2Z0VqbBxQBgOh9q7U22Wdbgv40M1prez+"
    @"gL1mttXFfbwn6C2e01vYSRQBAejGgf9gS9PcBfZFCACA5YbXW2v26JehfnNZa2xMEAgDJ0fCihxg+NRnih0GCowG9P6Dz93qjX/lkZOzao8ftx4/"
    @"GR4ffXgf9bh7Q+wkEAOL4Xui+b3qgt4+Mt73P8yzLsjzPva+O7umF/" @"jL03r0YQwAAii4Esc+sKfbu8bbPM2ettcYYa61zWe6rIwNrSn0mKHAhQgAAgOjxIH3+"
    @"2hrgqz7PnDVGL4Wx1vWAv5qHKo9TBAAAkBy0QZFvVyqybdznzpaxXbrLfHVolR5fBT3sQQLDr8ruBu0vP7P85Ei7CzZ6YW620WjMNucXTUh3uR8bXIG+"
    @"HPS4y4puw9FpGxT5qHxusOKz8HX0fOO/Wk2FqNXq07MLxhhjXV7dvQz9YdDDno5woT1NQyHuckmRbdXcWa2Nnp+pK6WkFEJwIYSQUil1/eYdY6zL/"
    @"Ei56N9cKCWlRUdAws6vKvutydwaY1qNulJScJ4mjMVxzFiSpFwIqdT1W/9am/"
    @"mTL3dz3i+KPs8I7Fyh6Fj45u7Kc8WpNydza82df5SSgqcsjighGGOMCaE0YknKhZTyr79d5isvFTnPXwlF22NR92IjmkwUZR8oHlVyd+/"
    @"870pKnrKYEowQ7ARCGBMas5QLKX66lPmTRc6BouiJhKKlmx+fKtT2b4QnP/"
    @"58XEgpeBJHBCO4oishRJhEccKFSL97WH0WAADA65OhaHMqLk0jRNPb4Y3Z2RcBABBRxgVPWURXc5foNGIpT9k7CAAAXjibBcTtlJauNSQx1yZIciioz9Ki4HVmEcIkYgkLyh4KchjNY1JO"
    @"QjQ5Fz5xfh8AEJGod8Hl0jGJYoohAPu8C7WdSyhaPmdjPmEK9gcAQIQR6md8Q4QxRhDsKshmgscr5j6iyanF8NrM7wAAwn73AoQQgh2TQWjTEiuKBgDiKP0zjAub+"
    @"V2bXC67fCBr80carVpWkDB+03bYn2+K/HGHbG9yRuBq0WgibnXZhzdBPtwl31otR0cS2Sw0cb4y2Cd4sOJdoUZTriFH0SWpnCvGs8urw32Rh6u5K3LmZBr3cAWQxLxTt7GZv7pzQ/"
    @"DOzkzX2jTlisuyrANJzGWj2FfW5b6ye33wmM8LMbRpSB4T1Lv/CeNyZmn/"
    @"5b4yNNDj8MBQpbw4ZyRnZJ1bBhGJubzRMiV4e2wN+sDQaLsENq0bksdk3fsLEYlTqZqmtLlz3742Orxne3jBwPY9w0euBWvSPdVUMt2AXLCFmmp104x1WZ573263q4+"
    @"q7XYwUiVrYlpTSmxMDv2dcKkaums/jLHWOZeFcM7ZkuUxuqEkT6K+vCjElKVCXZ/VyyzTUpSf6tm6EimjfbpciEiUcKnqjcU1jFMZvNioK8mTiKC+/"
    @"TPENE64VLXpOd2LbvTcdE1JnsR0U8YcogKuasEqLacaszA7XVMFGG3S8hdwIZWq1admmvOtRW2M0Yut+ebMVL2mlBRPBO7AI5YEq6RUrRNKKSWF4EnY90/"
    @"4zwRhEqwSF0J2QgSbFlHyxOCO28CERsHrpWmaJgljcUQJ3njf94VHwetRSiklBGO0Bdjy2oYIocL69Zf0Pz2KjyG8ScjaAAAAAElFTkSuQmCC";

NSString *const STImageResourceNavigationItemBackBase64String =
    @"iVBORw0KGgoAAAANSUhEUgAAACAAAAAwCAYAAABwrHhvAAAACXBIWXMAAAsTAAALEwEAmpwYAAAEAGlDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjajZXPbxRlGMc/u/"
    @"POrAl1DqYCFlMn/gBCSrOAQRoE3e0u20Itm22LbWNitrNvd8dOZ8d3ZsuP9MRFb6D+ASpy8GDiyQR/RbgABw0kBA2xITHhUOKPEEm4GFIPs92d1jb1PT37fb/P9/k+z/"
    @"tkB1Kfl33fTVow64WqVMha4xOTVuoOSZ5hE11sKtuBnykWhwDKvu+y8iTg0c8kAG7tXuN+"
    @"o7OpIgMbEk8A9Upgz0LiFOiu7asQjHvAgZOhH0LqWaBTjU9MQioNdFajOAd0TkXxONCpRkv9kHIB066VK5CaB3qmYng1FkceAOgsSE8qx7ZKhaxVVPVpx5Uxuxtc/"
    @"88z6zaW63UDHcHMyDFgJyRO1dRAqRl/" @"YpfzI8CLkLjuh9kSsB0SfzRmxjLALkg+"
    @"Na2OjEX85KtnaqNvApshWXHCwdEmfsabGj4e5SYvzNSPlZqc63bQPwk8D8m7NTk4FPnRqMhcHugBrbvWGGjqa0eDuZH8ss6ZWv9wpKOpd8pHi0AXaO+reul45Fm7IN1CKdLXrvphselBW/"
    @"Tc4aFIU5gyyI8s42FtdCDKFftDNdrMFZPTzpHBJn/"
    @"ed4tDkTdxUTVKY03OzbLKFyId8bf0xpqa+tZKOXcM6AX9MCcSZSR1ppDYeDzGokSBLBY+ijrTOLgUkHhIFE7iSWZw1uEVkahm3GZUkXgsonCw1+"
    @"FEFe43OXWxRaTFPpEWB8WQOCQOiD4s8Zp4XRwWOZEWfeJgK7cYq29R5X5L510aSCxKnCB7vquxs13vrHrbsW+ce7Aiu/4fz3LZT3wCBMy0mLvj/V+b/"
    @"25rW+O2uPTWrY5r8xzfaL76PX1Rv63f0+/oC22G/qu+oC/od8jg4lJFMovEwUMSxBzEe7iCS0gZl9/wqMd4KypOe+e72jf2jXMP5HvDj4Y529NG07+k/"
    @"0zfTn+avpj+fdWU15yS9pH2lfa99rX2jfYjlnZZu6L9oF3VvtS+jb3V+vvRensysW4l3pqzlrhm1txmvmDmzOfMl8yhtp65xdxjDpg7zJy5rfVu8XrxXhwmcFtTXbtWxBvDw+"
    @"EkEkVAGReP06v2v5ktusUeMbhqaw+Ig6Ll0sgbOSODZewy+ow9xlEj0/Zn7DByRp+xw8iv2Dp7nQ5kjBXvczdTSAJmUDjMIXEJkKE8FQL01/"
    @"3TyqnWQmtvOv2KlfF9V1qDnt3bY5Vd11JOtRYGlpKBVHOy0sv4xKQV/UU/LJEAEptvtLHwDTj0F2g329hkA74IYMvLbWxnFzz9MVzabzfU3PI3M/ETBNP79ka/OrKg311aergdUh/"
    @"C4w+Wlv65sLT0+DPQFuCy+y9gZXF57k4HNAAAACBjSFJNAABtmAAAc44AAPJ7AACE2gAAbpQAAOUaAAAzJwAAGReZSRx/"
    @"AAAA5ElEQVR42uzYQRKCMAwF0CRX9gDi3jP3u2KGEcWkJD8u6B7+o03TDgpAOodJ87gA7QDFLe1dazWriIg8QZ2BbRoG5M5cgt2nmsrCAqCzCI/"
    @"CtRqQEj4LSAufAaSGRwHp4RFASbgXUBbuAZSG/" @"wKUhx8BKOHfALTwTwBq+DuAHr4FtISvgLbwv7mUauWFwzsDbQhzrjdYNUBHWLDywdoFNIRN9gCw+"
    @"kA5wtOIShHeTliGiLTiEkT0LEhHzBxGqYjZ0zANceY4TkGcvQ8oaxuGEAO8PyQ7xIAspvJwP3j9qr0A3YDXAF7fNNH9M4kZAAAAAElFTkSuQmCC";

NSString *const STImageResourceViewControllerShadowBase64String =
    @"iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAWNJREFUeNp0VAuyAyEIIztuL9V3/2vliYIC2p3p1A/"
    @"GBIIgKf79fb+PkE2ARv0X0d+Hwlcob4/"
    @"89HkfU8evzHnjjGt69pHwDWjABnEDupHjwgddMGIJEGOd84hhzDiOUw6pdyJAdwVzjgLIGM3JFB7JRSJQxCZiSg6GkyX27QxqA0XCJhZwZTjIOys/"
    @"gFvWukSnO8AtzX2tAMLVhRLMdRZsT62CYPzwI4crzRsKJopeUsYUwNTM9VZzuCu3xKURE3faBVjxRXKAthyBdwUw9mOklrKct6Mogpwn1JrQrTBiB+"
    @"hyBS5FqUMGPy32y9kDLPbQKZlBHIqdwn5wTcffvrh0ClO+"
    @"vZJIWYT8KuZzlgPb1NV7nAVgwSS3fc7HIXVobTm7UqvKWvtp8FYlQ8ILk96BbSWyPm2bzCGZIU2MiwFFPYdrNUuVsR6G4pRNZF2wOga5VZ9fNiSzXFCOJow+971/"
    @"AQYAQJW4FRODSokAAAAASUVORK5CYII=";

NSString *const STImageResourceImagePickerSelectedBase64String = @"iVBORw0KGgoAAAANSUhEUgAAAD4AAAA+"
    @"CAMAAABEH1h2AAABAlBMVEUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC4uLjd3d3t7e309PT6+vr9/f3+/"
    @"v61tbXk5OT29vb9/v7////AwMDr6+v2+fvi7fuwzvSEtO5fnek/iuUoe+IZcuCSkpLn5+f19/v0+P2uzfRspesuf+MUb9/Ozs7t8PT4+v6lyPNVl+jg4ODx9fnC2vdmoerk5OT4+/"
    @"2bwvE3hOT7/f6FtO4YceB+sO0jeOHv9f34+v7q8vwfduHy9/1KkOZJj+ba6Po4heQmeuLu9f3o8fz8/"
    @"f85huRJkOZqpOsu0brmAAAAQnRSTlMAAQIDBAUGBwgJCgsMDQ4PEBESExQVQXCZvNft+z6Cvvn/SZjn/v///////y+J5v7/////WcH+//905///g/f///"
    @"z1JqqYAAACq0lEQVR4AaTUa0tbQRAG4Jlzyc3ERKsFgxUUWvFb//+fKP0kWKjF1ljUamJiLuey0x1fUFbGk1P6yoogz87unN1l+q9wnX/"
    @"JP3LGYGB4qcXh9AdemQgJZlnDgTWsHly1BhNUcZSNGOOZi8PAImwOrTCK/MASSLFS5/wQgbc4sLdxpGF4AdeUTn0wAb/S3sZx1EHl56iau7L0M4SeA+0r+/"
    @"SZS0qC6gXFIpPSxzn4gEMrTobM002j+kNPZFToBPABV+3XnSSHfLvLnNPrpCI3O3JeFH4H8AFnVpx85KshL8hKW0Z78q3QCUQCDh2nyQn/POAp2enJxQc5LfISHhy/I/"
    @"a105Pk7h2P6a0M5M92cZr7+uJIXrj23OtP6WT3nqqyddPPz7x3TsChWfVR4+pwQtXpn+9l39Vj+eDatnS/fXuQjNfwQXGxs/iVa/"
    @"vAdWjb0uFsmE5pXXr5qDvKtX3kPaO411vdVmNB69POlrN777U8+FPxgXtfUJ0k19H4qTw4dt5rbrTzKrV9R0i6eFxNsXtwLd6N+"
    @"3GVTjcfckLKSTnT8uCsa29sRIOoSvfPjvkaf7uxe8w8d+D6zRudtMeV+oR/"
    @"EyLTfJ75bw8ead+V19CIcu29w0VV3m5062qaZYsMm2flieet5kZdTY+rpecFeBT5rTearU5dTfPlKstyvTfKY+WNdruupsUiU16+8GbaaT1fi3G1puU8X73J95gvbW3zcPH7/PVzeWloa/"
    @"FG69zhF3hTB60zPhx89IOgO+eE2B/" @"OOjbwtg6PjXlo4S8tHR5a88rAH4upgytjX1h4snV4Ya3nAn5paeO5sB+rIzG08Vj9Lb0OBAAAYCAI+"
    @"VsH0SD23b3KeNQ7Ez9SP5E10MGDwMnRKGF2LDyUHokT5J8DHyOfQhFin4EfoXUABH7uXfP0iQ8AAAAASUVORK5CYII=";

NSString *const STImageResourceImagePickerLockedBase64String =
    @"iVBORw0KGgoAAAANSUhEUgAAAQgAAAFSCAYAAAAO40FuAAAACXBIWXMAABYlAAAWJQFJUiTwAAAAHGlET1QAAAACAAAAAAAAAKkAAAAoAAAAqQAAAKkAACFPkVhKaAAAIRtJREFUeAHsnXu"
    @"MXPV1xylmMRhiMHEoNGAWgqCFkj9CqZSE0EhJI1EJ2qiCiroplAJJSEhDX1BaRa6UGswzCdiYR8E8DNhgr8Fee23v+zH7fnv9wHZUUaKqoLRUpJYsIU3P586c6W/v3pmdWc/"
    @"dnd+95yf9NLOzM7/7O9/zPd97zu/+5s5JJ1lLMgK/"
    @"JsbNR08yhmabIeA1AuUIwMliYRy9nGN7Da5N3hDwCYFSATlNAHqH9n9hcPTQHwyNvfud0YmjTw1PHHl2dPLo3pHJo8P0samfZyvp+"
    @"jnGCMaSMRmbY3AsAXHa8eXvUnP1CXObqyFQswgUC7JCMBKcQ+OHbh2ePPLIyL4jTWNTR98n8EenjmZH9x3Njkweycr/skMTh7ND44ezg+PvZgfG6Iey/aPldd7LZ/"
    @"gsYzAWYzI2x+BYObE5+j5zYC7MKUI4itlTsw6wiRkCtYZAVBAVBGFgdN81w+OHH8iJwc+PEZwjEqRyVg+Cl0AuN/Cr/T6OjYAwF+aUF45jgWjInJm7gF2wRZ5H2Vpr/"
    @"rD5GAILjkA4UApB1No9ePnQ+Ls/"
    @"kNS+Qc7Sv+SMHWQEEogLKQbliktBNPLZRmCD2IJN2CbIF2yV52EcFtwxNgFDYKEQCAdDECh33fVM3cD4gRtEEF6hXNAygTOzD4Iwm3CoYGh5EtgotmIztoszVDDC+CyUn+"
    @"y4hsC8IRAmvQbDydTrspj4uJxhP0AUqPOTIAhlCYbYis2B7YJBGWsX8+YwO5AhMB8IRApDY1vbeUOTR/5WsoXJoHSQ2j0NolBMNLCd9QuwABOwASNxkAppGMf58J0dwxCIBYEwmQOSv/"
    @"jii6cNjB28WQKgMRAFqc1zVxbKu6JQLLiS9DpXTcCEtZa8WDSCGdiJp0wsYqGrDTpfCEQKw+ampnNGJg7fRxrNCn9S1hTiFqbCmkW+BAFDsDShmC8623GqhUCkMOzt7l4hC3I/"
    @"lTPhx5wROTPGHVRJHd/JKj4GU7A1oagWfW2cuBCIFIbtLZnPjkwcWS/"
    @"CcJy6Os1rC9UWLGet4jgYg7UJRVz0tnFPBAFXHILaeOfOzs+MjB9+VDYJHTNhiHddpSAUgjWYg30RoTgRH9tnDYGKEZghDDfdtOrUwYnD94owfGTCEK8whDMSRyg+"
    @"wgf4QjwatZhZsaPtA4ZAJQjMEAb58KKeAdn+PHl4TC7LZQdkjaFPvuNgff4xAHt8gC/"
    @"wCb6RbkJRCcPtvXNGICwOizZvbjpHsoX1w5NHs4Njh4PFx74RCQzrC4YB2QW+wCf4Bh+Jx1UoXB/OmQj2QUPARcAllZ6NFvUOH7hNvgL9wdD4EREGyRpMFGoKA3yCb/"
    @"ARvhKHqkjgQ9enrq/" @"tuSFQEQJKpIIwNHeOXCGXK1t1ncGEobYzJl2fwGf4TrwfJRQVkcLebAioMPBYEIfB8UMPSOp6fFC+OGVZQ20Lgyvc+"
    @"Aqf5Xx36AHxaZRI4GtrhsCsCITFYdHLW3efOzLxbmPuC1QExkHrHmLAFm58iC/xqTBBhcL1+awEsTekEwGXJIWsoad/4otCqvd0B6SJg9/"
    @"iGCxicrVDfIpvHZGwtYl0xn1ZVofFgTPLooGRgz8Ynjh8fFC+ZWjC4LcwhP2HT/EtPs6LhGUTZYVK+t40QxzkW4Nny3rDFispkiUKYZHQkgNf4/"
    @"O8UFgmkT4NKGqxikOhpOjqG75azixHrKRItjioWGjJgc/xvSMSrlAUJZD9I5kIqDDwWBCH3uHJP5HLl8espEiHOKhI8JgrOY4cgwPCCS03XJGAK9ZSgEBYHCDDKb0jB/"
    @"46V1LYeoMbOGl6zp4JOAAX4IR0FQqXMykIkfSa6Dqas0MgDvIbDmttvSF9WUOU+Om6BJwQfphIpEgrVBwKJcWqVauWyFrDZu7uRC0aRRh7LX3CARfgBNyAI/"
    @"kTifJGeZSi0Em+qepUdfIiHC9ni+22GJk+AShH9HXxEo6YSCRbIGaIw5o1//"
    @"qpwbGDu00cTBxKiYWKBFyBM5ZJJE8oIsVB0sduEwcTh1LioP9TkYAzJhLJEogZ4pArKw4258TBAkSDwB5Lc6F/VC6DyvZsufV+s5UbyRCJGeJw/"
    @"fX3LO4fP7jNMofSwWBiEY2PZhJwCC5ZueGvUMwQBzHlFFH/V00coslvolAeLioScAlOmUj4JxKR4tA3vP9hE4fygsDEojROKhJwykTCL4FQceCxsAmqp3/"
    @"yntwNXg7JDrmD1g2DE+ZATiQOZ+FWSCRcDvoVPQmfreuYgji0945cL+LwSb/cKMTEwcSxmhyAU3ALjplI1L66qEAUxKGppfcL4sCPuN1Y77AEh3XDoMocyN/"
    @"K7iO4VkQkaj9yUjDDGeKwbt26ZQOjhw4NmDiYKFRZFMInGjgG1+CciUTtqc0McZAp1mWGpjbyzbywM+"
    @"1vy6Ti4ABcg3Nwz0SidkTCFQdKCy471bX3TfwFDuOuxnGQwcY0kQlzAK7BObgHB/NchJN05ak8tTZfCCjoPOq6Q92O3W2/"
    @"LTf++JhV5rAT7W8L7Dg5EFzZEO7BQeEkImH3kpgvNYg4jgqEisMpd99995lyDX/"
    @"c1h1MCOIUglJjwz04CBeFs+5GKuVrBJXtpWojoGAXxEEOUJcZnHomV1pYgJQisf0vPn6wySxYjxAuwknpJhLVjv5ZxnPFAYEI1h3aeob/LHcfSSstTADiE4BysGU9Ai7CSeGnigRcpSt/"
    @"5am1OBBQgDV7qNva2HyZqLbsdzBxKIfA9p74BQQuwkm4KUEQtR4RR2ykfsywOJA9nNo7vH+nrTvMnfQ9g/uzXf37Ijv/M0GZG7Y5Tu7fCUelW6kRs3xFiUNdc+fQH3GTUWo/"
    @"+Yl360Uw6OqfzLZnxrItXcPZvR2D2abWvmzj3p6KOp/hs4zBWIxpmBfnXG494lAWjkpsaKkRvrIRc9ikZ/iwQNSxUtw/cvAIN/Mwok4nKsHb1jOa3dM+kN3ZnCkpBG/"
    @"v6nivobFtMqrzv1JCwtgcg2OZYEz3AZyEm3A0f1XDSo2Y9CosDkFp0TUw8U9kDyYOOWISoHK2ihKETwj+199qfO35DZt//MhPnr7znnv/"
    @"7hviq4ul15fZL+YzfJYxGIsxRTw+cQUEwWAOJhb/LxZwFK4KzlZqCAjVblHiULd5W/MV8m26j0WdUy0QPYNT2dbukeyult5pWULDjtaxl1/"
    @"f9vSDj6297bKrrvpNcUq90y+S5+G+Ql6L6uH38Xe9dsbmGByLY7piwZyYG3NMs4jDUbgKZwU3KzUEhGq2sEAA8KmZwQO75AsyqSVe98C+"
    @"YD3ADcgtO1r61j278b7rrvv6VYJRfb5rgLvBf6H8L9wvkNeievh9/O2OpePXy+v1HJs5MBd3bqxdMOe0CgVchbOCEVmElRoCQjVaWByC0mJPe/839f4OGanz0tS7JMj2SLDtkAVG+ju7u/"
    @"5jw8ZtP73tjnu+IoDXS9eA1SDWANfg/6y8R/tvyPNKun6ORx1Px9fj6fHrmRNzY446X+aODWnyGbZyHwo4C3cFOys1BIRqNARCN5ggDnW33377pwTsI32y+JMmknVLmu4KQ8PO9oNPrn/"
    @"prwSTeukalASpBiwBrAGtInC+vEY/z+m/Ls/L6e5ndBwdV4/DMfX4zEXnVc9cmbMrFNiUJh/CWbgLhwUbLTWU33DdWgUIAJgKBJeGgtKivX/079mEkiZitcoVgkZZ/"
    @"CO4CLInnn7hu4JHvXQCUM/cBKaKggauioEKwLnyHvpn8n25PIb7p+U1evh1/tbP6Tg6LuLBsfS4mmEwJ50fc61n7ioU2IRtafIl3IXDgoWVGgLCiTRXHILS4h9Wr/60/"
    @"Oryh2nJHkjFm9r6C6XET55+4fsCaL10FYawKKggELAEr4qBBjuBf06+c3MT7WfL81Jd38ejft4VEYSDY3FMzTRUMMJiEQgFtmjpgY1pKTtyWcSBD+"
    @"GyYBVVasjL1mZDAHFwBSKXPfSOP8A+98yQrDskvLd2j2Z37JF1BukbNzW+lF94LCUMYUGAgCoIBLYKwFnynL4030l3y+n6fv28jqeiocfTTEMFo6hQYBO2qZ3YnHS/"
    @"Yh8cbhcuC+6WRQgIlbawOATZw9+sWrVcVsA/7JPbhyWZRGxt3tMui5AiDA2N7VP3/eOPbxAAo4RBswUVBgIzLAgazAQ3IsBXkOlnOJ1fri6nu5/"
    @"RcRiTsfU4iIYrGMxJhULLkBkZBTZiKzZjOxgk2cdwGC7DacEnKosgBqwVQSAsEGQPi9u7k5898H2IXS19+axh+3MXXPC5S8V2XXjU9QUVBrd8IO3XLEGzAxUEDWwVgdPlvfTTIjq/"
    @"FuX2qPfo53U8HR/RcAXDFQs3q4gUCmzduGn7c4gEGIBFokWCLEI4nccbjtsWbAFhthYWhyB7WLly5dLeoQO/SHL20NE7IRudMtntu7v+97GfPf9tAWo2YQhnC26WQNASwBrMGuga/"
    @"Jy1wh2SRvXw+/" @"hbx9Fx9Tgck2O7YuEKBXPW9YpIocB2MAALMEmqSARZhHAabgsmYArXTSQEhFItLBBB9tDcMfiXSV57aM+MF0qKO7977+"
    @"8JQCoOpONcGSCYKCUILlcY3GzBFQUNXALZDXBXACDkXLo7hjs2x9LjIhgqFm5W4ZYf2KKLmtiIrcFVDzDQkgNsEisSkkXAbbEb7MDVBEJAKNUQCL3PQ5A9yN+nZQb3j/"
    @"PNuCQSpa1nLBCHLW83d13++c9fLva6VyYoJ9w1Bi0lVBh0PUGzBQLUFQUNZhUCCBjueh1+tsfw5/"
    @"hbx9XjqGCoWLhCwVx1vUKFwl2jwNbC+gRYgAklBxgl0fcBp4XbYjd+i8oi5GVrikBk9rB9T8839KvcSSOJXqnYvHX39gsvvPRzAgTi4GYNrDMQRGQNBFWUMESJggauG9RhAVC8K30Mj+"
    @"MeQ4+"
    @"LYITFQjOKsFBgmwoFmVIhmwATsEEkkniFg23ncBuOi92WRQgIpVpk9tA9MLU1idmDlhWvvdn4ioDilhSaNZCCEzhkDdTxusagpYQrDHoGJ0A1YN1ALiUC8pGyWqkx3GPp8ZmLzgux0KxCh"
    @"UJLD2zDRmzVskOziaDkACNEIonlBtyG42K7ZRECQrGm5INoEAxiLX5s7QsXyt2MjnNHoyRlDyy+QfhXN+1YL3YiDlyh4MzpioObNRBMKgyk7VpGgJOetTUwNVgVU/dR3l7V5o6tz/"
    @"X4Oh+"
    @"dH3NVoXBLD2wjMyJDwmZXJMAEbFaAFZglbeEyf7eu43Bd7LQsQkCIapBLxQFCQaTTWrqH7k9a9sDlO1boJXXeJja64kB6rSWFmzXoOgNBpWeZsDBoUGqQ6qN8ZF6bHlcfdV6IRVgosAWb9"
    @"KoHGZKbTYCFlhyBSIAZ2CXtEigch+tir/oXrMAM/MAy1c0lE6AE2YM8nt4ztP/"
    @"dJAkEG4B2Nvdmt2xv6Vmx4rJLxEbNHMLiwBmVMyviQEoOccJZgxJISaQ41gKh3LnwPCwUbjaBbdiIrZpNaMkxTSTADOzAMEmbqeA4XBf7NTsEH/"
    @"WvYikvpbMpAJBIs4fFW97efV1GSose2ZqalN7UNpDd1th+4Gtfu/4KsdUVB9LqqJIiKmtQ4tSiMIQZrL7Vx2JC4WYTKhJuyVHIJMAODMEyKbzADrgO5wVAPREQC66Pw9im5m/"
    @"IAxAQXwXitPbe0bV8hz4pJGiR7xm809T1y5W33XmN2Kni4O5t0KsUmjXo2YRyS0uKYuIgb6nppgKhvnb97WYT2KzZRNS6RLAmAYZgCaZJ4Qdch/"
    @"Niv5UZDpWVOEoYyLL4yiuvPLNn6OB7SckgOvomuZSVffix9X8u9hUTB2pwFQctKXwXBsfVwVP1dzGh4Ozplhxg4mYSCGogEmAJpmCbBJHIcf3ge3BfbLTFSgGBpkSZlj1s2dH8de4RIHWZ"
    @"952bonDfg1c2vbNe7FVxIGXWskIvYbriMFvWAHY+"
    @"NxUKTgx6ciB71GwiLBJgpFc4CuUGmIItGCeBK3Ae7outlkUICDRXIILsQV47vb13WMqLZAjEXrnD89bGttGLLrr8YrGNs58rDpwdw5lDlDhoQPGYlObaVI5IuJlEIBJgCrZgnASBgPNwXx"
    @"ys5SUxoWVlknxfFoeVIJBDzx6kVku6Bvf9exIyiE65Db3cFOVX3/"
    @"7eD78odqk4sDKvC5LFxAFSuMRQrOTlRDW1i0cVCewulkmoSBSuboAtGIO17yIB5+G+2M86jJYZxAbYKFbyNB3NJQUgBHsfXtrY8LtsiuIylu+9qbU/"
    @"++KrWx8U29g+zSYoiM2OwVKZgwpDmkih5MdmFYpSIqFbs4Mdl2AM1r7zRS/dEgOCQ+rLDFcgCuWF/"
    @"ErTj5IgEGwL3rqjbd+yZcvYDKU7JFUcWKGPWnNIozgIFEErVyT06gZYsmh5PhiDNZj7LhJwnxgQu1JdZrhkmFZedGTGm+TeD947mpuePPrE+"
    @"lvE0ZQWejmTDUC6CYo0Us8Sbq2ZpsxBIJjWXF4UyyR0nwRYstAbXNkAazD3XSDgPjEgdqW6zHCzh0J5ccsttyzPDO0/"
    @"5nsGwZnszYbmFnGyrju4VywgONuL3TMEGGj2oEEiL6Wyqf0qEO4JBMzADgxnXNkAc9+zCLhPDBALYqOeQML8kH8lu7kCUSgvNr+950bfxYEzGPXwj/"
    @"75oevFhbru4C5KmjjMzu1yRMLdI8HazvlgnoS1CGKAWBCb3JOIewKZHUGP3+E63z07LJFfHfoX3wWCbxu++XZzp/"
    @"hHSwvOBFpa6LoDK9QsyobPDGBjLYeAyxOCA6zALLjSJY9gSbmm39sISg2wxwc+"
    @"lxrEALEgtqWyzFDHu04nlTqjo3e81XeB2C3fEXjk8advFnt0vwMEJh0mLXbXHUwcBJBZmnLFLTeCq13yObDUUkPXI84De3zgu0AQC2If2Wa4zFBM5F/JbBioDqe8wOGnX3rppUvlxhn/"
    @"47NAyPy5cjEq9mhpoVctSIfDpYWbMibe6WL/XJriEuYMWYSuR2ipAdZBqYEP8IWvIkEMEAvERN5OYsRdyAaPxLZIZz/"
    @"7yptf8tWhOm9ui7b22VfvFM+52QNpsJUWc6ezioSeVEqVGiwGn4cP8IX6xddHYkLsSdU6hOtsdTQp1JJtTR3fYydctyzy+drlewH/"
    @"fcklV7LvgTMZC5NaWripYvhMkOizgWBQjebyhsxLM8+gNJW/tdQA83PxAb7wlUfMm1ggJsSecFmKUCoe8jRZTQ2bsf6wt3NkHd/"
    @"K89WpnXKnqNe37n5F3BWVPbhnAYQx0U6OibLKHbADQ0RCSw13wTLIIvAFPvGVT8QCMSE2uicX7CZ2FAt5mqyGYZoq6lkgqCXb+yY6fBaI5q6R7EOPP/WHYl+p7EEdbAJROa81KJQ/"
    @"YKkLlgTRtCwCX+ATnwWCmBC7sI0YScU6RFggCmeAroGpD30WiB17M++LE2fLHlB/"
    @"EwcBYY4tLBIlswh84rNAEBOCE9mRm4G6HJojjLX7MRUI1F+du+T+VQ9e6qsjmbc4MvvK5h1Pik2VZA+166XanplyiEApmUXgE3zjM7eIDbGz2H6I2vZUhbNz1d917JKX3njnep+"
    @"d2CZbq9c8to6db9S/7qYoV/mx2bKHCkkT8fYwj/REA9bT1iLwCb7xmVvEhtiVioXKosq/"
    @"5Z3Wu7oH5OqFp31P+9Cvli9fzs7J8L6H8CYXFYgI3ttLFSBQlEsyRmFfBD7BN77yinkTG2JT1EJl4rjkOtVdoDyzcU9mtc9OfHtXF7vewuVFsbQQHKydGAJgqHwiM9MsAsynLVbiG5+"
    @"5RWyITboOkeiFSnUotaM6NEgLd7cPbOyR+wqy+83H/uob2x8Wm7S84AymDmURFlsTvbAk9i1EK8onmQw+CLZf4xsfOcWciQliQ2xJBZ+iHBooflv3WLevAtEpd1V+7Mln/"
    @"1icqOUFZ7BUpIRi50I2l0/umhbY4wPu2rUc3+AjH0WCmCA28va4GWkiTzjqUNeZgUCIA9/10YHMmfsPfOtbd/"
    @"yWOFF3TqL2rjOxV+tFMLBWHQTA0uWUZqVgjw+C+0XgG3zkK7+IDbEFwcMud01LOSUv+9/CzqSW0m2yS+W3Fv/"
    @"LVwc2dwz9p9ii5YV+74LSKdH1Yo1QUgVCy1YwD8pWecQXQZmBj3zlF7EhdlAyhbNSFQgw8L6pQOBIN4M4Y8WKFct8dR7z3rk3kxGbtLyIciQ2q/3eO7LGDFBcZ/BK5okvgjIDH/"
    @"nMMWJEbAkLRKJ4hSNRPNeRKP0Z9957/yVsZvG1NzS2s4ik5YWmgro4aeWFgBNjU4GAW2Dtlhn4Iigz8JGv/"
    @"GLexIjYgkBoZoqtxJJmEfLU7+YKhDoxSAXXPL7+d3x23qaGpjXimmKboxLlxBqlYFFuyXyDMgMf+cwxYkRsSfSVjKJOXP/ca7/vs/"
    @"NefK3hh45AuCqPEJpACAgxtzC3dB0CXwQCgY985hgxIrakUyCef/mtG3x23jMvbbpVnKc/hJPoOjHmQJ/"
    @"r8AgE3S1fCwvg8voyfOQzx4gRsSN1AhFc4tzwWsPNPjvvJ+s23AgJpev6Q9SlKAhsLR4EVCB0HYIMAh8E/"
    @"JLHZfjIZ44RI2KH8kvXtxKVneJEdaCuQahA3OKz8x596jnSP71zFDapA90FSnnZWowIFOWXHPNsfOQzx0Qg+AGmsEAkil+uA6cp/GtvNt7hs/NWP/"
    @"yzr0BC6aSArkAkSuHFtlpuyi8wd09A+ORsfOQzx4gRsUMFIipDrWXflDU3dSCqN00gXt20/c6ufrnM6Wl/6NG114pN7gYpzSBMIMqiRlXepPxyBSK4SoZv8JGv/"
    @"GLexIjYYQLhoxNNIKoS4Cc6iAnEiSK4gJ/HeepAN4NgxX9pQjII3UGZ2I0sC8ifcg6t/"
    @"CKDUI7hi4BjCckglGNRJQb2e9tUIFznYWQSBcJ1npUY80fZKIEocCzBAgHHNL7mD+0qH0kNSKRAPPzE018WvKLUPRHOqzIX4hquJMfwkY/"
    @"lq845vwaRWI6VdJ7vJYYJRFwxX9G4JTlmAlERlvP+5pLOe1lWaDtlpdbXvtoyiHknVMQBS3IMH/nKL+ZNjIjN6cwgcgKxTwTCz24CERGu8/" @"9SGQLhJ7+"
    @"ICxMIT8UB55UQCP0qLuS1Fi8CKhC6W1f32gQL4bkMwgQiXhfMfXR1XuQiZYIzCBOIuXOm0k8qx0wgKkWuBt6vzosUiA1vNNzla3lRZgZRAy5IxRTgWSIFghgR29K5BmECkYrgnQ8jTSDmA"
    @"+UYjmEZRAyg2pAzEDCBmAGJHy+"
    @"YQPjhJ99naQLhqQdLC8RGWYPokxVmT3sZVzE8dZt30y4tEJ7yi7jYIDEi3kjpGoQJhHeRWKMTNoGoUcfMNi3LIGZDyP5fDQRMIKqB4gKMYQKxAKCn8JAmEJ46fVaB6JA6y9duaxA1w8qSA"
    @"uErv5h36tcgfHaeCYQJRNz8NYGwDKJmoszjiVgG4anzrMTw1HGeTdsEwjOH6XRNIBQJe4wTAROIONGNcWwTiBjBtaELCJhAFKDw64kJhF/"
    @"+8nW2JhCeeq4MgZiUy5x+9tVPPFnsprV6PwhP3ebdtEsIxJNf9pVfzNuuYngqDjjPBKJmhMQEomZcUdlEZs8geiV78LSvftgyiMroENu7iwuE+"
    @"MhXfjFvyyA8FQecZwIRW8BXOrAJRKWI1cj7LYOoEUckfBomEJ46eFaBaJczsa/dMoiaYWVJgfCVX8w79SWGz84zgTCBiJu/"
    @"JhCWQdRMlHk8EcsgPHWelRieOs6zaZtAeOYwna4JhCJhj3EiYAIRJ7oxjm0CESO4NnQBAROIAhR+"
    @"PTGB8Mtfvs7WBMJTz5lAeOo4z6ZtAuGZw3S6JhCKhD3GiYAJRJzoxjh2WgWCHyu2b3TGSCxnaBWHyB+IZq9K3HsV4hzf9kF4vA/iiSc3uF/3Pl1Iu1h6nXRXIFQk7fGkk+LCADEGc7DHB/"
    @"jiDOlL8VGcARz32CYQGdlq7WHnZ9HWPvPytULCs6SfKV0F4lR5fop0FQnIaz1eDNzsQQUCn5yFj/"
    @"CVjxxjzmkQCFV3gobgKaj7xs277moTEHzsnX1T8pui1n3BwEeOMWdiRGJGf5uT2AmfgMjKvG1MXgWC9E8FIlD3zQ277yJFa8tMeNfbZc7MPXe3In9//Cfu33VY2PHzXwT0kF/"
    @"EBPwiRiRu3CyVGAqXsfKSny0sEIX076139t7c3jveC4F8FAibs3+i7pvPiA1ihFiR8HfL2EQIhC5IkUEE5cXKlSuXtnQOfr9ncOrfegb3Zzv7AcDPDMI3stl8/"
    @"RM0YoMYIVaIGWKHGJJ40jKD2NI4k6d+NJ3wtOyhtWf07szQ/l90IwzBopF/"
    @"DrMgM58tBAcoZ4kZYocYIpZECsJZhMZdzaqETlAfg7WH3a19V2eGDwyYMFhwLURwJemY04RCYorYEjXQq2Uad/"
    @"pYU0Khk+IRYTj5pptWndrVv2+NpEefyKOVEp4ulCUpwJJiC6UHMZWPrTXEmsadPLqxKH8ufHMnFGQN2/"
    @"d2r+genOruHpgKVvmT4hizw7KgWuIAV9CIMWKNmBMpiMomFlQhVByCrIEJ7m0bulaU7YOu/"
    @"inLGixrsCtUMXMgl01MkU18QOw5IkFManzOu0jogXksiENr98iNstZwjAWVWlJam4ud+ZPOgfwi5jFisIhIEKvz0sLiQFqzqDUz+qfdA/"
    @"uPmzhYMCY9GGvVvkAkJAaJRWIy391MInaRiBKHU1q6hr8ptdAntunJxKFWgyct8yIGiUViUgTC/" @"U6QG7vyr3iaHgRVQqFO2dGS+ZKsNxzr6N2Xbe2ZsG4YGAcWmAPEIjFJbBKj+"
    @"Vh1Mwl5qfpthji88Pq2Czv7pz5AtUwcTByNA7XDAWKS2CRGRQpiF4kZ4vDVr952mihVt4lD7ZDCAtR84XKA2CRGidU4RcIVBy0t6lq6xh7kq758JdWdlD03khoHaoMDxCYxSqyKQLhbs6t"
    @"Wbqg48FgQhy272q/p6Jv6hGuwRobaIIP5wfwQxQFilFglZkMi4ca2/"
    @"GtuTQdRcQi+lSl7wnustDBCRhHSXqs9XhCrxKxIgH4LNLzjck7qECUOdbua+29liyeXjVp7xq0bBsaBGucAsUrMEruiBJQaVVm0DAtE3U13331mW8/"
    @"Ee7nSwsTBBNI44AsHiFlilxjOi8QJZRFhcQhKi6aW/"
    @"u8E2UONK6YvTrN5msDMFwfaJGaJXWJYBOKESw0Ewl13qLv66quXtGXGj7T3WmkxX06145iAVJMDxC4xTCzns4hwqSEvz97C2QM1y6mNe3vlHpJyAMserOY2DnjJAWKXGCaWiWnp7qVPjft"
    @"ZFSKcPTDQ4ubu0R229mBntGqe0Wys+ecTMUwsE9PSo0qNaQLxfwAAAP//"
    @"zftEEQAAE5VJREFU7ZxpjF1lGcfZ96UogoAFgolBEjHwpfoBY8CVGP1glA9qwgdjicQlBDSAC0tLF0pnOjOlywDtdBs6UNrSTmc6nU6nhQKlrdTGEGIUDWoUCWKRfXF8/"
    @"ufeZ3jv6X1n6b22ve/5neTpubdz5845z/v//97nXe494ojK40h7qjjK4miLYy2Ou23GjHMHtu9922Jo8+O/JcgBGmhQDcjD8rI8LW+XPS6vy/Puf3tY/QjhcIy9RG9w/"
    @"KM9267dAhwwRYOagk6tslOXl+VpebvscXk9hIQ93f9welRUD/ayE/sGd63c8gTVA0KrFBr5aMx8yMvytLxtMeYqIgSEiKLhhQhzUv9je15ieNGYYsDEtFteA/"
    @"KyPC1vlz0ur8vzIw4zqg0vTpjduuhT+T/Ac0SHBhpfA/"
    @"K2QeEEC1URow4zQkB49XDiiod7v40YGl8MtCFtmNeAvG1g0DBDIwV5PjoPER1erO7e+guGF4grLy6eN7Ym5Gl526AwpmFGWD2o1FDJodLj5PWbdiwDEI0tBsxM++U1IE/L2/"
    @"J42esjDjNCQKjU0ItVepzcM7DzsQGWt1jiRANJaUCelrfl8bLX5fnoMCMPCI1JBIhTNm7ZtTdPH57TI6GBxteAvC2Pl70+4jyEA0LDC5+g1Njk1E1bn/kjYmh8MdCGtGFeA/"
    @"K2PG4Rm4ewH32wvVJroOH8QxkQu1/c/PgeK68IcoAGUtLApq27XzTPOyDC5c6K/"
    @"RCqHhRa4ggBobHJaX3bfrOv3+BAkAM0kJYG5G153KLaRKVzoeLDWQ6IbIIyA8RWA8RjlhiCHKCBpDTQZ94OACHPV13J8PkHVRA+/5BNUNrz0/"
    @"UmwAFAooH0NFAGxOnm8xEnKgEEPWNSPSMwGxvMAATGx/" @"hoIKqBegBiAkOMsdGYXos8NZoGyoCYcCBDDC1xalwCIOiBoj1QoxmC662EeA4Q4V6Iig9tVZuDyPZAAIjKhCIw8pGSBgJA+"
    @"F6IqrspAQRVAlVCATUwXkDst82aCoIeM6Uek3up1PMIgBALfDfl8EYpAFHAXgTTVJqmSPkAEBieoQMaiGqgLoDYaDspN1mSCXKABtLSgLytaQSL/"
    @"CTl2IcYACItUWBy2tM1ACCofKj80EBUA/"
    @"UBxKANMbYZdQlygAaS0sBG83btQwwAkZQoAD2dnWugToDYbRXEM2YSghyggZQ0sHFwdz0qCACRkii4FyDnGgAQVD1UfmggqgEAgTii4vBehHNxKwoAASAABBqIagBAII6oOKgcils5eNsD"
    @"CAABINBAVAN1AUSvLYX0WZIJcoAG0tKAvF3zRikAkZYoMDnt6RoAEFQ+VH5oIKoBAIE4ouLwXoRzcSuK+gFiqyWRIAdoICkNAAgEnZSg6aTq21EDCAABINBAVAMAAnFExUFvXN/"
    @"euBHzCSAABIBAA1ENAAjEERVHI/Z4XHN9qx4AASAABBqIaqBOgNi1z74/3/4IQQ7QQEoa6B3cVftW6x57E/" @"v22yGCHKCBtDQgb9f8WQwAkZYoMDnt6RoAEFQ+"
    @"VH5oIKoBAIE4ouLwXoRzcSsKAAEgAAQaiGoAQCCOqDioHIpbOXjb1wcQA7aKMWjJJMgBGkhKAz3m7dpXMQBEUqIA9HR2rgEAQY8H3NBAVAMAAnFExeG9COfiVhQAAkAACDQQ1QCAQBxRcV"
    @"A5FLdy8LYHEAACQKCBqAbqAogNtorRa0kmyAEaSEsD8nbNy5wAIi1RYHLa0zUAIKh8qPzQQFQDAAJxRMXhvQjn4lYUAAJAAAg0ENVAnQCx0yYpd9sfIcgBGkhJAxsGdtZjkhJApCQK7gXI"
    @"uQbqA4jNBogtllSCHKCBpDSwwbxd+"
    @"zIngEhKFICezs41ACDo8YAbGohqAEAgjqg4vBfhXNyKAkAACACBBqIaABCIIyoOKofiVg7e9nUBRLdNUvaY0QhygAbS0oC8XfMqBoBISxSYnPZ0DQAIKh8qPzQQ1QCAQBxRcXgvwrm4FQW"
    @"AABAAAg1ENQAgEEdUHFQOxa0cvO0BBIAAEGggqgEAgTii4vBehHNxKwkAASAABBqIaqA+"
    @"gOi3jVIDRlmCHKCBpDTQbd6ufaMUgEhKFICezs41ACDo8YAbGohqoE6AeNqGGLvsjxDkAA2kpIHu/"
    @"qfrMcQAECmJgnsBcq4BAEHVQ+WHBqIaqAsg1lsZYt+fP0SQAzSQlgbk7ZpXMQBEWqLA5LSnawBAUPlQ+"
    @"aGBqAYABOKIisN7Ec7FrSgABIAAEGggqgEAgTii4qByKG7l4G0PIAAEgEADUQ0ACMQRFYf3IpyLW0kACAABINBAVAMAAnFExUHlUNzKwdseQAAIAIEGohqoDyA22VbrzUZbghyggaQ0sN6"
    @"8XftWawCRlCgAPZ2dawBA0OMBNzQQ1QCAQBxRcXgvwrm4FUVdALHOhhjdZjSCHKCBtDQgb9c8BwEg0hIFJqc9XQMAgsqHyg8NRDUAIBBHVBzei3AubkUBIAAEgEADUQ3UCRA7bJJyp/"
    @"0RghyggZQ0sG7TjnpMUgKIlETBvQA51wCAoOqh8kMDUQ0ACMQRFYf3IpyLW1EACAABINBAVAMAAnFExUHlUNzKwdseQAAIAIEGohoAEIgjKg7vRTgXt5IAEAACQKCBqAbqAohH+"
    @"55ioxQii4qMCqRxKxB5u+ZPc67tfXJfd78lgSAHaCApDcjbNQNiTc/"
    @"2F4EDgEQD6WlA3q4ZEKu6H39+vfUcBDlAA2lpQN6uGRBdawf3IIy0hEF70p7SgLw9HkAcbS8+1uJ4i5MsTrWYsOKR/m0ICkGhgfQ0IG/L42Wvy/"
    @"PyvhggFhxlcaRF9o+eVAXEAyu6OxBHeuKgTWlTedt8f8CAOEW/PG/" @"Rql8jJsSEBtLTgLxdBoS8Pq4K4kT7hQwQs1oWf2ftxqeYpGSiFg0kpAF5Wt4OACHPj3mI4YA4ffKPfv5pm+"
    @"1EHAmJg2ogvWpgvG0qT8vbBoXTy8XAgQHCfvlDnasGWOoEEHQSCWlAnpa3DwQQx9kvDVcQepP2JWs77AsuEUhCAhlvj8Pr06k65GV5ugog5P0RVzGOsRc4IE62x6fpTWa1LrrukQ3bAQSA"
    @"QAMJaEBelqfl7bLH5XUVBfK+GLDfMqfWO/WfDogT7LED4owrr7z6ghWPbH6TXiSdXoS2LG5bysvytHn8DAsVAfK6PB8CQkxQZP/"
    @"ogfZChIDwzVJ6kzOtJFnHakZxRQVQ0mh7eVhelqct5G1tiJTXQ0D4JqkMEPaz4c1SAsR+uynt/"
    @"z48Zea933pwzRZKzARKTMyehtkPpB3lYXlZnraotklKDHBA2MPS4RVEuJuyYqLSXnbWA53dz1JFFFdcByJIfufw0Yu8Kw/LyxZjWsEo4eGDCsIBsd9Epb3wIzOa7/"
    @"shVcTh0+CYj7YYjwbkXXlYXi4DwucffIJyvxWMEBCqIqITlfazM+04d1Fn959W9zzBUIOhBhpoIA3Is/KuPCwvW4xpgtJelx2Cgw8zovMQ9pqzRKDlqzaZOLQvgiAHaKARNCDPlqsHDS/"
    @"GMv8gHlQcDggfZmhfdn4eQqXJR9uXrunvenQQQABINNAAGpBX5Vl518KHF6NusbbXVhwhIMLlTq2RailEJYnIc/bk62/"
    @"8bMfKnndW92jzFD0IOUADh6sG5FF5VZ6Vd8se9uXNavsf9lvBsN/JDgHCIREOM6pWEXPmLZmy9KGNQ/"
    @"bNuEACSKKBw1AD8qY8Kq+at0erHuR5h4M4UPVwQPgwQ6sZFbsq7bkmOESic9qXrNmy/"
    @"OFNQ+v6dgyt12c1CHKABg4LDciT8qY8Kq+WPRubnIyuXtjvVRwOCJEkrCK000rfD6Fxi9ZPs7mIr3z9m5cu6tzw1+Wr+q2S2DGkD4EQ5AANHFoNyIvypLwpj5pfq1UP8rR//"
    @"4NXD15B2I+qHwKEQyKsIjTMGP5shj0WiTQbes71N9xy1eIHe161/d1AAkDSQRxiDQgO8qI8KW/Ko2Wv5quH2N4H+X/EIwTEaFWEhhrn3nDznV+zC3oTSBzanoOeu9j5D+Dwpjwpb1rIo/"
    @"mVi3z1oGJg1OrBXpMdsSrC5yKyb7u2V2pFQ1WEypfzbp3S9D1BYpmNe7SlE7EWW6y0/8Ftf3lO3pMH5UV5suzN/L6HcOUiP/"
    @"cwavVg75kdsSrCVzS0RVNLJcNDDXt83q23z7zGLvC1JV0bh/SVVojk4IqEfBcz3/KaPCfvyYPyokW1oYXmEeXhcO5hXNWD/W525KsIDTV8RSM/"
    @"YSlIZKsadj5v8k9+9kX7Ou0XOlb2Dq1cO8i8xCEekwKNdKGhIYU8Jq/Jc/KePGgRrlqEH8qSd8OPdYdwGHP1YO+RHXlIqBxxSPjmKX1c1Fc1svkIe/6xSVdcdcnCxav7dOEqe/"
    @"QNNgg1XaHStge/beUpeUsek9fkOXnPIj/v4B/prsvQwt5/+MgDIpywDFc1dAGaj9BEyDAk7PHEmc0P3K4xkW6ic/XA0JreJwEFFQUaqEED8pC8JE/JW/KYvGaRh4N/"
    @"3iL8xGZsaDHu6sH+XnZUg4SqiPBzGrqAapBQqTPx+9f99PP2DTbbdUMOCn2yjF7n4Pc65Lxxcy7POBjkI3lK3pLHLOS1sHII4RDOO8i76uhrGlrY71ccMUhoLOPzET5pGVYSGgdlkLDz+"
    @"bdNm/" @"OD+5ete85BofLooXXbmKOooTfB8I1r+LG0neYY5BEfSsg78pC8JE9ZOBx8zkFVvDzoH+UWHOo672Dvt98RAkJrpaJPOB8RQiJfSTgkVP7ohi741V0tk+"
    @"0m9zoodNaur65HtzJXASwKX1lqbkFekCdCj8gz8o48VPaSPBVOSDoc5EF12Hk4hEuavufhgIcW9v4VRwgJAcLnI3zSMg8JTVz6Eqj2Saj8Ga4m7PEFk39889Ut7Q+223bQl8NE6LGIqW+/"
    @"0Qztw+sfI8hBshqQxqX1sEpwP8gb8oi8Is9YhFWDPCVvaZ+"
    @"DvCbPjQSHug8t7O9VHLVAwpdBdVMin0qjrKKw8wU33TrlmuZ5S2cv6Fj9hCXnPU8Q59K8DXkoTB7ekwfkBXlC3iiHg8EnIn1IcdjAwa4zO0aDhK9uaLelPtjl3yGh8sd3XQ4POyZMmHDhx"
    @"IkTP37RxRd/4rLLJl0yadIVl15x5Zcvv/GWqd+d1nT/"
    @"HbNaO+a23te1fu59XRta21f2WvS1tHf1ty1cOWCPB1vbu7a1tXdtt8dPtrZ37jDa7mxZ+OBuiz0We1sWdv5uzoLOZ+csWPGcxe+b56/4Q/P8zuebFqz4c9O85S9Y/KVp3rK/"
    @"Nd+77O9Nc5f+Y/a9S/9p8dLstiUvN81d8q97SvHKPW1L/q2Y1daxb1br4n2z2ha/qri7dfF/7m5RLHrN4vWZLQ+8PnNOFm/Y+Y0Zc+5/"
    @"c0azx31vTW+2aMri7elN7W9PU8xWLHxHcZfF1HsUCxTvTp01/90pd2fxnp0t5r1350zFvWG8f8eMubloe/+O6W3v316K/"
    @"9rZorUU0+xscVtFtAzdNs3iriD0PIsPXqvfy8LfK3tfvXfp790xw865a7Frfb/yeudl91G6H93T/Ow+s/vN7ruUB89Jlh/Lk/"
    @"JluVNkebRvR3prOLeWZ+W7HFk7qD1K7WLtY+3kbVZqv4593qbWxq+ondXeaves/"
    @"U0H0kOmC9NHSSemF9ON9CMdSU8lXXU+K52V9Jbpbrd0KD1KlyV9dm2TXqVb6dce91n0Stf3tHXMn958/9Sbfjnt2i9d/Y1Jn/vCVy+TDy6//DOflC/OPv/"
    @"8i8wnAoUPJ7xq8CGFPCavyXNaypQHfa+DhhX/98rB/kbFMRIkfHVDF6oxkK9wqPwJJzB1kwKFDz28qvDKYri6sNc4Rf18of0fQQ4aVQOu4/"
    @"xZmvdKQT7wOQZ5RF6RZ1SJOxjyQwqHgzyoof8hgYP93ezTnnlI+"
    @"LyELkwXGK5whNWEz03kKwolIYRFCAwlKwSHJ5JzSVDkoTHz4Lr2szQfQiEEg6pvecbnGsKqIZyMdDh41ZBfzpRvD9oRQsJXN/"
    @"KTlz7k8GrChx1hRaGbFxlFyLCyCKGh8oogBylqwHUeAsGrBQeDqm95xsHgqxReNcSGFHVfrbBrGNcxGiTCaiIcdggUmnHVDXtVITp6ZSFghNAI4aFyiyAHjawB17OfXe8OBHkhrBbkFXkm"
    @"BIPvb/" @"CqIT+kOORwsOvNDoeEzl5J+"
    @"JBDF50fdjgoNPTQDedhIVoqPEmCRhhKIkEOGlUDoZb12HXuuvdKIYSCvKIqXN4ZCQyHdEhh1xY98pBwUPiQIw8KDT10o9VgEQJDFYZXGUocQQ5S0oDrW2cHglcKeSj46kRYMYxUNciTh91"
    @"xIKDIw0KkVHK8wlCV4ZWGkkeQgxQ04LrW2fUu7YeVgryRBBjsPoaPGCR82OFVhYYe4fBDEy2eEFUXXmGoyvDwBHIuCYk8NGYeXM9+dr27/uUFhVcL8olXC/"
    @"kVinCu4bCsGuzaqx7VQOFDD4eFbtqHHw4LJUXhSQrB4Qnk/AFMyUXj5iLUuOs+DwUHgzzjcwzyUcOCwa694ghBocd+c37DDguvLPLQ8ErDz2EieVyCKXlonDy4jvNn170DIawUQjDk/"
    @"VRhtkZ+kr8xB4WfqwFDSfIIE8jjUuVFHho3D67r8Bx6wH3h57x/GpkFo157/mb13BMRnsOE8bhUYpKH9PIQat4fV/PIqMZK8QXVEpH/P08a5+ogJS+NmZe8zqs9P6Se/"
    @"x8e68Zku4r22wAAAABJRU5ErkJggg==";
/// WebView
NSString *const STImageResourceWebViewBackNormalBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAwAAAAMAgGAAAAVwL5hwAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG"
    @"9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1w"
    @"LmlpZDozOENEOTM3NTFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDozOENEOTM3NjFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjM4Q0Q5MzczMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOj"
    @"M4Q0Q5Mzc0MUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"DgvIFgAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAI9SURBVO3Z3YrTQBQH8E7Szkwm0+"
    @"xNIYU2aTrpNKLJtNMIsigiCD6JLyCCvoEXgoigLAguiIKoiIgsflyIiD6FLKIrri6K34JX641CCFPr5RzcA73//aEk53/"
    @"SaOzMfzyu6y6laXpnNpv9lFLed103gIQPsix7Vpbl9p9fGIbHQeAdx+FZlj2t4suy3O52uycg4P0sy57U8XmeP282mx3b8Ww8Hj824NcxxhEE/KM6viiKFxjjgfV4KeVDA/"
    @"4lxjixHU+llA8M+FeEEGE1HiFEpJT3DPgNQsjIdjwejUZrdbxS6jUhRELA3zXg31BKM+vxaZreNuDfUkp32Y5vpWl6q46fTCbvKKW7bcc3hRA3Dfgtz/Ny2/"
    @"GuEOLGHLyyHj8cDq8Z8O89z5tAwF814D8wxrT1+CRJLtfx0+n0I2OstH4rTpJk1YD/xBjbazseDQaDSya87/v7rC8kvV7vlAH/2ff9ZRB1UGv9tYb/"
    @"wjnfD6aMK6U2qwG01j+CIDgCJkAYhsfqfyGt9fd2u30YTIh+v396TohDkEKcMYXgnB8EEyKKorOGEN845wegZEBRFJ0zPFZBPZlQHMfn57zYliGFWAH7dq6sGBeh7keL9iQQG+"
    @"pfN1UQHWFRVwDR0mpt7QrInvwPfXnL87w9YEIIIa6DvBUtuhkppTatv9ZVQhivdr/vpWMoIebdTe2/WFdDmC7XRVFstFqtLqQQa4bPrCfBdAmEEK5/"
    @"vel0OkcbkMZxHBrH8Uqe5+txHF9ACOHGzgCbXxSIEHEAAAAASUVORK5CYII=";

NSString *const STImageResourceWebViewBackHighlightedBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAwAAAAMAgGAAAAVwL5hwAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG"
    @"9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1w"
    @"LmlpZDo2RTRGN0NGMjFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo2RTUxNERENDFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZFNEY3Q0YwMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOj"
    @"ZFNEY3Q0YxMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"QntQdQAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAKaSURBVO3ZWUhUURzH8e91NnPFcjJTczQ1M1tESyrNIChoQQxJyhZSU3yMym3U1MGwyMKybMFM2pWIiGh5EC"
    @"snLYkWC4IYogwtKdqDnuxJGA5X5vUc8g/3/fODyz3n978wMf/x+HsTeHIr11/"
    @"X87ctj9t+FgKUwftZCOgsxulqYHTsKUhnlxJ4HzN+HcX0uONdDYwWZlCiAt73chH3RXzXHt4E+RIsNX6SCZ+LhXSL+O4SXKGBREiPv7CDLhF/"
    @"r5S3YUFESo9vz+euiH9QxrvwIGxS4y1GvM/mc0fE95TzPmIy0VLjzUYsbXncEvHOcgYjpxAjNd5kwNy6nZsi/"
    @"mEFH2zBxEqPP72NGyK+185QtJVZ0uNPbOGaiH9UyceZVuKlxhsNmI5v5qqIf1zJp5ipJEiNN3hhbM6lU8T3VzESF0Ki7HjD0Vw69PDxocyTHt+0kUsi/kk1n2eHMl96/"
    @"KEczuvgvyRMJ0l6/MENtIv4p3v5mhhGstR4Lw2v/dmcEfHPavg2N5wUqfGahtaQTasefkEEqdIXkt2r2Cfin9fyPWkGi5WogwN1/HTHv6jlR3IkS5Up4312ht0DvHLwJz2WlcoEyEtjp/"
    @"gKvXTwe0kMK5QJUbaaA3ohUqNZrkyIijU06oVYFMUyZUJUruWwGGKgjl8pNtKUCKBpaNXraBJDKPVl0jS0mkya9Q42Zc4GTUNzZNGi7Ok8FqJ+"
    @"PaeUvB95uicpcUP1dFNVoiN46gpKtDT3EI05nFOyJ3vqy/1VjMSGMEeZEEc2cUXJXZGnnVGfnWHpt3VjM97WrtfOUFQwcUqEGG9vqsTG2j2E3ubaWc6g1Z9pyoTQ+3dQlEGpMl3CZMAs/"
    @"r3JWUgBKo3FiLcji5buEly1mRwzGTAzMYrNP9e4TuEAAAAASUVORK5CYII=";

NSString *const STImageResourceWebViewBackDisabledBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAwAAAAMAgGAAAAVwL5hwAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG"
    @"9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1w"
    @"LmlpZDo2RTQ4QjJFRTFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo2RTQ4QjJFRjFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZFNDhCMkVDMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOj"
    @"ZFNDhCMkVEMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"STrnagAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAALCSURBVO3Z32tSYRgHcF/"
    @"1eKadLQQv2kSOE01RSdRcSBJB0H+w+zH0D8hYDQebMDiwXGu6RJEdoZm4ioiIqET8xTkbm5vbYDcyRtRiqyj6HXS1bhrIyxnevg/tgXP/+cLhvO/3OTLZyfzH093dfTqVSj3d3t7+w/"
    @"P8S4ZhesDgGYbpWVxcFFut1uHRMzw8fB0EXqPRMIVCQWjHt1qtw2AweIN4vFqtPpXP5+s4vlgs7mi1Wh3peE0ul6vi+FKptNvb22sgHr+wsFDG8eVy+"
    @"XVfXx9LPD6bzRZxfKVSeaPX641E42ma7uJ5/hWOr1arbw0Gg4lovEqloufn51/g+FqttseyrJloPEVRqkwm8xzH1+v1dyzLWojHp9PpZzheEIT9/v5+K/"
    @"H4ZDL5BMeLovjeZDLZiMYrlUpqbm7uMY5fWlr6YDab7UTjFQqFMpFIPMLxy8vLHy0Wi5N0vCIejz+Uwlut1nPE42dmZgo4fmVl5ZPNZnMRj5+enr6P41dXVz/"
    @"b7XY38fipqal7OL7RaHxxOBxeovFyuVzOcVwWx6+trX11Op3nicYjhBDHcbwU3uVyXSC+kITDYQ7Hr6+vf3O73X4QdXBjY+NHO77ZbH73eDwXwZRxURQP2gNsbW39DgQCV8EEGBoauoa/"
    @"Qpubm7/8fv8VMCFGRkZuSYUYGBi4DCbE6OjobakQPp/"
    @"vEpgQkUjkjkSIn16vNwAiAEIIjY2NxfEQoL5MCCE0Pj5+V+pgA3M2IIRQNBpNgT2dj0JMTk5mQN6POt2TQNxQO91UQXSETl0BREtrDxGLxXIge3KnvvxvU+"
    @"EAE2J2dvYByF1Rp52RKIoHxG/rjua4rZ0gCPtGo/EsiBDH7U1BbKzbQ0htrmu12p5OpzsDJoTUv4NQKHQTTJegKEqF/70ZHBwMyiANTdNd0Wg0VSqVdicmJpIURalkJwNs/gJke/"
    @"7nAAAAAElFTkSuQmCC";

NSString *const STImageResourceWebViewForwardNormalBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAwAAAAMAgGAAAAVwL5hwAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG"
    @"9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1w"
    @"LmlpZDozOENEOTM3OTFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDozOENEOTM3QTFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjM4Q0Q5Mzc3MUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOj"
    @"M4Q0Q5Mzc4MUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"QKcqDgAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAIKSURBVO3Z72vTQBzH8XSD0l6vl6YN7aVJ2rRPLIE0aYII/"
    @"piKw21s7IFjeyAMxD0dDBE2FMZEUCqICoqC6GAwEPxHfCr+CQ72YJVtblM2HNueTBjh7uGgH+hBn79fkF4u31OU3gJbqqqOeJ63FgTBVqFQuAcH8DzvZxRFx6e/"
    @"I13XZ6AAvu93zgD+I+7DAHRdn4mi6OgsIgzDQ6jHqVgszkoQ00iIOREin8/fhUGUSqUHsf/"
    @"DcRiGh5qmTSEhHkoQkzAIzvmCAPFP07QJJMRjAeIgl8vdgUEYhrEoQYzDIMrl8hMRQlXVUSTEUwliBAZhmuZzAWKfMTaEhHgRR7Rarb+"
    @"MsdswCMuyXgoQf7LZ7C0YhG3bryWIGyiGhG3bb0QISukAEuKtALFHKb0Kg6hUKu/jiCAIdiilV2AQ1Wr1owCxnUqlLiAhPsURpmm2MeoTif56vf41DuCcz0PE12q1L/F43/c3ksmkjRC/"
    @"KojvpNPpZtfHO46zIoj/RQgJuv3J6XMcZ1mw82wSQkKEHeezIH6LEBLB7vmZTOYiwlv3gyT+EkL8O0H8b0rpZdST5y7EeceyrFeSE+c15K+v6wjfv21J/"
    @"E2E+GeieMbYIOQMCGbyYBjGkmT2M4wQvwg7feOcP5LEj3V9/On9GO4EutlsrkPfAbiu+x32FkZRFIUQ0mo0Gt9c1/0BNfPvrXNaJyLfOiYAAAAASUVORK5CYII=";

NSString *const STImageResourceWebViewForwardHighlightedBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAwAAAAMAgGAAAAVwL5hwAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG"
    @"9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1w"
    @"LmlpZDo2RTUxNERENzFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo2RTUxNEREODFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZFNTE0REQ1MUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOj"
    @"ZFNTE0REQ2MUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"NmJJiAAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAJWSURBVO3ZXUuTYRjA8f/"
    @"0A3TUgZqYZs2WjaWuxaau5WqurZVvi4pENIpktMRQlq3NLd0EscIoiAqCIIgOo09QeJClaVGEnhR0kJG9UxTakSA3t4fBc4HXJ/j/"
    @"4OHmfq4bVkfYuM34H8d4N5FgvqmSNnGARzHezmZZnM2yOJNhIWynQxRgPM7cEmAJ0VJFuxhA2E7HTIaF5Yg3g/"
    @"wV9Tm1OonoEA0VHBWDaHMR1SFCNg6LQbRX07UcsIQIWAmLQRyroVuH2LuVFjGIE256NYg/"
    @"9eU0iUF0ejirIl4P8NtXTqMYRKSOuA7htRASg4h6SeoQnjICYhBdu0npEG4zfjGIMz4GVcSrC/"
    @"yq3YRPDKLXz5CKeJnmZ81G9ohBxAIMq4gXaX44S6kTgzgX5KIO4ShhpwiAyYQpvo9LOsT2YmrFIBIhRlXEdIrvVeupFoNIHeCqipjq52tlES4xiIFGrquIySSfS9ZiFoPINHFDRfT4yYoA"
    @"5OaQO3qEeyrguJseEfGXD3FXjX8S50PeGgoNHz9ykDtq/HicubI8rIaPHw5zW41/ep6Plnxsho7PMZEz1MwtNf5Zgk9bCqgw/"
    @"ImTbeamGj+RYL68gEqxZ751HXbDx6cbuKaLtxXiMHx8cj9X1Pjn/"
    @"XypKMIp8uY5neKbiPtOX5AR3Y3TXkyN2L8vRwluw8f3+Mnq4ndswGP4+G4fA7p4VylekTsgMZuHU14SK+x+6g0fv9IeVMT27aSHmC5+12aCho9vdRIRvYEe6+"
    @"O96DeAB1Emxb7CAFjy2Xa/k7GHp5kStfNfnf80/wC1XNd1AAAAAElFTkSuQmCC";

NSString *const STImageResourceWebViewForwardDisabledBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAwAAAAMAgGAAAAVwL5hwAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG"
    @"9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1w"
    @"LmlpZDo2RTRCOTFDOTFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo2RTRCOTFDQTFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZFNDhCMkYwMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOj"
    @"ZFNEI5MUM4MUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"XDpcAAAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAJ1SURBVO3ZW4sSYRjA8VE/"
    @"hRddeCUqZp7RxkktPFAmqHURJuIqiriIpomKJonDCmJJURAVBEHYnfgFFAQVzyky3hZ00S5tZ4pitytheXm7DOaBfT7B/"
    @"wfDzDvPSxCnA2woirJ3u913o9Ho0OVy+cEBOp3O281mc7zZbI4ZhjnyeDw7oACDwWB/C9gi3G53AAzA4/HsMAxzdBKxXq//"
    @"gHqcvF5vDIdwOp03wSB8Pl8ch3A4HDfAIPx+f+IkYIuw2+"
    @"3XwSACgcAtHMJms10DgwiFQhkM4rfVanWDQUQikRyKWK1WvywWiwsMIhqNFnAIs9l8FQxid3e3hEMYjcbLYBDxePwuDkFRlB0MIplM0ihiuVz+"
    @"JEnSCgaRTqerKGKxWPwgSdICBpHJZGooYj6ff9fpdBfBIHK53D0cQqPRGEEAOBwOJ5/"
    @"P38ch1Go1BQZRKBQeYBDflEolCQZRKpUeoYjpdPpFoVCcB4Mol8tPUMR4PP4kEAiEYBCVSuUpikilUnsgADwej9doNF6jgGAweBtEfL1ef4XG9/v9D3w+/"
    @"wzr42u12ks0fjAY7AuFwrOsj69Wqy/" @"Q+OFweCASic6xOp7L5XJpmn6Oxo9Go48SiUTB+jcOTdPPMPGHEolECfadL5VK1RC+uo9x8TKZTMv6+GKx+BCNn0wmn+"
    @"VyuR7kyXM2m30Fcd7JZrN13IlTpVIZwP59aTSaC6yPT6VSe7h4rVZrYn18IpGo4OL1ev0lkDsgMJuHWCx2B7f7MRgMNtbH/"
    @"2sPCmL7Fg6Hs7h4k8l0hfXxXq83BnoD3ev13oO+A2i1WnOwtzAEQRBisVjebDb77Xb7Daid/+n8p/kLTr7GbAAAAABJRU5ErkJggg==";

NSString *const STImageResourceWebViewRefreshNormalBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAwAAAAMAgGAAAAVwL5hwAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG"
    @"9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1w"
    @"LmlpZDo2RTQ0OEJCRTFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo2RTQ0OEJCRjFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZFNDQ4QkJDMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOj"
    @"ZFNDQ4QkJEMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"cDYE2gAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAQ2SURBVO1azWsbRxTXrDfa9cwy0o7WYDRo8X4hVyvv7IwIIS70GqeHUppC4jiXlhDoX9B/"
    @"wNjnQFP32kNNnEMJvsU69dRrckl6qQ89GOzWgQRi49SmvcggJitLu/qygx/s7e2891u9eR+/"
    @"p1zuUj4CURQFYYxvUEpXPM97GobhS8bYvhDiSAhxxBjbD8Pwped5TymlKxjjBUVR0Lj9BhjjBdd1NzjnB41G4780D+f8wHXdDYzxQi6XAyP1vFgsflWr1Z6ndbrTU6vVnheLxS/"
    @"PslkoFG5GUbQTRdFOoVC4mclxTdO8IAi2BuW4/"
    @"ARBsKVpmpdkO4qinVO9KIp2UjtvmubtOI7fdDJer9e3bdteI4QsQQiFqqolAEAeAJBXVbUEIRSEkCXbttfq9fp2p3PiOH5DCLkj25f1UsV6uVxeTjImhDh2HGfdMIz5lHEMDMOYdxxnXQh"
    @"xnHR2uVxebj8zKwBg2/YPHX7upq7rs/3eJ13XZ4MgaCbZsG37p1MQmQBQSlcTssehZVkPBp0YLMt6wDk/"
    @"lO1RSlczASCE3JFfYoztIYSuDiu7IYSuMsb2ZLuEkMVUADRN8+QLyxjb03W9OuwUret6VQYRx/"
    @"HbVADkVMk5f4cQujaqOoMQusY5f3dWyj2zSMnKlmXdH7ST+XzerlQqD8vl8rJhGJ8BACakO3E/CwAgV9ggCJrD+Mq1Wu2FFKL7rus+JoTcU1V1qhUJzVQAMMY3JMUTXdc/"
    @"GUbz16Uqn8zOzv5eqVQeNhqNk54BuK77uF3JcZz1YcV5EATP+mk7Er+KnIcNw/h0mC341NTUd0EQPEvK/6kByOFTr9e3R9XmKooCi8XiF7Ztr83Nzf2VCQCldEUq4z+Oa9CYnJycm56e/"
    @"r5arf4mhPg3oaDufvCS7/ubUvVbOg/T3sTEhGma5u2ZmZmfGWN7jLG/"
    @"TdP8+gPFMAxftQOAEMYXaq5ljP3TDkBV1dKFAiCEOGoHAADIXwK4DKEUcuEvcUIavXuhAJynQpZJMMYLUivx58gZsw4tfqFQ+"
    @"FxRFNi1uRplM9erGIYxfzoVep73axJnNJZ2uldxHGe93SfXdTd6DiMhxPEguJ9+OCOZ+OrGiwJ51BvWSNnj0LMlkcAvut7LpKG+"
    @"VCp9M2rnLcv6VvbDNM1bmZCfB1olVSS0iK2354nY0jTNT3VQB2pxF0LYGJbzEMIGY2w3iVrMWp2TyN2DcZC7mavgGfT61iBCStf1aqetTzu93heIbgsOhND1tIYQQtcdx/"
    @"ml1wVH30IIudvDiukRIWQRQshbK6YrAIArrRUTJ4Qs2rb9qIcV03AIBU3T/LP4ygEs+Zqps00WMU3zllyx+12z9lykBtnmthbdT7JQg5zzQ9d1n4xl0Z3QihsY4wVK6Yrv+5thGL6K4/"
    @"i1EOK9EOJ9HMevwzD8w/f9TUrpauuvBkbuUj4C+R9mIUg0AAAAAElFTkSuQmCC";

NSString *const STImageResourceWebViewRefreshHighlightedBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAwAAAAMAgGAAAAVwL5hwAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG"
    @"9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1w"
    @"LmlpZDo2RTUxNEREQjFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo2RTUxNEREQzFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZFNTE0REQ5MUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOj"
    @"ZFNTE0RERBMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"YGfYjAAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAR5SURBVO2aXUibZxTHf+/SCMbCsoWMoW3CVJJOrRqtdnUQd7GZuNavtZsm2SqboWW7Efwaw4/"
    @"OJSa7GMzada5eVaGuljGKtBfqjYOBoLPUUa1V6sUuBN0sdFDFTtluJoS3b2LefKnFA89Vzvuc8384z3nO+Z/AvjwHooojwWzA0mDBc+UsN4fqmJlsY2W2g/"
    @"XZDtYn21gZqmPmylluNljwmA1YVXEk7KjTgoBgNmDtsjMw7WL14df8K2dNu1jtsjNgNmAVBISYOm/J4L1btdyV67S/"
    @"dauWu++kUx7IZqGR4rFmFseaWSw0UhyS4zoNKb01DEfKcfHqrWFYpyFFyvZYM4tbemPNLMp2/"
    @"mQmlVPtPPZnfLSJBVcF3WUmHOlJ5KhVaJQK4pQK4tQqNOlJ5JSZcLgq6B5tYsHfPlPtPD6VRZXYvlhPVqzXFeGWMjbnYaPTRn+OngI5cSwICDl6Cjpt9M952JDau64It++eIQEQBIQvy/"
    @"hOykCfk5EULUfCvU8pWo70ORmRsuGu4IctECEBaLTiFX8442atKp9zkU4MVfmcm3GzJrbXaMUbEoBTWVSJP5poZTnzEHnRym6Zh8ibaGVZbLckC5ssADoNKeILO9HKcrIWY7RTdLIWoxjE"
    @"7+38LQuAOFXec/Ek+zDHY/XOZB/m+D0XTwKl3ICPlFi5Mg9npJ1MVKNrK+FiXRHu/NcwK15A4ft7ZR5O2QAEAUH8wvY5GYnGKd+uZcrXzmQbK112rpeb+PDlBLQA/"
    @"rKTXwBmAxZfpXkvm6mv8Ho0ir9ApzvvZfOnzxhrK+HivJfNoAF02bnuq9Rpoz9acX61hqFwyg7JUxHn4Vw9b0azBHe8wadXaxiSyv+yAYjDZ7SJhViVufFKVG+nUeqqoPvXL/"
    @"gjJAANFjy+Cl+V8/1O9RrGVzl6vpDPfzzPL3Me/hE7P97C0jMf9VQz6KtUZsKxG7q9F+N56WQmld98QO9EK8u/tfJn8VHOPKM4XM99XwBpiWTvqb52so2/"
    @"fAGoVWj2FIDZDtZ9ASgVxO0D2A8hGbLnL7E4jZZmY99TAHbTQxaSmA1YRaXEw5gzZn5K/LeMvBuvRLVtcRXLYi5YydFTsNUVdn/"
    @"Ez1Kc0Y6U08FKp41+X5+67AwEHUZzHjYiwf2EwxmJia+AvKggIIhbvWi1lMGImFy4XcvUtvdSqqk/"
    @"c4yPY+38+8f4ROyHNYPTISHfDbSKrEjQaUgRk0k7TWzpNaTK2kiKWhxvYSkjidxoOZ+RRO54C0tS1GJIG0qRu9MuVneC3A35FfRHr/"
    @"fWMByJkErWYvQ39fGl18MCsd2Aw6TjhFxDJh0nvq3iWrADjrClNBv7diOm9jIul2RhS0vEpFahOaBAeUCBUq1Ck5aIqSQLW3sZl7cbMUWNUNBrSA3EV4a7+"
    @"pyMyM42oYg1g9PiFzvcMWvQj1Qky1yzAeslBzdCoQZn3KxdcnBjRwbdEqX4QbMBa4MFT081g8P13L9zgUcPOnj6oIOndy7waKSe2Z5qBhuteP//"
    @"q8FB9uU5kP8AtSDirAAAAABJRU5ErkJggg==";

NSString *const STImageResourceWebViewRefreshDisabledBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAAwAAAAMAgGAAAAVwL5hwAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG"
    @"9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1w"
    @"LmlpZDo2RTRCOTFDRDFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo2RTRCOTFDRTFEOEYxMUUzQUIyQkUwRDg0N0Y4QzY4RiI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjZFNEI5MUNCMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOj"
    @"ZFNEI5MUNDMUQ4RjExRTNBQjJCRTBEODQ3RjhDNjhGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"LtfwQwAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAATDSURBVO1ZT2giZxR3iAZ0lzBN6CWHEXVJNg5iJ0tYNnUMhBBddUKpFddNLy2bhd5kPPQgRAMhIRBRIev0ol"
    @"JIw7qHsnrQbBIhhcFJlAQVHZtDc+ghkLRZ2MImZJvQngLD7Ggc/yZLHnynefO99/t43/ve+z2B4FY+ARGLxXc0Go0Ox/G5QCDwOh6P0+l0+rhQKJwVCoWzdDp9HI/"
    @"H6UAg8BrH8TkURfVisfhOW50GAABAUVTv8/" @"kiuVzuZG9v7z8+K5fLnfh8vgiKonoAAICWOj8+"
    @"Pv51NBrN8nW63IpGo9mxsbGvKtnUarWPSZI8IEnyQKvVPq7JcQiCFKFQaK1RjrNXKBRagyBIwWWbJMmDSz2SJA94O28wGKw7OzvvyhlPJpP7brebwDBsEobhQRAEe0QiUadIJOoEQbAHhu"
    @"FBDMMm3W43kUwm98vts7Oz885oND5h22fr8Yp1u90+y2WMpulzj8ezgiDIMJ84BgAAQBBk2OPxrNA0fc61t91un2XuWRMAAACA6enpJS4D4XB4XS6X36/"
    @"3Psnl8vvhcHidy8bMzMxPlyBqAuBwOObZP+bz+VOr1fq80YnBarU+z+fzp2x7DodjviYARqPxCfsniqKOVCrVULOym0qlGqIo6oht12Qy2XgBgCBIwb6wFEUdyWSy/"
    @"manaJlM1s8Gsbu7+"
    @"w8vAOxUmc1m36vV6oetemfUavXDbDb7vlLKrfhIsZUtFsuzRjvZ29sLOZ1Ov91unx0aGtJ2dHR0ML9bLJZnvAEAAACwX9hwOLzejFOOxWI5pp10On3s9XpfTkxMfNvd3f25QCAQlMtOZQF"
    @"oNBodU6lUKl0oFIqBZhR/lU63VCpdRCIRyul0+kul0kXVALxe70umksfjWWlWnAeDwTf1lB2cp8LOw4ODg182swS32Ww/BIPBN1z5nzcAdvgkk8n9VpW5YrFYMjo6OuF2u4nNzc0/"
    @"awKA4/gcU8Htdgfa1Wv09fWppqamflxeXv6Npul/"
    @"2c6nUqnDj34iCCLGVMIwbPI6dHtdXV2fGQwG68LCws8URR1tbW39pdPpvvlIMZFIlJgABgYGvrhRfe329vbfTAAgCPbcKACFQuGMCUAkEnXeArgNIR5y4y8xRxp9eqMAXKeHrCZBUVTPBL"
    @"CxsfFHyxmzMiX+yMiIQSwWS64srlpZzFUrCIIMX3aFS0tLv3JxRm0pp6sVj8ezwvTJ5/"
    @"NFqg4jmqbPG8H91MMZsYmvirwoAAAAu9VrVktZjbDJhVgslrvyXnI19Waz+btWO282m79n+6HT6cw1Ib8OtAqvSIAgSMEmk9pNbEml0nu8NuKiFlOp1CEMww+"
    @"a5TwMww9SqdQhF7VY04Zc5G4ulztpB7lb8ytYjl4PhUJrjQgpmUzWX27qw6TX6wJRxYDjEV9DCII8Wlxc/"
    @"KXaAUfdgmHY06tGTC6X64XJZLIplUoEBMEeoVAoEgqFIhAEe5RKJWIymWwul+vFVSOmphEKUqn0XiW+st4VDofXeWebWkSn05nZL3a9Y9aqH6lGlrkoiur9fv+rWqjBfD5/"
    @"6vf7X7Vl0M0WiURyF0VRPY7jcwRBxBKJRCmTybwtFosfisXih0wm83Z1dfV3giBiDodjHkVRvUQiuSu4lU9A/geZtJedAAAAAElFTkSuQmCC";

NSString *const STImageResourcePaySelectedBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAA8AAAAPAgGAAAAOvzZcgAAA2ZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxucz"
    @"p4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDpERjBFNDI4QUQxMDhFMzExOUY0MzlDMTc5OTYwQjk4RiIgeG1w"
    @"TU06RG9jdW1lbnRJRD0ieG1wLmRpZDoxOUQ3RTg5NDBFNDQxMUUzOTI2QUE5MTMzQ0U1ODk4MiIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDoxOUQ3RTg5MzBFNDQxMUUzOTI2QUE5MT"
    @"MzQ0U1ODk4MiIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ1M2IChXaW5kb3dzKSI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOkZGNTE5QzQzMzcwRUUzMTE4RjhDRTYyNUVDNzhDMTQ4IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOk"
    @"RGMEU0MjhBRDEwOEUzMTE5RjQzOUMxNzk5NjBCOThGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+MS+"
    @"FLgAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAOxSURBVO2azUsbQRjGnzXgRSlUC9JWStVstX5X0IIiamvM2uJH1ZoYBfXiRSESsBBXG6NxAyLiwYMgXgTReBDJU"
    @"f8JvRgvnryJ0SjGkKCmhxJhjVqTnd1EOw+8t9mZ+"
    @"SUzz7zzAVBRUVFRUVE9TyUmJYHVaqERBHRubMC4uwve7YbV74fV7wfvdsO4u4vOjQ1oBAEsxyExKelpQTIMA5bjoHM4YLm4gC0YjCgsFxfQORxgOQ4Mw8Q3bG5LCwa2tyOGvC8Gtrfxsbk"
    @"5/kBTsrLQs7lJDPR29GxuIiUrKz5gC3Q6jJ6eygYbitHTUxTq9bGdq7U2m+ygt6PWZlN+bjMMg4a5OcVhQ9E0P68sdJ3dHjPYUNTZ7crAFur1MYcNRWFHh/"
    @"xurIRBPdrIzs7kdW85lx4pS5ZsSUW8wYYit6WFvCuTzKBIx8DODlnXZrXamMFMXF2hmudRYTJh/PLy3nIsx5ED1q2uxgR2/PISn7q7b/pRYTLdW1a3ukpuizfm88UEtshgEPWlmufvLT/"
    @"m85HZWsZiOFsDARS0t4v6UdrXh4nr6we/Y7Va6cAaQVAW1u8Pc93P/f3/"
    @"hLUFg9AIgnTgLqdTUdichgZR++WDg4+CtQWD6HI6pQMbXS5FYMd8vjCnrRwaiqgOo8slHXj46Eh2WIvXC7VGI2q3ymyOuJ7hoyPpwFa/"
    @"X1bY3+fnyKypEbX5xWKJekooCjxxfY2vViu46elHJ//vKyvFJjk5KckDFB3SVWbzzXffZ2cfLDvi8eBdebmoLe3UlKTRQmRIR2JaOY2Novy7eWHhbtiTE7wtLRWV/"
    @"TYzI3l6EDGtSJYli9crGqIJKhV+Li+H/QtvSkpkOS4isixFmniMeDxILysTQRvW12ELBmE+PMTr4mIRbNP8PDEDJJJ4sBwXccO82420goKbOlSJiWhbWkJafr7oh/"
    @"ixuEjU8YnsmKLdPJgPD/EqO/vOOhNUKrQtLRFPXIjdS0W7Pfx1cICUzMww2PaVFeLruc7hIHgAEMWwDoVpfx8v0tNv5uxtEyMVH+rrCR/x7OxE3ZnBvT28zMggPmdlO+KJ90O8vNbW/"
    @"+eYtndrS+aD+LOzuDqIT1Wr6VULvUyj16X0QvzxKjIYFHvyUNTZGR/vPFLVavRubcm69MjuxtEor7VVUkZ217Ml2ZIK0g/"
    @"T9GtrUe2yxnw+6NfWnsbDtLCtZXIyWI6DRhDQ5XTC6HKBPz6GNRCANRAAf3yMwb09dDmdqLPb/z49TE4GFRUVFRUV1bPUH1rap/EAAAAASUVORK5CYII=";

NSString *const STImageResourcePayDeselectedBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/AAAADUlIRFIAAAA8AAAAPAgGAAAAOvzZcgAAA2ZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/"
    @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxucz"
    @"p4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDpERjBFNDI4QUQxMDhFMzExOUY0MzlDMTc5OTYwQjk4RiIgeG1w"
    @"TU06RG9jdW1lbnRJRD0ieG1wLmRpZDpFRUE4OTJDNzBFNDMxMUUzQTdBREJFMkEyRkRFOUZBQiIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpFRUE4OTJDNjBFNDMxMUUzQTdBREJFMk"
    @"EyRkRFOUZBQiIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ1M2IChXaW5kb3dzKSI+"
    @"IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjAxNTI5QzQzMzcwRUUzMTE4RjhDRTYyNUVDNzhDMTQ4IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOk"
    @"RGMEU0MjhBRDEwOEUzMTE5RjQzOUMxNzk5NjBCOThGIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+"
    @"EyqaRQAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAASMSURBVO1aTUgbaRh2YDKStCZoWZJD0kvGW9tzZrYoZqxJl6Usmj93D5r20DVjcivY7rXOVEOoYKCeElCUZo"
    @"RaAlJMdJPWiU7ebvjaS91roaftD7SwFbuVby+dJZTdBZtJHOs8MMd533mY73vf5/1pazNgwIABAwYMfJUwm80nWI/HF4/FhNvJ5P17kvSsvL7+GiqVPahU9srr66/vSdKz28nk/"
    @"XgsJrAM4zebzSeOFEmCIAiWYfxTgpBTNjffIwB8kEfZ3Hw/JQg5lmH8BEEQuibL9fUN5hYXn6gfX1OU/"
    @"YVstprgebGf4wLdNH3OZrV2URTVTlFUu81q7eqm6XOc1zuU4HlxPpNRaoqyr76fW1x80tfb+4PuiDqdTved2dmC+qFrq6svrkSjNxwOx+"
    @"mD2nI4HKevRKM31lZXX6j27szOFpxOp1sXZH0XLoTlUuktAsClQuFlJBQapyiqvVG7FEW1R0Kh8VKh8BIBYLlUeusbGIgc6l3lx8Zuqn8hKYrLNpvtlNZ+bDbbqaQoLqt++LGxmy2/"
    @"2wRBEBPXrqU/3dOPkVAo3myfkVBo/Lft7b8QAP5lYmKupaQTPC+qEbW3p+dSq/z2nD///fajR38iAJzgebE1d3ZgIKL+2VaSVdHb03OppigfEQD2+3zDTY/GaoAaDocThxU/"
    @"hsPhBALAcrn8rqnRW00906IoHXZ2mBZFSU1ZTRMVCACXi8VXnZ2d3xw2YZvV2vXr2tofCABzfX2DmkdlVUGFg0FeL4InMDj4MwLA0tLSU02jNuvx+"
    @"BAAfpDPPydJ0qQXwiRJmh7k888RAGYZxq+Z4VuTk3cRAL48Onpdb7L28ujodQSAb01O3tWsxKvK8m5NUfYddrtLb4Qddrurpij7VVne1aS0VI/"
    @"zQjZb1WuVtpDNVhEAZj0eX8PG4rGY0FJl04Dyi8diQsPGZlKpPALA/"
    @"RwX0Cvhfo4LIAA8k0rlGza2Ikk7CADTbvcZvRKm3e4zCACvSNJOw8bKxeIrBICbUfppWUKqoqhhY1Cp7CEAbDKZKL0SNplMFALAUKnsGYSNI20ErX9PS5zXO6RXwpzXO6RZWlKFhyZJ/"
    @"SgID5Zh/" @"AgAz2cyil4Jz2cyimYV07ErHo5KeTglCDntGgCfjrWeGwDfsuxFTVs80tLSUwSAQ4FATEctnqtNafG0tem8ideslKmnNu2UIOQQAJ5Lp4tNc+J0Ot1yufwOAeBWzJP+"
    @"C5FQKK424l0uF91UZ8dq1PK5sjkWwzQ1ah+rcalKun4gPi2KUlMG4lZrlzpHOrSBeD0u+nw/1q88hINBXquVh3AwyNevPHzn9/+kCwHgcrnouXS6WL/"
    @"UEh0ZmfiipRa73RUdGZmoX2qZS6eLTY/GX1qXqopMXVuaz2SUBM+LnNc71E3TZ60dHZ0kSZpIkjRZOzo6u2n67P+tLem5Dv/"
    @"nbrMM458WRakqy7sHXUyryvLutChKR2Ix7XNYLJaTLMP447GYMJNK5Vckaefhxsabx1tbHx5vbX14uLHxZmV5+feZVCqf4HmRZRi/"
    @"xWI52WbAgAEDBgwY+CrxN1asURgAAAAASUVORK5CYII=";

NSString *const STImageResourcePayPlatformAliBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/" @"AAAADUlIRFIAAABKAAAASggGAAAAHNDCcQAACklpQ0NQUGhvdG9zaG9wIElDQyBwcm9maWxlAACdU2dUU+"
    @"kWPffe9EJLiICUS29SFQggUkKLgBSRJiohCRBKiCGh2RVRwRFFRQQbyKCIA46OgIwVUSwMigrYB+Qhoo6Do4iKyvvhe6Nr1rz35s3+tdc+"
    @"56zznbPPB8AIDJZIM1E1gAypQh4R4IPHxMbh5C5AgQokcAAQCLNkIXP9IwEA+H48PCsiwAe+AAF40wsIAMBNm8AwHIf/"
    @"D+pCmVwBgIQBwHSROEsIgBQAQHqOQqYAQEYBgJ2YJlMAoAQAYMtjYuMAUC0AYCd/"
    @"5tMAgJ34mXsBAFuUIRUBoJEAIBNliEQAaDsArM9WikUAWDAAFGZLxDkA2C0AMElXZkgAsLcAwM4QC7IACAwAMFGIhSkABHsAYMgjI3gAhJkAFEbyVzzxK64Q5yoAAHiZsjy5JDlFgVsILX"
    @"EHV1cuHijOSRcrFDZhAmGaQC7CeZkZMoE0D+DzzAAAoJEVEeCD8/14zg6uzs42jrYOXy3qvwb/ImJi4/"
    @"7lz6twQAAA4XR+0f4sL7MagDsGgG3+oiXuBGheC6B194tmsg9AtQCg6dpX83D4fjw8RaGQudnZ5eTk2ErEQlthyld9/mfCX8BX/Wz5fjz89/"
    @"XgvuIkgTJdgUcE+ODCzPRMpRzPkgmEYtzmj0f8twv//B3TIsRJYrlYKhTjURJxjkSajPMypSKJQpIpxSXS/2Ti3yz7Az7fNQCwaj4Be5EtqF1jA/"
    @"ZLJxBYdMDi9wAA8rtvwdQoCAOAaIPhz3f/7z/9R6AlAIBmSZJxAABeRCQuVMqzP8cIAABEoIEqsEEb9MEYLMAGHMEF3MEL/GA2hEIkxMJCEEIKZIAccmAprIJCKIbNsB0qYC/"
    @"UQB00wFFohpNwDi7CVbgOPXAP+mEInsEovIEJBEHICBNhIdqIAWKKWCOOCBeZhfghwUgEEoskIMmIFFEiS5E1SDFSilQgVUgd8j1yAjmHXEa6kTvIADKC/"
    @"Ia8RzGUgbJRPdQMtUO5qDcahEaiC9BkdDGajxagm9BytBo9jDah59CraA/"
    @"ajz5DxzDA6BgHM8RsMC7Gw0KxOCwJk2PLsSKsDKvGGrBWrAO7ifVjz7F3BBKBRcAJNgR3QiBhHkFIWExYTthIqCAcJDQR2gk3CQOEUcInIpOoS7QmuhH5xBhiMjGHWEgsI9YSjxMvEHuIQ"
    @"8Q3JBKJQzInuZACSbGkVNIS0kbSblIj6SypmzRIGiOTydpka7IHOZQsICvIheSd5MPkM+"
    @"Qb5CHyWwqdYkBxpPhT4ihSympKGeUQ5TTlBmWYMkFVo5pS3aihVBE1j1pCraG2Uq9Rh6gTNHWaOc2DFklLpa2ildMaaBdo92mv6HS6Ed2VHk6X0FfSy+lH6JfoA/"
    @"R3DA2GFYPHiGcoGZsYBxhnGXcYr5hMphnTixnHVDA3MeuY55kPmW9VWCq2KnwVkcoKlUqVJpUbKi9Uqaqmqt6qC1XzVctUj6leU32uRlUzU+OpCdSWq1WqnVDrUxtTZ6k7qIeqZ6hvVD+"
    @"kfln9iQZZw0zDT0OkUaCxX+"
    @"O8xiALYxmzeCwhaw2rhnWBNcQmsc3ZfHYqu5j9HbuLPaqpoTlDM0ozV7NS85RmPwfjmHH4nHROCecop5fzforeFO8p4ikbpjRMuTFlXGuqlpeWWKtIq1GrR+"
    @"u9Nq7tp52mvUW7WfuBDkHHSidcJ0dnj84FnedT2VPdpwqnFk09OvWuLqprpRuhu0R3v26n7pievl6Ankxvp955vef6HH0v/"
    @"VT9bfqn9UcMWAazDCQG2wzOGDzFNXFvPB0vx9vxUUNdw0BDpWGVYZfhhJG50Tyj1UaNRg+MacZc4yTjbcZtxqMmBiYhJktN6k3umlJNuaYppjtMO0zHzczNos3WmTWbPTHXMueb55vXm9+"
    @"3YFp4Wiy2qLa4ZUmy5FqmWe62vG6FWjlZpVhVWl2zRq2drSXWu627pxGnuU6TTque1mfDsPG2ybaptxmw5dgG2662bbZ9YWdiF2e3xa7D7pO9k326fY39PQcNh9kOqx1aHX5ztHIUOlY63"
    @"prOnO4/fcX0lukvZ1jPEM/YM+O2E8spxGmdU5vTR2cXZ7lzg/" @"OIi4lLgssulz4umxvG3ci95Ep09XFd4XrS9Z2bs5vC7ajbr+427mnuh9yfzDSfKZ5ZM3PQw8hD4FHl0T8Ln5Uwa9+"
    @"sfk9DT4FntecjL2MvkVet17C3pXeq92HvFz72PnKf4z7jPDfeMt5ZX8w3wLfIt8tPw2+eX4XfQ38j/2T/ev/RAKeAJQFnA4mBQYFbAvv4enwhv44/"
    @"Ottl9rLZ7UGMoLlBFUGPgq2C5cGtIWjI7JCtIffnmM6RzmkOhVB+6NbQB2HmYYvDfgwnhYeFV4Y/jnCIWBrRMZc1d9HcQ3PfRPpElkTem2cxTzmvLUo1Kj6qLmo82je6NLo/"
    @"xi5mWczVWJ1YSWxLHDkuKq42bmy+3/zt84fineIL43sXmC/"
    @"IXXB5oc7C9IWnFqkuEiw6lkBMiE44lPBBECqoFowl8hN3JY4KecIdwmciL9E20YjYQ1wqHk7ySCpNepLskbw1eSTFM6Us5bmEJ6mQvEwNTN2bOp4WmnYgbTI9Or0xg5KRkHFCqiFNk7Zn6"
    @"mfmZnbLrGWFsv7Fbou3Lx6VB8lrs5CsBVktCrZCpuhUWijXKgeyZ2VXZr/Nico5lqueK83tzLPK25A3nO+f/"
    @"+0SwhLhkralhktXLR1Y5r2sajmyPHF52wrjFQUrhlYGrDy4irYqbdVPq+1Xl65+vSZ6TWuBXsHKgsG1AWvrC1UK5YV969zX7V1PWC9Z37Vh+oadGz4ViYquFNsXlxV/2CjceOUbh2/"
    @"Kv5nclLSpq8S5ZM9m0mbp5t4tnlsOlqqX5pcObg3Z2rQN31a07fX2Rdsvl80o27uDtkO5o788uLxlp8nOzTs/"
    @"VKRU9FT6VDbu0t21Ydf4btHuG3u89jTs1dtbvPf9Psm+21UBVU3VZtVl+0n7s/c/romq6fiW+21drU5tce3HA9ID/"
    @"QcjDrbXudTVHdI9VFKP1ivrRw7HH77+ne93LQ02DVWNnMbiI3BEeeTp9wnf9x4NOtp2jHus4QfTH3YdZx0vakKa8ppGm1Oa+1tiW7pPzD7R1ureevxH2x8PnDQ8WXlK81TJadrpgtOTZ/"
    @"LPjJ2VnX1+LvncYNuitnvnY87fag9v77oQdOHSRf+L5zu8O85c8rh08rLb5RNXuFearzpfbep06jz+k9NPx7ucu5quuVxrue56vbV7ZvfpG543zt30vXnxFv/"
    @"W1Z45Pd2983pv98X39d8W3X5yJ/3Oy7vZdyfurbxPvF/0QO1B2UPdh9U/W/7c2O/cf2rAd6Dz0dxH9waFg8/+kfWPD0MFj5mPy4YNhuueOD45OeI/cv3p/KdDz2TPJp4X/"
    @"qL+y64XFi9++NXr187RmNGhl/KXk79tfKX96sDrGa/bxsLGHr7JeDMxXvRW++3Bd9x3He+j3w9P5Hwgfyj/aPmx9VPQp/uTGZOT/" @"wTZH+4dAAAAIGNIUk0AAHolAACAgwAA+"
    @"f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAAAJcEhZcwAACxMAAAsTAQCanBgAAAAcaURPVAAAAAIAAAAAAAAAJQAAACgAAAAlAAAAJQAADCy+Ki0UAAAL+ElEQVTsmn1sFGd+"
    @"xzd1cRpyTavmwAZ8SU0KcWxDOQjYGGwwEPBLMJAzySX4Ba69NCe1yalHcgoVIsm9NE5s/"
    @"EKaSxsgcNWBsc2aJiGt+kebU5QWqShFUXvtNdzZ632b193Zl9ldE8Onf8zMMrveXa9tpP7Tkb56ZkfamZ3P/n7f5/vMrsPx/9v8tsLCwsK9e/"
    @"c++e677567du3amCiKk8FgELtCodCMCofDRCIRwuFwiuzHMr1P07TkqGlaynUDgUBSqqqmSFEUFEVBluUUSZI0TWNjY5FPP/"
    @"30v955551zLS0t+wsLCwtnBam5uXnf1atXv1BVNeVDpYOybsJSNlD5yg4pE6BckCxAdlCZ4IiimFVXrlz5orm5+YkZARUUFBQcO3asy/"
    @"4B8oE0HzjZYKUDs0PLB1auasoFSxRFjh492lVQUFCQFdSxY8e6FEUhF6h8KygSieStbKCyVZcdVD6wZgvKgpURUktLS+tMkHKByuRBdwqWBSxbG862BfMBJYoiu3fvbp1m3J9//"
    @"rk73Rgz+VM+kOYCKpPh5/" @"Kt2bZfOrB8QF27ds2zYMGC2wbf2tp6QJbl5AVygbIDu1PVlA1UphkwV+vNxpsEQchLra2tbUlQp0+"
    @"fHs4X1EwVlX7z0Wg0p27dukWmzTqaSCSmtfxMFXUnQZ08eXIkCeqzzz4bT4c0k0fNBCkbmEgkgm6OANGojtvjxe8X8AsCfr+Azy/g8/nx+/"
    @"2Iskw0EiYc0ghkMfVcOWq+sK5evTqeBOX1ehNzrah8Qem6jq7rRHWdmK4zNTXFyPAwpaXLWbn8QSoffojKlaYefoiKlQ9R9NVFfP+"
    @"lFwEIa0ECIQ0tz4hwp0C53e7JJCjrpHYjnCkezLWiDFAxAL7zx53c7XDw6B8UsaZ0EV9fvpg1pYuS+7/rcHD4T581QWlo2uwgWaBEUUyOgiAkR7/"
    @"fn5eSoCRJIh1Wtqqab0Xpuk4sFgeg65WX2VFZzKHHa+ho2sjB5ho6mzYa+4/X8NjqEo6/dgSAkBbKWU25gma2KpozqGwVlcujMoXMXJDsoHp/"
    @"+BfsqFxGZ3M1HY3VtDdW0dawgfbGajqaNrKtcgndJihNC2UNnrNpufTWmhUo+7cw29abD6ieHxxhW/"
    @"kSOhqraWuo4sCuDcmxvbGarRXFvPnqyymgshl5poCZreXmXFGiKJLNp+Zq6HmBeu0I9Y8U09FggLL0zM71dDRtNEF93wAVygBqhvyU3nLp3uTz+"
    @"fJSCqh8fMoOKayFCGkaoZBGOBQiEg4nFY1EiEYj6KZiejRFibgBqvvV2xVlr6Zndq43Kqq8mJ5XjIoKhDS0QAAtECCYhKSgKgqKIqPIMookIUsSsiQiiSKiKCAKhvx+"
    @"H4Ig4DMBzQmUHdJMhh5QVcLhCHdi+0n3X1K3crHpTVUp7dfeWMWmFV/lJ2/"
    @"+iDu1qaqKx+OZX0Wlr4uytV80qiPLEpfev8TQyAiXnCOMOkcYHR3h0uhFLo1eZNQck7pkf+3EOerk8keXeem5QzQ9upyOpuppoDqaNtL0aCmHn+"
    @"vk8oeXcV4cwekcwXlxCOfFYZzOYS6ODDFiafhCUsPDgwwNDTI8NMjQ0HkGBy8weP4Cv75+nWAgMD9QVvtlmgGtSgoEAgBcv/4Fi+5byF0OB18pyKx7Cxws/"
    @"A1D9xak6p67HCwscFBbWcqhPZsNULs2cMCUUVHVfKtlEzWVpcY57nJwT9p50q+X6fhXChwscDi4y+Hg448/5hbg9Xrx+Xx4vd68lNJ66aCyteDUzVv8z/"
    @"XrbKoopfrB+6grX8bWihK2lC9LamtFCXUVy6gtX0ZduTlW3NaW8mXUlS/"
    @"hG5vLOdi8KcXILVBtDVUcfHwTe2or2VK2hO3lS6itWEpdeQl1FSXUli9jS4Vxra0VJdSZ1zK0NOXz1K5YxJqS+/jk5z9n6ib4fHMElQtSyvovECA+OYVr7Nc83/kN/"
    @"uypXXzv4F4OH9zL92wyXu9JOWbXiwf38sLBJ3h2z3a+uW0dz5jZKSUiNFTRtmMdzz5Rz3c7W3nJOmen7TqH9tmU+vrFbxk6fGgfL3bu5k/27+TqlSvEYpP4/"
    @"LfNfFagrFxhb0G7X1lTsNGCCqqqoOtREvEYsXiMeDxGLGaMlhKJeKriMUOJGPF4glvA22/8kO2rlibN3N56bY1VbF9VwttvvMJNQNdjxGIRYrpOPGasF3U9elu2WTYajRCJhIlEw0TM/"
    @"WhEwyuIuD3upPd4vV48Hs+MSoLy+/" @"0poLL5lVFZMmogQERPEI1Poscn0ROGYokbxCZvEJv8kripxI0pJr9MVeJL4yHKwOvH2F5elBI4k2ZuBs6+"
    @"Hx8FIBJLENFjRPQY4ahOKKKjhaNo4SjBcIRgKExACxHQQqhBDSWoIQeCyIEgkhJEVYP4/QJejztvQDOCskf/" @"lFa0L2usXGUqZH9EbA+jZsayh9JoNArAm6++"
    @"TH35ksyzngmq65gROAOqSiAtgStpC99pS5S02S29peYNyh79Z8pXwQxhNNsPD3ZZS5itZcUZK6o9DZSqqma4zPyIN9eiN73VrNHtds8OlJVULWD2uJ/"
    @"L4BVZRlaUuQfOnh+zecX9WQJnNTUr7uevun8wr5ApCALuiYnkTVtw3G533soJyoKVKzKEQhpyIMDfnjlN9xtd9Pf3cWKgjxMD/"
    @"QwM9HPC0okB3jrRz1sn+jlxop+3BgZ479QpvtP5FC3VK+loqKItrao6GqtoqX6Y5zr3c/LkSQZ6++nr66W/r5e+vuP09vbQd9xQb083vcd7OH68h+M93XT3dNPd9TrdXV384pe/"
    @"JBAITKuSOYOylKmy7LDsBh+PxwgENcpLl+FwOLjb4eC3bFpo092mCk3d7XCwufL3+faeumTr3a6sDbQ3VvHtPXXUVDzAAoeDe8zz3Ju2b2lhmhwOBw8s/"
    @"j3GJlyEwhG8aZAmJiZmD8oyt2ywMhm9rMhEojqqrLK79uusXvybbH2kmC1lRWwtK6aurIjah4uoKyumrsw4nq768iXsWFXCY39YwmOrDW1ftZTtq5ayY3UJu1aXUF+"
    @"xhLpHiqgvK6L2EfO8ZYvZu7mSb+7YwP76dezfZujJbevYX7+OJ7etZfOKRfzo5e8yxU0m3B48aTc/MTGRt5KgLIObqbJSc5aEGtBQZIUPnRcY+elf88HgWT64cJYPL5zlg6GzvH/"
    @"BeG3ozDRdOn8a589O4fzZaUbPvcfo+fdwnjvN6LlTOM+dYvTcaf5u8Izx/sEzfHjhLKPnz/CPH1zktRc62VtTZj4VNR78HWyuSWrXmq8x9NO/YQpwT7jmDCkjqNnCsmbF/4vthT/aT/"
    @"P65YanNRhqazAmgqe3rWVf3Sr+/eq/EorGcLtdc4aUAip9mszWinZo9inZL4j4BMkGU0CSrDYVkSQRWZaQJDnlmCVRsv9COz0H+f0+/H4fPq+HqZs3+Ye/v0zVisW0m0sfa/"
    @"nzzK71HGioYveGh3i+cz+qquIX/LgmJnCbN+1yuWal8fHxVFBzgWXdnCKLyLJZabKMKCtIsmw8RJNlJFlBkhVUVURVRCRZSpUkJyUmwQkIooAgiKYEfF4fAK8dPcLar/"
    @"02h5o3JmNFu6WmaraVF/Fu7+vcBMbGXYy7DFCzhZQXqEy+lRmYiCiaz6XNUZIF46ZFGUkUUSSJoCQjSgqCpNgqK8f/"
    @"lwQxNTgKfgLBEKKqsm9nLTvXltLeaMtdDVW07ari6R1r2V1dxpVP/plILMGEy82Ee27VNA2UNVWmT5nplZUEZ7aD4PMTlARiQR9E3KD7QJcg5gPdCzERdAHCPm5oXlRRQjbhiULanyIy/"
    @"Pho/1J8PqOaPrr8PmsevN8AY9PTDdW0NVbx+KOl/Pmhp5DVIF6PD7drjPGJ8eRNz1ZjY2O3QblcrmkG5na78ZiwJtxevB4Pbq8Xt8dLSPZC1AO6h6gq8B+/"
    @"8vNPv5BwXpM5eSXI258EeetTlZP/pvDRf0r8yxcS/+0WuKF5IeaHuA9iHhKaH0UU8AnGz+iCX0Aw/Ujw+wyP8vnw+3x4zLY7cvh51j/"
    @"wO3Q213DATPCGP1VxqLma+opizp96m8lb4BobY9zl4leu8TlBsoP6XwAAAP///"
    @"Uf6ZwAAE+lJREFU7Zh5dFvVnYCvZBNKaaHTJWylBdpCCiEpafCSjEuzYTsOpFDWxHFisgFJHNsJYckOYXFil0LHLdOFtpOGAIWBYTIktmXJmxYvsi0vsq2np9WybEuyJC+SZQe++"
    @"UOOE5iydGhnzpnhnvOde6Wnc9+9n36/e+97QgghXC4XTqcTl8s1jdvtxu124+rtpc/" @"dh83tJjLohDEPvn4PrzUMsuntIX748jBfK4mhfC6GOBRDHIwhDkwgDk4gnowhDo2T8FyUmc+"
    @"PkfT7Eda9FeQpVZDyjkFk1wCnw16IumDYw7Dfy4DXi9Pbh8frpd8zQG9vP319vQwPj2B1uEhPnsudC2exJiOF1elJZKcnsTo9iVW3JnHPLTdy/"
    @"9J5mDvNBIZCuJxOnE4ndocDx38Tu92OOFOcTicOhwPnVMfn4nL00t9ngxEHbreHA2U+vl0aQRyYRDweQ+"
    @"yNIA6OIQ4Mxzk4jDgQjrefHEM8FUEcGkMciiIOvIfYP4nYN454MsbFR6KkHw2z62SIf2sdwNXrgbAHRnqZ8Pfi9bpx97qQnW4AXv51KbMv+zK5K1LJzkhhTUYK2RnJrMlIJicrlR/"
    @"fcBnFewuYOP0+dodzeqKfBZvNdlaU3W4/x+KUIKcT2e4k7HVC0MkftANc8kIE8cT4FGESd4YQ24cQ2wKIh8KIzSHE5iBiUxDx4BBi61D8emEQsSuI8olhlPtHSXhmFFE0hnh2HHEgFu/"
    @"vwDiX/XyEO14NUlozSIfUy9hQL4y6IOQlNBrhruW3csusS8nJSiU7M4U1GclkZySRnZHCqlvns/"
    @"yHV6OrVjM6HvvARP8Oopy4nPHIkuwuRgdkYgE7uW+FEHveQ+waR+wMIdYHEauDiJxQXEreEF/"
    @"aEeDiRwa5aJefi3f5mFEYQDwcRKwPIdaNIDaEEQ8FEFuHSMgPkPhIiITdYZRPRkh4bhxxZBzxTAyxJ4rYHeNLz0VY8scQT1cM4R4+"
    @"zcljL5J0kWDj4lmszkzivowUstOTyV6WyprMJJbNvZS9W9cxFokhO5w4PmMk/"
    @"UVR51p32O3YbXaCHjvRfjtLjw7HU+yxCUROGJE7xHX7fdz7m172vO7ipVNOXquReEcr8XaNhdc1Eq+oLLz0roWn3rTx0B+"
    @"d3PVLNzceGuD8gmHExmBc9OYwyq2DKLcHEIUhxBNBlAdHSSiKIYonEM9OIPZFEY+Pc0HpJFc8Ws0NPylk7YpFbFt4GZvTvsnaZfO4PzOJ+5fNZ/"
    @"ncb6OueJfI+GkkqxWbzfY3QZblD4o6I8thd+ByOCFoIefNIOIxEAUgftrG2l/0oGrx4nbbOB20cDpo4/"
    @"SQnZFBGz6vE2+vA4fDTpck02buwdTeSbPJTEOrmVOGTo5VdrHrVTtLf+bhop0BxPphxMZQPEW3BRDbhlDuCKJ4IoTiqVESj0SY8bMo4qkoohjEr+GLzwwya/"
    @"txlt+zjvWLZ7Ml7RJWzvoCh7ZvIDoxjmyzY7PbsE1Fw/Tc/haiZFlGlmXsNhsW2cZ7gzaO1vci9oPIA+XCX/" @"Crl1+"
    @"BqBXCLvo9DpwuFy6nHbfLiccdX3T7el14e13097np63XjcLgxS06MnVbqmi3UGTsxtrZhaO3grdouHjnm4vsHfYiHgojcYcTWEIrtPsS2wfja9sgQifvCJDwdQVESRXFkEvFzEKUgXoCv7"
    @"O9iXm4JmUsXY2ssA8KE3T04bDYkWcYu27DLDmSbDckuT3/" @"3mUXJsozLbiXc2813fzuJ2AHiO7n8sfhRIIzL7Ua22rDbp1LV4cRud+"
    @"J0OHA57NPbsNPlwO1y0uty4el14vU4cbnddEhu6k0S6kYL2mYz5s4O9M1mfn7CyqKSPsSWIcTaEcTWMAkFfhK2hhBbgygKhkh4Iow4NIKiOIaiOIYojiFeiAubUfI+S4/GeKbMTYPZzni/"
    @"BQLdBHstWGUZi9WOTbbhkGQk2Yo0NVfbFPLHYLVaPyjKarVilWUm+60cNXoRB0F8cxWF9yUBYHe6ke1/"
    @"eQexTdXOjzhixM9oTnrdLnrdLmSbk7YuG3UtFmqNPZjNnVgtHbyitvHTF72IB8OIDeMk7ogh8oMoC/wot/hQbBtCuTOI2D+Comgcxc/GECURxGEQeycRT8Q4ryhGxh8CPK/"
    @"qo95sZ6zPAr5uRj3dOGx2JFnGKlunM+ivFGXFapWwWiUY7GJVGYgfv8kNFwhMehWRWAxJsiLbpv6JjwjTT9pBHHY7boedXqcdp9OBxWbHZJaobbWib5OwS+14bG1UGh2s+"
    @"m0YsSWEeBREwVg8FfOn1rKtfkThEIq9YZTPRlEUj6N8PoIoiiGemkTsnUDsGefiojFW/"
    @"H6I58v70LbL+LwS+LqI9vXgtluRrFYs1ilxVms8WKxWrFZ5ui1J0llR8QsyHrtEf7+L2S+OceHMuWxYdCU2yY67rx9ZlpCl+O+scryTc/"
    @"P43PojmVpgZZuMbLfhsNtw2O30SHbMXd20dnbRITmA93nx0HYuu2Ye12x8F7GLqU0liMj3o8wfInHrEIotfhT5fhS7gyQcGkN5OIYojqA4EkFRFEEcGkfsmUTsmeT8ZyZY+Lshdp/"
    @"ycsroZMAt8f5gFxP9XQw6JCRJjgeDJCHLFmRJxibJSFbLuaLiEx9wSrR4x7hkaxVzLruAvPuzsFklnC73tOGPC9P/zq5it9lwOGxYbTZ6rDIAL/"
    @"7qJb5yvuC++V9n67LLWfmTHL65SR0X9mhcmLIggMgPIrYHEdsCKPICKHcFURwIoywaQ1ESQ3Ekhjg8hjgSQTwzEU/"
    @"P3ZOIp6LMfinMw28N8CetG7MkEfGaOT3YxbDHjEuWka1WLDYLsmQ9V5SEZLXgdVqocr/Hd3N/"
    @"Sfr3ZrB25SI6zWZc7l4kSfovWD8Qrh8v8ePWAKvVik2OSzp29BgXJQqWzr2a9SvSWLMshS2LL2XjoqvI+ukGZuaeQqwbRGweRuQNIQrip3/"
    @"l9jCKbUHENj+iIIBi9zDKpyMoisdRFE8gDkcRh6Moi6KIZ6OI/eOIx+OPVJc+P0LW0SGKy/uoaLExYO9h0tvFewNd+N3dZ0VJkoRVstLvsNDcN8GiTUf4yeyvsWLBbHQ6LT5/"
    @"AIvF8hdlfZS0T4vF0oPD4QDg1WPH+PIMBQtnXc6mlT9iTUYSq9OTuT8jhfUZN7Nq3oXkLJzJv5wykfnrKGLDMOKBMCIviCjwo8gPotg+"
    @"hCIvgGKbP56mj4ZRHhxBeTiCsmQc5ZEJFIcjJBZFURRFEc9FEE+Ox588dscQz0a5/qUwD7w2yEsaD/qOc1JPskhYeiQc1m68wQke2P3PZMz9FsnXfJ3f/"
    @"fqXxCahp6sLq8WC5WP4OHEfviZJEt093Xj7+"
    @"wD4xYsv8EWlYMGsy9i4Mo01mSnx57jMZFYtX8jtqd9j2Zxvo1X9OzCEz9bOsYpubjnsRWweQ2wYReTFjxWiIICiIIAiL4xy2xDKbT7EziEU+0Ionx1DUTxOwpEYiqIoiqIIiueiiKJo/"
    @"Pnz6Rhi/2nE7tOIvZOc92z0rKju7m66u3vo7u5mJOij6PdlLPrhDWTddDnpS9Lw9vfj6euj02wm/"
    @"tvPRldXF93d3YyNRRj0+Xlw80bOE4IfzbmKB25byNrlKWSnJ7EqPZmc5Qv4yfxrSJ9/DYbaMmKn38fQ3E6LqQ231IrN3MBv/"
    @"s1ERpEbsXUYsXEU8fAwIj+IotCPyA+gyA+hyAvE0zLfj+LxEIon44u/siSKsjgyFV1nhMXTVBRF4q+LzpROcyfmrk46zV24nRI1zRIrly4iZ8n1XP31L/"
    @"BIYR7vARbZSkdHB2az+VPR+eHPnZ10dHTQ7/MRm5yk/ORJkm6ax/" @"lCkJlyPRtvT2NNRjKrM5LJzkhmbdYClt54KXf842zajA1E3n+f+"
    @"uZWGlra0TW2oNYZUdU2YqyvoV6v4VdvN3JrsYOEbWHEAxNxcYUDiILQ1FoWQpEXRLnNj9juQ7kziHLvCIpnoihLYoiSccTh8WlZisOjiOfGzopq72invaONjvYOWtra8QfDFB/"
    @"azeLvz+SeH9/EN76gZO/u3cQmJ+jz9mEymeho76CzIz7xc2lvb6e9vZ2O9nY6OzroaG/HZDLR3d1FwO9nbCxCbZ2WB9at5aLzBFd/"
    @"9QLuW3YzD6xYQE5GCmvSk1iTkcKq9Ju5ZdZX2Xz3Mpy2HkKj4zS1mGhvM9HaYsLQaKRS28TJKgPvVGj513IduhoNhjo1L/"
    @"+7jjtesJCwPYzYMIbYMoLIHyKhwIciP4SyIIQyL4jICyC2+lBsD6B4LIzyyTGURREUJROIkqmF/"
    @"5nIWVEmkwmTqQ2TyURbq4keyYLD7WDjysXcPv8qbku5ngsVgnvuuYdGo5Hh0VEGBn1YrbZpOaa2NkxtbbS1t9PW1k6nuQu7w4nP7ycUCiPLNt54/"
    @"TXWrl7FJRdfyJeEYNEPvsu6FQtZl5XKmswUVqcnk7M8lTsWXsuPrvsaxXsKiIyE6R8M0tDQSHtbK21tbbS1mTC1tmJsbkXXYERd18AptZ63yrT8+"
    @"WQ1qsoqGrQqjp2o5d4XZb62K4BYH0U8OIqyYIjEQh+KgiCiMISiYGhKWABlXgDlTj+KvcMkPD2O4shE/PXPmdLS0sIZWltaaGxowN3vp7OtiTsXXs9tSd/"
    @"ljlvmcnGi4MpLv8FDm9bzpz8dQ683YLfb8Xg8eDwevN5++vr68Hg8dPf0UF1dxb/88WW2b9tCyvz5XDRDwVcSBAtv+BbZmankZi1gbUYy2Rkp5GQtYNWt87nlum9w74/"
    @"nUP7Oq0RPv49FsqEz1NNqMtHS0sy5YzWZWjCZTBibjTQ0GqnVG3lXo+etU3W8eqKW8goV9TXlvHGymk2/MnPFY/2ITSOIzVFEoZ+EwsH4OSw/GD/"
    @"1bw+g2DaEYosvfvTYFULsGzkrymg0coZGYxPNTUbq9To8/"
    @"gA9HW3krEhjyfWXkH1rEsnXXcnFSsFXv5DAtVdfyZLFP+LOlVnce9cd5Ky+l3vvvoOVt2WSlprE1ZfP5B8uUHBRguB7l3yRjKRZZN+"
    @"aTG5WKuuyUsnJSCEnI5U16TezbO6VLPvBlZTsL8DpsDE8NkGTsRmD3oDR2ESTsYlzx9k0VTefodlIc3MzTc1GGhoaUNUa+A+1jrdO1nCirBJ99UneOqkh/"
    @"7cdzNnbh9gYQWyOxKOpwDclKjRVh+MCtwYQWwJnRTU0NPBhGhvqqa6pxdM/gN/XT/G+QpbdeDkrk79DdnoyWak3cvP3ruCqb1zIzC8lcskFSmZeILjkiwquuOg8rr30YlK+/"
    @"y1WpM5mdXoSOVnJrMtaEE+z9CRyMlO5f/E8lsy+jGU3Xs6BLeto0FYTjY3TI9uprq6hqaGepsZGGhv/6/"
    @"gaGhvPjvWcdlNTI8amRpqb6mlqasRgMKCu1XOiUkeZSoOh6j84UaZi7x+MJD3pQDw8htgQjUdTYSB+"
    @"DisMoiwMxJ8v84bOijIYDJxLfX099fX1NNTXo6muwdxtIRYbp1Z1kh1rb2PpnMvJvOlb5CyZR25GKmsyUll969Sr2fQkcjJTWLd8AbnLF7JueQprs1LIzkxldXoS9yyaQ+"
    @"a8q7jlupncmXYjJbvzqK+tZDgyQt+An7paLVqtloaG+Bg+PLZPS319/ZTEBpoa47XeYEBTq0ddU4dRX4amqpyS1/QsedqOcksovvA/HEZZOEhiQRBl/odE6fV6Pgqd3kBVTQ1VtXV4B/"
    @"0M9A/y7tt/5qmdG1i17CYy5lxB+uzLyZp/FbenXsvKBddxxz/"
    @"OYuWC67g95Vqykr9D+g++ybLvzyR97pXcv+xm9mzJ5vjvSukwtTAyFsU76KNar0NTVY1Bb0Cn16HT6TAYDHzc2D4JnU6HXq/"
    @"HoNdTr9PRYNBT39CIsV5Po0GHQa+jvakCU0MFf3rHwN3PS3y5MIBYN4F4cBhFfuCDorTa+L/4Yeqm6zq0Wi2qykq0egN9/YP4h4J0m9s59farvPKbFzm480Ge2Hg/"
    @"j2+4j53r7uKRdXfy2IZ72PPQGkr2FPDm0d9R/s6/"
    @"InV14u3vJxAexWyxUKFRo1ar0Wu16HRn71VXV8dHjevTUFdXdw7aafTaWrRaLbV1evQ6LQ06PfUGHd0tVbhMKlRVWgp+38VVuwcR60cR689ZzGtra/"
    @"k46qZqrVZLbW0NlZWVVKrVtLZ10jfgIzw6ird/AK/Xi8/nY2BgEL9vAP9gfBfsHwwQGo3i6u2jta2D6ppaysvLqa6qoq6ujk+6/" @"9+Tmul2HTW1dbQ1avC0q2jS1lB0vI05+"
    @"z1nRZ08eXK4urqaT0NVVRVVVVVUV1ejUatRqSo4VVZOhVpDdU0ttXVadHoDdXoD1XVaqqprUKkqKSs7hUqlQqPR8Gnv9T9JVXU1tTVVVFfXUq2pwqhT42gtp66mIjYt6ujRoz0ajYZPQq1"
    @"WT9dn0Ex9p9FoqNRoUGk0VKgrUanVqNUa1FUaKjVqPk3//5uoNRqqNJWoNWoq1ZVoNJVUVFbz59decUyL2rdv359VKhWflsrKyg99VlGpOotqqlarKlFXxNsVf0X//"
    @"1tUqCqpUKlQV1ZQqaqgskLFgf1735gWtXjx4tXl5eV8TjkV5eWUl1dMUc6SJUuyp0UlJibOOHbsmLusrIzPOcuxY8d6zzvvvPPFuSUtLe3ud999l885S1pa2t3iL5Xc3NzDJ06c4HNOkJu"
    @"be1h8VFEqlQkbN278xdtvv83/ZzZt2vRPSqUyQXxSSUlJ+Wlpaan05ptv8v+J0tJSKTU19S7x15TExMQZaWlpq3fs2PFGaWmp/fjx4xOvv/46/"
    @"5c4fvz4RGlpqX3Hjh1vpKWlrU5MTJwhPi+frfwn6jwnJwAAAABJRU5ErkJggg==";

NSString *const STImageResourcePayPlatformWXBase64String =
    @"iVBORw0KGgoAAAAEQ2dCSVAAIAIr1bN/" @"AAAADUlIRFIAAABKAAAASggGAAAAHNDCcQAACklpQ0NQUGhvdG9zaG9wIElDQyBwcm9maWxlAACdU2dUU+"
    @"kWPffe9EJLiICUS29SFQggUkKLgBSRJiohCRBKiCGh2RVRwRFFRQQbyKCIA46OgIwVUSwMigrYB+Qhoo6Do4iKyvvhe6Nr1rz35s3+tdc+"
    @"56zznbPPB8AIDJZIM1E1gAypQh4R4IPHxMbh5C5AgQokcAAQCLNkIXP9IwEA+H48PCsiwAe+AAF40wsIAMBNm8AwHIf/"
    @"D+pCmVwBgIQBwHSROEsIgBQAQHqOQqYAQEYBgJ2YJlMAoAQAYMtjYuMAUC0AYCd/"
    @"5tMAgJ34mXsBAFuUIRUBoJEAIBNliEQAaDsArM9WikUAWDAAFGZLxDkA2C0AMElXZkgAsLcAwM4QC7IACAwAMFGIhSkABHsAYMgjI3gAhJkAFEbyVzzxK64Q5yoAAHiZsjy5JDlFgVsILX"
    @"EHV1cuHijOSRcrFDZhAmGaQC7CeZkZMoE0D+DzzAAAoJEVEeCD8/14zg6uzs42jrYOXy3qvwb/ImJi4/"
    @"7lz6twQAAA4XR+0f4sL7MagDsGgG3+oiXuBGheC6B194tmsg9AtQCg6dpX83D4fjw8RaGQudnZ5eTk2ErEQlthyld9/mfCX8BX/Wz5fjz89/"
    @"XgvuIkgTJdgUcE+ODCzPRMpRzPkgmEYtzmj0f8twv//B3TIsRJYrlYKhTjURJxjkSajPMypSKJQpIpxSXS/2Ti3yz7Az7fNQCwaj4Be5EtqF1jA/"
    @"ZLJxBYdMDi9wAA8rtvwdQoCAOAaIPhz3f/7z/9R6AlAIBmSZJxAABeRCQuVMqzP8cIAABEoIEqsEEb9MEYLMAGHMEF3MEL/GA2hEIkxMJCEEIKZIAccmAprIJCKIbNsB0qYC/"
    @"UQB00wFFohpNwDi7CVbgOPXAP+mEInsEovIEJBEHICBNhIdqIAWKKWCOOCBeZhfghwUgEEoskIMmIFFEiS5E1SDFSilQgVUgd8j1yAjmHXEa6kTvIADKC/"
    @"Ia8RzGUgbJRPdQMtUO5qDcahEaiC9BkdDGajxagm9BytBo9jDah59CraA/"
    @"ajz5DxzDA6BgHM8RsMC7Gw0KxOCwJk2PLsSKsDKvGGrBWrAO7ifVjz7F3BBKBRcAJNgR3QiBhHkFIWExYTthIqCAcJDQR2gk3CQOEUcInIpOoS7QmuhH5xBhiMjGHWEgsI9YSjxMvEHuIQ"
    @"8Q3JBKJQzInuZACSbGkVNIS0kbSblIj6SypmzRIGiOTydpka7IHOZQsICvIheSd5MPkM+"
    @"Qb5CHyWwqdYkBxpPhT4ihSympKGeUQ5TTlBmWYMkFVo5pS3aihVBE1j1pCraG2Uq9Rh6gTNHWaOc2DFklLpa2ildMaaBdo92mv6HS6Ed2VHk6X0FfSy+lH6JfoA/"
    @"R3DA2GFYPHiGcoGZsYBxhnGXcYr5hMphnTixnHVDA3MeuY55kPmW9VWCq2KnwVkcoKlUqVJpUbKi9Uqaqmqt6qC1XzVctUj6leU32uRlUzU+OpCdSWq1WqnVDrUxtTZ6k7qIeqZ6hvVD+"
    @"kfln9iQZZw0zDT0OkUaCxX+"
    @"O8xiALYxmzeCwhaw2rhnWBNcQmsc3ZfHYqu5j9HbuLPaqpoTlDM0ozV7NS85RmPwfjmHH4nHROCecop5fzforeFO8p4ikbpjRMuTFlXGuqlpeWWKtIq1GrR+"
    @"u9Nq7tp52mvUW7WfuBDkHHSidcJ0dnj84FnedT2VPdpwqnFk09OvWuLqprpRuhu0R3v26n7pievl6Ankxvp955vef6HH0v/"
    @"VT9bfqn9UcMWAazDCQG2wzOGDzFNXFvPB0vx9vxUUNdw0BDpWGVYZfhhJG50Tyj1UaNRg+MacZc4yTjbcZtxqMmBiYhJktN6k3umlJNuaYppjtMO0zHzczNos3WmTWbPTHXMueb55vXm9+"
    @"3YFp4Wiy2qLa4ZUmy5FqmWe62vG6FWjlZpVhVWl2zRq2drSXWu627pxGnuU6TTque1mfDsPG2ybaptxmw5dgG2662bbZ9YWdiF2e3xa7D7pO9k326fY39PQcNh9kOqx1aHX5ztHIUOlY63"
    @"prOnO4/fcX0lukvZ1jPEM/YM+O2E8spxGmdU5vTR2cXZ7lzg/" @"OIi4lLgssulz4umxvG3ci95Ep09XFd4XrS9Z2bs5vC7ajbr+427mnuh9yfzDSfKZ5ZM3PQw8hD4FHl0T8Ln5Uwa9+"
    @"sfk9DT4FntecjL2MvkVet17C3pXeq92HvFz72PnKf4z7jPDfeMt5ZX8w3wLfIt8tPw2+eX4XfQ38j/2T/ev/RAKeAJQFnA4mBQYFbAvv4enwhv44/"
    @"Ottl9rLZ7UGMoLlBFUGPgq2C5cGtIWjI7JCtIffnmM6RzmkOhVB+6NbQB2HmYYvDfgwnhYeFV4Y/jnCIWBrRMZc1d9HcQ3PfRPpElkTem2cxTzmvLUo1Kj6qLmo82je6NLo/"
    @"xi5mWczVWJ1YSWxLHDkuKq42bmy+3/zt84fineIL43sXmC/"
    @"IXXB5oc7C9IWnFqkuEiw6lkBMiE44lPBBECqoFowl8hN3JY4KecIdwmciL9E20YjYQ1wqHk7ySCpNepLskbw1eSTFM6Us5bmEJ6mQvEwNTN2bOp4WmnYgbTI9Or0xg5KRkHFCqiFNk7Zn6"
    @"mfmZnbLrGWFsv7Fbou3Lx6VB8lrs5CsBVktCrZCpuhUWijXKgeyZ2VXZr/Nico5lqueK83tzLPK25A3nO+f/"
    @"+0SwhLhkralhktXLR1Y5r2sajmyPHF52wrjFQUrhlYGrDy4irYqbdVPq+1Xl65+vSZ6TWuBXsHKgsG1AWvrC1UK5YV969zX7V1PWC9Z37Vh+oadGz4ViYquFNsXlxV/2CjceOUbh2/"
    @"Kv5nclLSpq8S5ZM9m0mbp5t4tnlsOlqqX5pcObg3Z2rQN31a07fX2Rdsvl80o27uDtkO5o788uLxlp8nOzTs/"
    @"VKRU9FT6VDbu0t21Ydf4btHuG3u89jTs1dtbvPf9Psm+21UBVU3VZtVl+0n7s/c/romq6fiW+21drU5tce3HA9ID/"
    @"QcjDrbXudTVHdI9VFKP1ivrRw7HH77+ne93LQ02DVWNnMbiI3BEeeTp9wnf9x4NOtp2jHus4QfTH3YdZx0vakKa8ppGm1Oa+1tiW7pPzD7R1ureevxH2x8PnDQ8WXlK81TJadrpgtOTZ/"
    @"LPjJ2VnX1+LvncYNuitnvnY87fag9v77oQdOHSRf+L5zu8O85c8rh08rLb5RNXuFearzpfbep06jz+k9NPx7ucu5quuVxrue56vbV7ZvfpG543zt30vXnxFv/"
    @"W1Z45Pd2983pv98X39d8W3X5yJ/3Oy7vZdyfurbxPvF/0QO1B2UPdh9U/W/7c2O/cf2rAd6Dz0dxH9waFg8/+kfWPD0MFj5mPy4YNhuueOD45OeI/cv3p/KdDz2TPJp4X/"
    @"qL+y64XFi9++NXr187RmNGhl/KXk79tfKX96sDrGa/bxsLGHr7JeDMxXvRW++3Bd9x3He+j3w9P5Hwgfyj/aPmx9VPQp/uTGZOT/" @"wTZH+4dAAAAIGNIUk0AAHolAACAgwAA+"
    @"f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAAAJcEhZcwAACxMAAAsTAQCanBgAAAAcaURPVAAAAAIAAAAAAAAAJQAAACgAAAAlAAAAJQAABs4KwUbKAAAGmklEQVTsmHlMm/"
    @"cZxx+OmNi8PgkE2xhX26I2SJPWaV2mqFKnKmqapWrVLJ3WLOu6o1KmtGquXdIm7dTG2nVSq0ZR17WVOiVLN9ZjWVoOE8AHxjb4KEcCJWEhhAZKSAdeCAE++4PULsQYO+aIOh7pI//"
    @"h3+95n+/H/r2vZZGVyqyyVolKc6/qa2ueUg5bqgxnbCHTldI2E58kbH7jiPmYvmPNU8phzWbVQ1mrRJWWJM0m1YOWt/VdnzQx82F5W9+l2aTaNr+hHMkx7FOX29qM/"
    @"D9j2KculxzJmdOTYZ+63NZqZIVrshIet3tU21cEzURzj2r7dTduS42+1/aukRXiWBz6czNu8Jqtqm+siEmM5j7Vzpiogj/k/21FSmLWPJP/95go8zv6npKIkRWux/"
    @"yOvicmyhowjJVEDCwm1ogOc1hLcVihOKxgiWixRnTYFvm6Gc/"
    @"dbLgSE1USNrBQ2MIGSsJ6TMFcxC9IkyDea68BIadZyA7IzPd8wqpmYW1IQ2nEyELOsxAsqCh7xERhKC8Wfk1Q4a6TX+KJnl2Un/8NRwePUP1hJQ0jtdSNODg+fIxXBl7il30/41vdD/"
    @"P5tjLyAtN7swKCJaylNGy8yUSFDNwo9rAJY0su0ihoAtl8tfMBXhl8me7Lp0mnJqem8I14+VXfL7ij7XPTwpsEc0iZFpbBjJkSv0eFDKRLaciEOaRFGgVtYBWPn9lNMBpkoeqfF4+"
    @"x9dS9saNpDxspCRm5kVkzJS4qqCcd7CETar8gHmHbqQdoi7ayWFUxVEFZ+"
    @"DbELRS1aLCFjKQ7b6bckCh7yIg0CmpfDn8eeJGlqImpSb7fvQtxC0ogC3vItEyiWvSkgj1oRNzCLc023o1GWOp64f1DiFtY7RPsQROpzp0paYn6SNK6lk8xMH6B5aq3ht5A3EK+"
    @"L4vSFtPSirI060lGaYsR8QhF/gIGxwdZ7vrH4GtIg2DyqylpNjDf/JkSFxXQMRfWZgP6JhXiFsLRFm6W+vXZnyP1gqVZIdn8C0GKohSkXnjmfHlKAa6OTWQsIdUed4a/"
    @"iLiE0mbDEony60hEScBAlku4PbR+3qFHxkZ5JLyTMs86NgY24rvUmLYg11ADG3wbWO9Zx3faHyV6NZp0/cnoScQpmHx5zJVhIYj/e+DXkYhifz5SJxy/eCx5winYFr4PqRKymwSpE/"
    @"JdufRe7k1Z0pnR0+TWCVJ/rUeVsKNj+7z7vtu5A6kXSvwG5sqRKXFRPh2JyHEJtwdvnXfYvmgfOU5B8Qlmnw5bQI84hIP9z6Us6umecsQh2AJ6zD4dGq+w2i1cuDKQdF/"
    @"rSCtZDUKBL4+5cmRKXFSTltlYfTqkVvh972/nDTk8PozBk4c4BatfR1FTHuIQ3hx6PWVRR/"
    @"oPI9VCkW81Vr8OcQqFjVr+c3Vk3r1fDm9AnEKiHAtBUlGFXhU5TiE0Gkop6PN9zyLVgtQIUik82PYVJqYmUxY1PjnOlsjdSJXE+rzY/0JKe//"
    @"Y+zTiECyLLsqrZTa5LqEsYGdyairlsFUXK9nf9SQHzz1/" @"w0+85849y4HOPZwYrkltwxQ0XfSSXZ9FoVdNcYIsmRITVezVMhs5Idzfuvmm+d00EB3grfNvsr9jD5v9d1PqKqSgIZ+"
    @"CegVTgxqpFeSEIA2C4haKvQpmr45E2dIlLqpRYTbiEHZ1Pra8dibhaO8RNnrvQI4L8q/pI2lvXMtdkQ081HE/"
    @"j57awfc6H2F312M83L6dLwQ+S6E7f1qcQ1C7BLP3+nzpEBflUfg4Zo8WqREOvPfksjk6dOYQmho18oagNOSxp/txai5VcWliOPlJnILT/"
    @"z3NqxdeZWf71ylyG5BqIbdesHq1mBtnZk2FmKi1HoWPU+xRkGphb9cTSy4oNBxk3YnPIBXCev9tvP5BRUb9zo/"
    @"1U97zO+weC1Ip6JzZWBt1zM6cjLgot8JspFr4dsc3l1TSwe6DSIWQ7RBeG/jrgva+dPVDDpzaizgEqZVpWQlyJ3QRE+XKZzbiEDYF71wyST9p/"
    @"RFyRNga2kJ0amTRruMYqqG4oQipEiwehbUuhUT5Z7hIJkpVJ1jdRkYnoosu6aftP0YOCz/o2rskH0r/2HnKPLcilYLFnYaoImc+syl05iGVguODmkUd+qV//wn5i/DD9/"
    @"Yv6TEfnRjh085bpr9ZboVEDj4iqahip4IcF/ac3L1ow54d7UGOCltaNiVd1zHcjrvfk1bvC9H3aehzMj4xNueac5fPkleTi6pWKHZqk4r6HwAAAP//"
    @"O2t3PQAABpNJREFU7dlrbFtnGQfw//"
    @"G5+Bo7sZ2m2+hU0ZUPsGoIBhNsdBMMTUxcBk23QZDWAWWAKHyiDAkJiW1QZYwB7cYuXSXUNm1i52L7+J7Ysbu2K8tgXZqpTZolkF4Ia9Jb0tZukz8fTus08jVpung0j/T/Yj3vOc/7s4/"
    @"1OgEALEqamCtKDKxJVDJ1KcXrUZ9M3E74wUlO5u15rncD4QPhA+974x6Opk4Wva73qIeWgIXwgcviS3ngdHfe3qbjOwk/6Ejqmc8BV2pRwsRcWZw0Ej7w+YH6OUfqGI4S28Ed/"
    @"92at6fn5AENKQ5W7hKIFvDJg78oeN2x9BhrOqxECLS/"
    @"LhJe8EtdXyi45stdK4kgeFPSnNMhA1WdMDFXFiXM1LcLtEXNPHvx7JxCfSK5nFUdloI9keEI4QUdSYk3Jy2EB6x9+xsF14ycHyHCoBQDa5JmIggu372k4Jp9o/"
    @"sIP1iVkHM6TEF1mpgvixNmQgUf+ee35gxpaGyIcIHP/vuZgn3jl8b56T23E80gPNrjFx+JFb3+D7rXEG4QXhDN4PODzxVdc9feO4gQWN1pzjKYgoobmT8m2jv1RBv40sALcwL1p8N/"
    @"IFrAY6mjRXtPpU9y3YF1fOStWsZH20u+xzOHn+Kqrq/ztSOvltT/"
    @"u76nCS+4qNOUZVAilJGL4yaaogLhAQPH1GuG+trfH6AxKrGcKvZ+TPtSj0n5oZwxI4tlcdxEXUj7OKvHPNc01NL2m3jPvs+UFdS/"
    @"xgdpjehpjCJr71NQHUaWkpq4WcNqAzf1b+SliUuzGkoJgHXv1JYV1FhqnMvit1AII2vfV0EZWGpqYiYaIiB2glsGN89qKCEArun+"
    @"dllBXbiY5sfitxIhZO15CqrdwJnE1i4SPrDjRMeshrIGFK5666tlBTVyfpQfiToohpC13wyUI2rgTAIVXLHrttmfyDs/ztsSS8oKqud0DyU/"
    @"aIkge7+zgaqOGolm8Oc9P815w6e6f8tVux/i5vde5buj7zKdvpjVs6HvacIDTkxOlA2Ua6iRaAYdUaUAVMTAUmOPSEQr6B/2Tf9JcjTGz7bfSTRphzw0g0afwBXty/ngnvu5tmsNf/"
    @"XOetYf/D3r3lxNuMA9o3vKBuqJf3yPaAadOfZ8FZSepUb0g85oBScu/5A9Pnacj+99XANqAx3tMp0RPZ1RhaYwCL/2OlqgnZZdl0/MLeC67h+Vxxd5OkVnwEo5iJx7zkDZw3qWGrjBn3X/"
    @"hCS58eAmOjyVRBNoDmvvRqG1jvDlm4f1VPwCLaqBZ1Jn5h3qz71/JBq1xy7nnjNQIT1LjdkvceXrd/H+xL1EIwgVdEZKX38lzoieaAKf2P/"
    @"9ef40XaDDa6WsCnSEDDlnnRVUdcRAwac9TvawnPfixWOgJSASTWDy/c55g3p072qisfCbPQUVVDgfqQ4ZiFbQ5qng8PnhDxxp06G/"
    @"EA2gLSTREdTnnXPeoaqCCp1hhXCBy4If5ciFkQ8MaVv/"
    @"VqIBNKigswDSNKiqgML5jCOkEE3greoS9pzsua5A59Ln+GxPPdEAil4Nqdh8ZQOlYekJF2hsVvha35brBnXoVC+xVTuiOEpAmg7lV1gOcQb1RCuIBvDBzq9w93/m/"
    @"kA6MTnJO2MrCBdKnmsKSpVZLrH7Fdr8ArFT+wvFN5MP0TXg4lhqfMYo3ScOsKF3R9br9Qc3ENtAu18qaaYMVKUqs9xi9ys0qBoWGsCl/ltY98ajfOHQRoaOBNl/up/"
    @"D54Z56sIpjp4f5bHx49x/4m02DTbyN/t/"
    @"zQdiX6TeBeJv4KdCdzAwFMhA9Z99j4IbVLwoaZayhrqSKlWmVdX+VYUGENs1vIpWiU6vhUvUat7sc9DuMVFxX9XTCMpe0BbQaQfj7eDDux7m4dP9JMnvvFlL7JgplE/"
    @"mhyaqRIsPlDyg0ArtO60V1LWBei9oU0VWqtK0NXZVockHYhtobtbzld6X+"
    @"OOutZQbdSXdMwNla5LPfKiwZhmHqmi4DaDUAtr9SvF1rXIqA2X9q3So0ivzRonNq6PNK5bUa90sDWagTL8UXTavxIVkx/"
    @"Sk6M5AyfcKdTaPxIVkR75P+G4GChKUii3S0ALM9FRskY5Ahh5Xl3y3sNrWJnEhU5HvFlYjVxke09UvAGkxPKarR97SQTSu1W280ZGMP9Rtgg4iipX8OWGV5UWxz9oq8kaK5UWxT/"
    @"68UIsZlQRFXinUGdfr3JaXxQGrW0z/3+G4xbTlZXHAuF7nllcKdZCgYKGurf4HxOq9BAAAAABJRU5ErkJggg==";

NSString *const STImageResourcePlaceholderBase64String =
    @"R0lGODdh+gD6AOMAAMzMzJaWlsXFxbGxsaOjo5ycnKqqqre3t76+vgAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAA+gD6AAAE/hDISau9OOvNu/9gKI5kaZ5oqq5s675wLM90bd94ru987//"
    @"AoHBILBqPyKRyyWw6n9CodEqtWq/YrHbL7Xq/4LB4TC6bz+i0es1uu9/wuHxOr9vv+Lx+z+/7/"
    @"4CBgoOEhYaHiImKi4yNjo+QkZKTlJWWl5iZmpucnZ6foKGio6SlpqeoqaqrrK2ur7CxsrO0tba3uLm6u7y9vr/"
    @"AwcLDxMXGx8jJysvMzc7P0NHS09TV1tfY2drb3N3e3+Dh4uPk5ebn6Onq6+zt7u/w8fLz9PX29/j5UQIDBAUBAQoUMDBAgAWACBMqXAiQAsOEFRAwtCDAAEADBnFVfIiwwAGH/"
    @"hxDNpwgsgKBiRQE/" @"OuYsRaClSIDkozJEWTNCQceVrCo0IAtlTQRzgy60KbOCTAVVjhK6yTRAEMvGjCQNMBUnkInDJiqcOAAnF2nfjUK8cKAhAROSVRYUIIABGfLAlAqAevIuXLJ+"
    @"qRQFQEGpwn3WrAL1VRchB8PyqULgHDUwksDUzh8MYOAri13MiYFWOYFxowdS9j8WPBlhZkpOsWYQXSppGk/"
    @"L5brmvRoyXXZqnBNSmHsCwKC8xUocIJr4sUVI9x7muVu26GSFkDBe0PP3AnHXuicdwL3hdOjK0xcorqG62s7nmdKlr0nwgHIjzCf4Tp3+cqL5r8JKj1av/NB/odBT/"
    @"4F8NuA7t1WkijfAUQAfh3Qh+By3AGYwQFTVXUBhlVdZQCEnQD1UAHaRSigbB1d54GEjZ3YX1VdWbgBi/"
    @"stJOOMJ9IIigANZmdid+txVCKOQBrnoigHwJgQiJoVOSFAMKbWWo5HjnJAjwFI2WRWHfRE2IEasKhjKQg0COZgVZbWHGI/"
    @"commk6rktJCWRsK5n0+UeUakm1veBcuaADGJHZ9BVgZAVUNeIGaap+"
    @"SZKAVjliZBgVnu6WefkMUCqGCKMorXct75ZmmmmJ4CU3goGopBpAqqCmh8YVJpZycCAvponYTWh5sEeRZAZ4twspqJgHkKCmyuT1pVQYdT/"
    @"gbrKSbQUfrrsZcWqiwFciZ0I67VckuqKL4dINxGKjaLbKrXUsDdmYN2226lpTwFEJ1bUeUlQRjUG1aJlF7lF4b2BjYVfnkS4C+4T237WIKtouQtQl/"
    @"RFBFH7G4CH0cKL+xwZPy59VDEMVmgpIGjVDSyg9N+GlKy+k3GEMgLUkCpg6bA5Q+"
    @"UBAyQMccro9syXwt9hSXNFAUMqj5IJ6300kw37fTTUEct9dRUV2311VhnrfXWXHft9ddghy322GSXbfbZaKet9tpst+3223DHLffcdNdt991456333nz37fffgAcu+"
    @"OCEF2744YgnrvjijDfu+OOQRy755JRXbvnlE5hnrvnmnHfu+eeghy766KR/EwEAOw==";

NSString *const STImageResourceSaveToAlbumBase64String =
    @"iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA3BpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/"
    @"eHBhY2tldCBiZWdpbj0i77u/" @"IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+"
    @"IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNS1jMDIxIDc5LjE1NDkxMSwgMjAxMy8xMC8yOS0xMTo0NzoxNiAgICAgIC"
    @"AgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6"
    @"eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxucz"
    @"p4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDpmMjg1YzVlMi1iMGQwLTQxN2EtYjI4OS0xMDliMDhjYmEyYTAi"
    @"IHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6OERERDgzRkMzNDFEMTFFNEIxNTg5MDUzOUVDNjUwM0EiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6OERERDgzRkIzNDFEMTFFNEIxNT"
    @"g5MDUzOUVDNjUwM0EiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTQgKE1hY2ludG9zaCkiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0i"
    @"eG1wLmlpZDo5QzM5OUVERDM0MUMxMUU0QjE1ODkwNTM5RUM2NTAzQSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo5QzM5OUVERTM0MUMxMUU0QjE1ODkwNTM5RUM2NTAzQSIvPiA8L3"
    @"JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/"
    @"PiUjP3MAAAGeSURBVHja7JlLSgNBEIZnJEsJLiOCiQsxR4ig4AtBeqc3MJfwBOIhFD2Bu0GQiIKCmBMIbty5FeN+/"
    @"ItUg7Y9nRFTpger4KcTpmvyfcxkHnSa53lS5UpVQAUEBLIsW8RwhGwh9YLeO2PMKuaG9m93nhZNwD7o927xcaVgyhvSQw4w98ndOOWBX8LQR3YD8EGoMVedWfrM9qVqnoZDZAa5QLqwfpE"
    @"mpCNZtA3QsxhOkB1m2wseAT5tkr+CLyFHDF3+uj3yFLKnTQzwjgTVdBmBSpUKqIAKqIAKqIAKqIAK/HOBeX7la/6gh+Zece/"
    @"EBU6RTeS6pATNuUE2kLMYBOht6RlZYLBmCfgW9+zHIEAg6zy2AhIuvO2J4k88SkIEftxXIZ+"
    @"ELRF4icuoK2FLBF7qPuADFYGXvJFZ4AfOmgQ8VU3wJknAHX2UUAEVUAEVqJwArUnZlZEoCiwN/vheRqDH4/"
    @"GnxknCzyXDJSaqS3f7t1VKNLQx3CfDdbKY6hVZNsY8Bo8AT6BHgHNkEAH4gFk6Lrz3CFStVEAFflkfAgwArNuJtxMPtwEAAAAASUVORK5CYII=";
