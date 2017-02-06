//
//  ScreenshotProcessUtilities.cpp
//  test
//
//  Created by yeshuai on 2016-11-20.
//  Copyright © 2016 ys. All rights reserved.
//


#include "openCVUtility.h"

//algorithms to look at:
//http://docs.opencv.org/2.4/doc/tutorials/imgproc/histograms/template_matching/template_matching.html
//http://docs.opencv.org/2.4/modules/gpu/doc/object_detection.html#gpu-hogdescriptor

std::vector<CGPoint> matchTemplateMultiple(UIImage *source, UIImage *pattern, float threshold, cv::Rect mask) {
    std::vector<CGPoint> points;
    bool cropped = mask.width != 0 && mask.height != 0;
    cv::Mat img;
    if (cropped) {
        img = cv::Mat(mask.height, mask.width, CV_32FC1);
        cv::Mat temp;
        UIImageToMat(source, temp);
        temp(mask).copyTo(img);
    } else {
        UIImageToMat(source, img);
    }
    cv::Mat templ;
    UIImageToMat(pattern, templ);
    int result_cols = img.cols - templ.cols + 1;
    int result_rows = img.rows - templ.rows + 1;
    cv::Mat result(result_rows, result_cols, CV_32FC1);
    cv::matchTemplate(img, templ, result, CV_TM_SQDIFF_NORMED);
    for(int i = 0; i < result.rows; i++) {
        const float* Mi = result.ptr<float>(i);
        for(int j = 0; j < result.cols; j++)
            if (Mi[j] < threshold) {
                CGPoint point = CGPointMake((j + templ.cols/2.0)/2, (i + templ.rows/2.0)/2);
                if (cropped) {
                    point.x += mask.x/2;
                    point.y += mask.y/2;
                }
                NSLog(@"找到模板: %.1f, %.1f 相似度: %f", point.x, point.y, Mi[j]);
                points.push_back(point);
            }
    }
    return points;
}

CGPoint matchTemplate(UIImage *source, UIImage *pattern, float threshold, cv::Rect mask) {
    bool cropped = mask.width != 0 && mask.height != 0;
    cv::Mat img;
    if (cropped) {
        img = cv::Mat(mask.height, mask.width, CV_32FC1);
        cv::Mat temp;
        UIImageToMat(source, temp);
        temp(mask).copyTo(img);
    } else {
        UIImageToMat(source, img);
    }
    cv::Mat templ;
    UIImageToMat(pattern, templ);
    int result_cols = img.cols - templ.cols + 1;
    int result_rows = img.rows - templ.rows + 1;
    cv::Mat result(result_rows, result_cols, CV_32FC1);
    cv::matchTemplate(img, templ, result, CV_TM_SQDIFF_NORMED);
    double minVal; double maxVal; cv::Point minLoc; cv::Point maxLoc;
    cv::minMaxLoc(result, &minVal, &maxVal, &minLoc, &maxLoc, cv::Mat());
    img.release();
    result.release();
    templ.release();
    NSLog(@"差异: %.1f", minVal * 100);
    if (minVal > threshold) return CGPointMake(-1, -1);
    float x = (minLoc.x + templ.cols/2.0)/2;
    float y = (minLoc.y + templ.rows/2.0)/2;
    if (cropped) {
        x += mask.x/2;
        y += mask.y/2;
    }
    return CGPointMake(x, y);
}

CGPoint detectScroll(UIImage *source, cv::Rect mask) {
    bool cropped = mask.width != 0 && mask.height != 0;
    cv::Mat img, HSV;
    if (cropped) {
        img = cv::Mat(mask.height, mask.width, CV_32FC1);
        cv::Mat temp;
        UIImageToMat(source, temp);
        temp(mask).copyTo(img);
    } else {
        UIImageToMat(source, img);
    }
    cv::Mat threshold(img.size(), CV_8U);
    cv::cvtColor(img, HSV, cv::COLOR_RGB2HSV);
    cv::inRange(HSV, cv::Scalar(15, 55, 170), cv::Scalar(25, 105, 235), threshold);
//    UIImage *test = MatToUIImage(threshold);
    std::vector<std::vector<cv::Point>> contours;
    cv::erode(threshold, threshold, cv::getStructuringElement(cv::MORPH_CROSS, cv::Size(3, 3)));
    cv::dilate(threshold, threshold, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(8, 8)));
    cv::findContours(threshold, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    float maxArea = 700;
    CGPoint center = CGPointMake(-1, -1);
    for(int i = 0; i < contours.size(); i++ ) {
        cv::Moments mu = moments(contours[i], false);
        if (mu.m00 > maxArea) {
            maxArea = mu.m00;
            center = CGPointMake(mu.m10/mu.m00, mu.m01/mu.m00);
        }
    }
    return center;
}
