//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

@interface XCDeviceEvent : NSObject <NSSecureCoding>
{
    unsigned int _eventPage;
    unsigned int _usage;
    double _duration;
}
@property double duration; // @synthesize duration=_duration;
@property unsigned int usage; // @synthesize usage=_usage;
@property unsigned int eventPage; // @synthesize eventPage=_eventPage;

+ (id)deviceEventWithPage:(unsigned int)arg1 usage:(unsigned int)arg2 duration:(double)arg3;

@end
