//
//  yysHelperUITests.m
//  yysHelperUITests
//
//  Created by yeshuai on 2016-11-18.
//  Copyright © 2016 ys. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCUIApplication.h"
#import "XCUIElement.h"
#import "XCAXClient_iOS.h"
#import "openCVUtility.h"
#import "XCEventGenerator.h"
#import <array>
#import <stdatomic.h>

typedef NS_ENUM(NSInteger, gameState) {
    Login,
    Yard,
    Explore,
    Chapter,
    Battle,
    Reward,
    TuPo,
    YuHun,
};

@interface yysHelperUITests : XCTestCase
@property (nonatomic) id <UICoordinateSpace> coordinateSpace;
@property (nonatomic) float                  systemVersion;

@property (nonatomic, strong) XCUIApplication   *yys;

@property (nonatomic, strong) XCEventGenerator         *evt;
@property (nonatomic, strong) XCEventGeneratorHandler  evtHandler;
@property (nonatomic, strong) NSDictionary      *templates;

@property (nonatomic) gameState currentStage;
@property (nonatomic) int       energy;
@property (nonatomic) cv::Ptr<cv::ml::KNearest> knn;
@end

@implementation yysHelperUITests

#pragma mark - Setup

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    [self loadTemplates];
    
    self.coordinateSpace = [[UIScreen mainScreen] coordinateSpace];
    self.systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
}

- (void)tearDown {
    [super tearDown];
}

- (void)loadTemplates {
    NSLog(@"载入模板...");
    
    NSMutableDictionary *templates = [[NSMutableDictionary alloc] init];
    static NSArray* templateNames;
    templateNames =
    @[
      @"back",
      @"battle",
      @"battleBoss",
      @"chest",
      @"confirm",
      @"explore",
      @"landing",
      @"lantern",
      @"chapter17",
      @"chapter16",
      @"logo",
      @"full",
      @"level1",
      @"test",
      @"battling",
      @"watching",
      @"clickToSetup",
      @"locked",
      @"lockText",
      @"ability",
      @"back2",
      @"drum",
      @"breakThrough",
      @"refresh",
      @"done",
      @"attack",
      @"startBattle",
      @"confirm2",
      @"invite",
      @"close",
      @"arrow",
      @"N",
      @"all",
      @"one", @"two", @"three", @"four", @"five", @"six", @"seven", @"eight", @"nine", @"zero"
      ];
    
    for (NSString* str in templateNames) {
        UIImage *img = [UIImage imageNamed:str inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        NSAssert(img != nil, @"没找到图片: %@", str);
        [templates setObject:img forKey:str];
    }
    
    self.templates = templates;
    NSLog(@"模板已载入");
}

#pragma mark - Tests

- (void)testRestart {
    [self laucnch];
    [self login];
    [self yard];
}

- (void)testGouLiang {
    [self resolve];
    [self startDogFoodPipline];
}

- (void)testTuPo {
    [self resolve];
    [self startTuPoPipeline];
}

- (void)testYuhun {
    [self resolve];
    [self startYuHunPipeline];
}

- (void)testTest {
    [self resolve];
    self.currentStage = Battle;
    std::array<BOOL, 2> didSwapDogFood = [self checkFullLevel];
}

#pragma mark - Pipelines

- (void)startDogFoodPipline {
    while(YES) {
        while(![self findTemplate:@"breakThrough" tap:NO]);
        int tickets =  [self readNumber:[self getScreenshot] mask:cv::Rect(794, 20, 60, 19)];
        NSLog(@"当前突破券: %d", tickets);
        if (tickets >= 15) [self startTuPoPipeline];
        self.energy = [self readNumber:[self getScreenshot] mask:cv::Rect(1001, 21, 51, 19)];
        NSLog(@"当前体力: %d", self.energy);
        if (self.energy < 3) {
            NSLog(@"体力刷完了");
            break;
        }
        [self explore];
        if ([self chapter]) [self collectChest];
        else [self exitToExplore];
    }
}

- (void)startTuPoPipeline {
    self.currentStage = TuPo;
    int tickets =  [self readNumber:[self getScreenshot] mask:cv::Rect(794, 20, 60, 19)];
    cv::Size boxSize(345, 135);
    static std::array<cv::Point2f, 9> boxOrigins = {
        cv::Point2f(140, 95),
        cv::Point2f(495, 95),
        cv::Point2f(855, 95),
        cv::Point2f(140, 240),
        cv::Point2f(495, 240),
        cv::Point2f(855, 240),
        cv::Point2f(140, 380),
        cv::Point2f(495, 380),
        cv::Point2f(855, 380)
    };
    while(![self findTemplate:@"breakThrough" tap:NO]);
    [self confirmTapped:YES onTemplate:@"breakThrough" withMask:cv::Rect()];
    while (tickets > 0) {
        int finished = 0;
        for (int i = 0; i < 9 && tickets > 0; i++) {
            while (![self findTemplate:@"refresh" tap:NO threshold:0.01 mask:cv::Rect(1050, 535, 120, 50)]) sleep(1);
            cv::Point2f origin = boxOrigins[i];
            if (((finished < i) && (finished > 5)) || ((finished < i - 3) && (finished > 2))) {
                NSLog(@"刷新");
                while(![self findTemplate:@"refresh" tap:YES threshold:0.01 mask:cv::Rect(1050, 535, 120, 50)]);
                while(![self findTemplate:@"confirm" tap:YES threshold:0.01 mask:cv::Rect()]);
                break;
            }
            if (![self findTemplate:@"done" tap:NO threshold:0.01 mask:cv::Rect(origin, boxSize)]) {
                NSLog(@"正在突破: %d", i + 1);
                CGPoint center = CGPointMake((origin.x + boxSize.width/2.0)/2.0, (origin.y + boxSize.height/2.0)/2.0);
                [self tapPoint:center numberOfTaps:1];
                while(![self findTemplate:@"attack" tap:YES threshold:0.01 mask:cv::Rect(center.x * 2, center.y * 2, 150, 150)]);
                tickets--;
                while(![self findTemplate:@"drum" tap:NO threshold:0.01 mask:cv::Rect()]);
                [self tapPoint:CGPointMake(1200/2.0, 600/2.0) numberOfTaps:2];
                while (![self findTemplate:@"arrow" tap:NO threshold:0.01 mask:cv::Rect()]) {
                    [self tapPoint:CGPointMake(320/2.0, 140/2.0) numberOfTaps:1];
                }
                while (![self findTemplate:@"refresh" tap:NO threshold:0.01 mask:cv::Rect(1050, 535, 120, 50)]) {
                    sleep(1);
                    [self tapPoint:CGPointMake(660/2.0, 550/2.0) numberOfTaps:1];
                }
                if ([self findTemplate:@"done" tap:NO threshold:0.01 mask:cv::Rect(origin, boxSize)]) {
                    finished++;
                    NSLog(@"赢了");
                }
            } else {
                finished++;
            }
        }
    }
    [self findTemplate:@"close" tap:YES];
}

- (void)startYuHunPipeline {
    self.currentStage = YuHun;
    while (YES) {
        //        [self confirmTapped:NO onTemplate:@"startBattle" withMask:cv::Rect()];
        //        while ([self findTemplate:@"invite" tap:NO threshold:0.01 mask:cv::Rect()]);
        while(![self findTemplate:@"startBattle" tap:NO]);
        self.energy = [self readNumber:[self getScreenshot] mask:cv::Rect(1035, 127, 52, 19)];
        NSLog(@"当前体力: %d", self.energy);
        if (self.energy < 4) break;
        [self confirmTapped:YES onTemplate:@"startBattle" withMask:cv::Rect()];
        while(![self findTemplate:@"drum" tap:NO threshold:0.01 mask:cv::Rect()]);
        [self tapPoint:CGPointMake(1200/2.0, 600/2.0) numberOfTaps:2];
        while (![self findTemplate:@"confirm2" tap:YES threshold:0.01 mask:cv::Rect(730,429,127,43)]) {
            [self tapPoint:CGPointMake(990/2.0, 140/2.0) numberOfTaps:1];
        }
        [self optionalTapped:YES onTemplate:@"confirm2" withMask:cv::Rect(730,429,127,43)];
    }
}

- (void)login {
    self.currentStage = Login;
    while(![self findTemplate:@"logo" tap:NO threshold:0.05 mask:cv::Rect()]) [self tapPoint:CGPointMake(100, 100) numberOfTaps:1];
    [self tapPoint:CGPointMake(333.5, 300) numberOfTaps:1];
    while(![self findTemplate:@"landing" tap:NO threshold:0.01 mask:cv::Rect()]);
    [self tapPoint:CGPointMake(333.5, 300) numberOfTaps:1];
}

- (void)yard {
    self.currentStage = Yard;
    while(![self findTemplate:@"lantern" tap:YES threshold:0.03 mask:cv::Rect()]);
}

- (void)explore {
    self.currentStage = Explore;
    NSLog(@"搜索第十七章...");
    [self confirmTapped:YES onTemplate:@"chapter16" withMask:cv::Rect(1140, 140, 130, 480)];
    [self confirmTapped:YES onTemplate:@"explore" withMask:cv::Rect()];
}

- (BOOL)chapter {
    self.currentStage = Chapter;
    NSLog(@"进入关卡");
    [self confirmTapped:NO onTemplate:@"back" withMask:cv::Rect(0, 0, 100, 100)];
    NSLog(@"取消锁定出战式神...");
    [self optionalTapped:YES onTemplate:@"locked" withMask:cv::Rect(1000, 640, 160, 100)];
    BOOL isBoss = NO;
    while(YES) {
        if (self.energy < 3) return NO;
        NSLog(@"找怪中...");
        int searchCount = 0;
        while(!((isBoss = [self findTemplate:@"battleBoss" tap:YES threshold:0.01 mask:cv::Rect()]) || [self findTemplate:@"battle" tap:YES threshold:0.01 mask:cv::Rect(0, 150, 1334, 450)])) {
            //[self findEXPBoost]
            if (++searchCount >= 5) {
                NSLog(@"并没有找到怪");
                return NO;
            }
            [self tapPoint:CGPointMake(500, 280) numberOfTaps:1];
        }
        sleep(2);
        if (![self findTemplate:@"lockText" tap:NO threshold:0.015 mask:cv::Rect(1060, 650, 220, 60)]) {
            [self battle];
            if (isBoss) return YES;
        }
    }
    return NO;
}

- (void)battle {
    self.currentStage = Battle;
    [self confirmTapped:NO onTemplate:@"clickToSetup" withMask:cv::Rect()];
    std::array<BOOL, 2> didSwapDogFood = [self checkFullLevel];
    [self confirmTapped:NO onTemplate:@"drum" withMask:cv::Rect()];
    while([self findTemplate:@"drum" tap:NO threshold:0.01 mask:cv::Rect()]) [self tapPoint:CGPointMake(1200/2.0, 600/2.0) numberOfTaps:1];
    NSLog(@"战斗中..." );
    if (didSwapDogFood[1]) [self confirmTapped:YES onTemplate:@"ability" withMask:cv::Rect(850, 680, 115, 70)];
    if (didSwapDogFood[0]) [self confirmTapped:YES onTemplate:@"ability" withMask:cv::Rect(965, 680, 115, 70)];
    while(![self findTemplate:@"lockText" tap:NO threshold:0.03 mask:cv::Rect(1060, 650, 220, 60)]) {
        [self tapPoint:CGPointMake(513, 150) numberOfTaps:1];
    }
    NSLog(@"打完了");
    self.energy -= 3;
}

- (void)collectChest {
    while(![self findTemplate:@"chapter17" tap:NO threshold:0.01 mask:cv::Rect()]) {
        [self optionalTapped:YES onTemplate:@"chest" withMask:cv::Rect()];
        [self tapPoint:CGPointMake(100, 100) numberOfTaps:1];
    }
    self.currentStage = Explore;
}

- (void)exitToExplore {
    NSLog(@"退出关卡...");
    [self confirmTapped:YES onTemplate:@"back" withMask:cv::Rect()];
    [self confirmTapped:YES onTemplate:@"confirm" withMask:cv::Rect()];
}

#pragma mark - Dog Food Utilities

- (std::array<BOOL, 2>)checkFullLevel {
    self.currentStage = Chapter;
    @autoreleasepool {
        UIImage* sc = [self getScreenshot];
        UIImage* templ = self.templates[@"full"];
        std::vector<CGPoint> positions = matchTemplateMultiple(sc, templ, 0.01, cv::Rect(227, 47, 362, 480));
        NSLog(@"找到%lu个满级狗粮", positions.size());
        return [self swapDogFood:positions];
    }
}

- (std::array<BOOL, 2>)swapDogFood:(std::vector<CGPoint>)positions {
    std::array<BOOL, 4> needSwap = {NO, NO, NO, NO};
    for (int i = 0; i < positions.size(); i++) {
        float x = positions[i].x, y = positions[i].y;
        needSwap[0] = (x > 195 && y > 115) || needSwap[0];
        needSwap[1] = x < 195 || needSwap[1];
        needSwap[3] = (x > 195 && y < 115) || needSwap[3];
    }
    if (needSwap[0] || needSwap[1]) {
        NSLog(@"检查战斗区狗粮");
        [self tapPoint:CGPointMake(536/2.0, 528/2.0) numberOfTaps:2];
        sleep(1.5);
        if (needSwap[0]) [self dragFrom:[self findNewDogFood] to:CGPointMake(669/2.0, 262/2.0)];
        if (needSwap[1]) {
//#warning need to specify mask here
            if ([self findTemplate:@"full" tap:NO mask:cv::Rect(1050, 100, 100, 320)]) {
                [self dragFrom:[self findNewDogFood] to:CGPointMake(1100/2.0, 225/2.0)];
                if (positions.size() - (needSwap[0]? 2 : 1) - (needSwap[3]? 1 : 0) != 0) needSwap[2] = YES;
            }
            else {
                needSwap[1] = NO;
                needSwap[2] = YES;
            }
        }
        while(![self findTemplate:@"back2" tap:YES threshold:0.01 mask:cv::Rect(0, 0, 100, 100)]);
    }
    if (needSwap[2] || needSwap[3]) {
        NSLog(@"更换观战区狗粮");
        [self tapPoint:CGPointMake(520/2.0, 240/2.0) numberOfTaps:2];
        sleep(1.5);
        if (needSwap[2]) [self dragFrom:[self findNewDogFood] to:CGPointMake(410/2.0, 262/2.0)];
//#warning need to find crorect point
        if (needSwap[3]) [self dragFrom:[self findNewDogFood] to:CGPointMake(822/2.0, 262/2.0)];
        while(![self findTemplate:@"back2" tap:YES threshold:0.01 mask:cv::Rect(0, 0, 100, 100)]);
    }
    return std::array<BOOL, 2> {needSwap[0], needSwap[1]};
}

- (CGPoint)findNewDogFood {
    NSLog(@"找狗粮中...");
#warning need to find correct mask
    sleep(1);
    if (![self findTemplate:@"N" tap:NO mask:cv::Rect()]) {
//        [self findTemplate:@"all" tap:YES mask:cv::Rect()];
        [self tapPoint:CGPointMake(71.0/2., 583/2.) numberOfTaps:1];
        while(![self findTemplate:@"N" tap:YES mask:cv::Rect()]);
    }
    CGPoint notFound = CGPointMake(-1, -1);
    int count = 90;
    while (--count > 0) {
        @autoreleasepool {
            UIImage *sc = [self getScreenshot];
            std::vector<CGPoint> positions = matchTemplateMultiple(sc, self.templates[@"level1"], 0.01, cv::Rect(170, 530, 930, 50));
            for (int i = 0; i < positions.size(); i++) {
                CGPoint point = positions[i];
                cv::Rect iconBoundary(point.x * 2, point.y * 2, 110, 150);
                CGPoint battling = matchTemplate(sc, self.templates[@"battling"], 0.01, iconBoundary);
                CGPoint watching = matchTemplate(sc, self.templates[@"watching"], 0.01, iconBoundary);
                NSLog(@"狗粮坐标: %f, %f", point.x, point.y);
                if (battling.x < 0 && watching.x < 0) {
                    point.x += 25;
                    point.y += 40;
                    NSLog(@"找到可用狗粮");
                    return point;
                } else {
                    NSLog(@"已参战或观战");
                }
            }
            [self dragFrom:CGPointMake(1060/2.0, 630/2.0) to:CGPointMake(230/2.0, 630/2.0)];
        }
    }
    return notFound;
}

#pragma mark - Accessibility Helper

- (void)resolve {
    XCUIApplication *springboard = [[XCUIApplication alloc] initPrivateWithPath:nil bundleID:@"com.apple.springboard"];
    [springboard resolve];
    XCUIElement *yys = [[springboard descendantsMatchingType:XCUIElementTypeAny]
                        elementMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", @"\u9634\u9633\u5e08"]
                        ];
    [yys tap];
    
    sleep(2);
    self.yys = [[XCUIApplication alloc] initPrivateWithPath:nil bundleID:@"com.netease.onmyoji"];
    [self.yys resolve];
    self.evt = [XCEventGenerator sharedGenerator];
    [[XCUIDevice sharedDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeLeft] forKey:@"orientation"];
    
    [self loadKnn];
}

- (void)laucnch {
    self.yys = [[XCUIApplication alloc] initPrivateWithPath:nil bundleID:@"com.netease.onmyoji"];
    [self.yys launch];
    
    [[XCUIDevice sharedDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeLeft] forKey:@"orientation"];
    self.evt = [XCEventGenerator sharedGenerator];
}

- (UIImage *)getScreenshot {
    return [[UIImage alloc] initWithData:[[XCAXClient_iOS sharedClient] screenshotData]];
}

- (CGPoint)mapPointToScreen:(CGPoint)p {
    CGPoint hitPoint;
    if (self.systemVersion >= 10 || self.currentStage == Login) {
        hitPoint.x = p.y;
        hitPoint.y = 667. - p.x;
    } else {
        hitPoint = p;
    }
    return hitPoint;
}

- (CGPoint)testMapPointToScreen:(CGPoint)p {
    CGPoint coord;
    if (self.systemVersion >= 10 || self.currentStage == Login) {
        coord.x = p.y / 375.0;
        coord.y = 1 - p.x / 667.0;
    } else {
        coord.x = p.x / 375.0;
        coord.y = p.y / 667.0;
    }
    return coord;
}

- (void)spinUntilCompletion:(void (^)(void(^completion)()))block
{
    __block volatile atomic_bool didFinish = false;
    block(^{
        atomic_fetch_or(&didFinish, true);
    });
    while (!atomic_fetch_and(&didFinish, false)) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

- (void)dragFrom:(CGPoint)p1 to:(CGPoint)p2 {
    [self spinUntilCompletion:^(void (^completion)(void)) {
        XCEventGeneratorHandler handlerBlock = ^(XCSynthesizedEventRecord *record, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to perform tap: %@", commandError);
            }
            completion();
        };
        [self.evt pressAtPoint:[self mapPointToScreen:p1] forDuration:0.2 liftAtPoint:[self mapPointToScreen:p2] velocity:1000. orientation:UIInterfaceOrientationLandscapeLeft name:@"drag" handler:handlerBlock];
    }];
    
}

- (void)tapPoint:(CGPoint)p numberOfTaps:(int)number{
    [self spinUntilCompletion:^(void (^completion)(void)) {
        CGPoint hitPoint = [self mapPointToScreen:p];
        XCEventGeneratorHandler handlerBlock = ^(XCSynthesizedEventRecord *record, NSError *commandError) {
            if (commandError) {
                NSLog(@"Failed to perform tap: %@", commandError);
            }
            completion();
        };
        [self.evt tapAtTouchLocations:@[[NSValue valueWithCGPoint:hitPoint]] numberOfTaps:number orientation:UIInterfaceOrientationLandscapeLeft handler:handlerBlock];
    }];
}

- (void)confirmTapped:(BOOL)tap onTemplate:(NSString *)str withMask:(cv::Rect)mask {
    if (tap) {
        while(![self findTemplate:str tap:YES threshold:0.01 mask:mask]);
        while([self findTemplate:str tap:YES threshold:0.01 mask:mask]);
    } else {
        while(![self findTemplate:str tap:NO threshold:0.01 mask:mask]);
    }
}

- (void)optionalTapped:(BOOL)tap onTemplate:(NSString *)str withMask:(cv::Rect)mask {
    if (tap) {
        while([self findTemplate:str tap:YES threshold:0.01 mask:mask]);
    }
}

#pragma mark - Digit Reading

- (void)loadKnn {
    using namespace cv;
    Ptr<ml::KNearest> knn(ml::KNearest::create());
    Mat_<float> trainFeatures(0, 228);
    NSArray *temp = @[@"one", @"two", @"three", @"four", @"five", @"six", @"seven", @"eight", @"nine", @"zero"];
    for (NSString *str in temp) {
        UIImage *img = self.templates[str];
        cv::Mat templ;
        cv::Mat_<float> flatten(1, 288);
        UIImageToMat(img, templ);
        flatten = templ.reshape(0, 1);
        trainFeatures.push_back(flatten);
    }
    
    Mat_<int> trainLabels(1,10);
    trainLabels << 1,2,3,4,5,6,7,8,9,0;
    knn->train(trainFeatures, ml::ROW_SAMPLE, trainLabels);
    self.knn = knn;
    NSLog(@"Knn已载入");
}

- (int)readNumber:(UIImage *)source mask:(cv::Rect)mask {
    using namespace cv;
    bool cropped = mask.width != 0 && mask.height != 0;
    Mat img, grey, binary;
    if (cropped) {
        img = cv::Mat(mask.height, mask.width, CV_32FC1);
        cv::Mat temp;
        UIImageToMat(source, temp);
        temp(mask).copyTo(img);
    } else {
        UIImageToMat(source, img);
    }
    cv::cvtColor(img, grey, cv::COLOR_RGB2GRAY);
    cv::threshold(grey, binary, 145, 255, THRESH_BINARY);
    bool empty = true;
    
    std::vector<int> verticalProj;
    unsigned char *input = (unsigned char*)(binary.data);
    for(int i = img.cols - 1;i >= 0; i--){
        float colSum = 0;
        for (int j = 0; j < img.rows; j++) {
            colSum += input[img.cols * j + i];
        }
        if ((colSum == 0 || i == 0) && empty == false) {
            verticalProj.push_back(i + ((i == 0 && colSum != 0)? 0 : 1));
            empty = true;
        }
        else if (colSum != 0 && empty == true) {
            verticalProj.push_back(i);
            empty = false;
        }
    }
    int result = 0;
    for(int i = 0; i < (int)verticalProj.size() - 1; i += 2) {
        cv::Rect range(verticalProj[i + 1], 0, verticalProj[i] - verticalProj[i + 1] + 1, binary.rows);
        cv::Mat digit(range.size(), CV_8U);
        binary(range).copyTo(digit);
        cv::Mat padded(digit.rows, 12, CV_8U);
        cv::copyMakeBorder(digit, padded, 0, 0, 0, 12 - digit.cols, cv::BORDER_CONSTANT, cv::Scalar(0.));
        result += [self readDigit:padded] * pow(10, i/2.);
    }
    return result;
}

- (float)readDigit:(cv::Mat)digit {
    NSAssert(digit.size() == cv::Size(12, 19), @"");
    using namespace cv;
    Mat_<float> testFeature;
    testFeature = digit.reshape(0, 1);
    Mat response,dist;
    self.knn->findNearest(testFeature, 1, noArray(), response, dist);
    return response.at<float>(0, 0);
}

#pragma mark - Pattern Matching

- (BOOL)findEXPBoost {
    @autoreleasepool {
        UIImage *sc = [self getScreenshot];
        CGPoint pos = detectScroll(sc, cv::Rect(0, 360, 1334, 300));
        if (pos.x < 0) {
            [self tapPoint:CGPointMake(500, 280) numberOfTaps:1];
            return NO;
        }
        cv::Rect box(fmin(fmax(pos.x - 300, 0), 1334 - 600), fmin(fmax(pos.y + 360 - 300, 0), 667 - 300), 600, 300);
        CGPoint position = matchTemplate(sc, self.templates[@"battle"], 0.01, box);
        if (position.x >= 0) {
            NSLog(@"Tapping: %f, %f", position.x, position.y);
            [self tapPoint:position numberOfTaps:1];
            return YES;
        }
        return NO;
    }
}

- (BOOL)findTemplate:(NSString *)str tap:(BOOL)tap {
    return [self findTemplate:str tap:tap threshold:0.01 mask:cv::Rect()];
}

- (BOOL)findTemplate:(NSString *)str tap:(BOOL)tap mask:(cv::Rect)mask{
    return [self findTemplate:str tap:tap threshold:0.01 mask:mask];
}

- (BOOL)findTemplate:(NSString *)str tap:(BOOL)tap threshold:(float)threshold mask:(cv::Rect)mask{
    @autoreleasepool {
        NSLog(@"找模板: %@", str);
        UIImage *sc = [self getScreenshot];
        CGPoint position = matchTemplate(sc, self.templates[str], threshold, mask);
        sc = nil;
        if (position.x >= 0) {
            NSLog(@"模板%@坐标: %.1f, %.1f",str, position.x, position.y);
            if (tap) [self tapPoint:position numberOfTaps:1];
            return YES;
        }
        return NO;
    }
}

@end
