//
//  ScreenshotProcessUtilities.hpp
//  test
//
//  Created by yeshuai on 2016-11-20.
//  Copyright © 2016 ys. All rights reserved.
//

#pragma once
#import <opencv2/core/core.hpp>
#import <opencv2/opencv.hpp>
#include <opencv2/imgcodecs/ios.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


CGPoint matchTemplate(UIImage *source, UIImage *pattern, float threshold, cv::Rect mask=cv::Rect());
std::vector<CGPoint> matchTemplateMultiple(UIImage *source, UIImage *pattern, float threshold, cv::Rect mask=cv::Rect());
CGPoint detectScroll(UIImage *source, cv::Rect mask);
