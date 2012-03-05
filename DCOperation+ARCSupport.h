//
//  DCOperation+ARCSupport.h
//
//  Created by David Cairns on 2/29/12.
//  Copyright (c) 2012 David Cairns. All rights reserved.
//

#ifndef eNotes_DCOperation_ARCSupport_h
#define eNotes_DCOperation_ARCSupport_h

#ifndef DC_USE_ARC
#define DC_USE_ARC __has_feature(objc_arc)
#endif

#if DC_USE_ARC
#define DC_RETAIN(xx) (xx)
#define DC_RELEASE(xx)
#define DC_AUTORELEASE(xx) (xx)
#else
#define DC_RETAIN(xx)           [xx retain];
#define DC_RELEASE(xx)          [xx release];
#define DC_AUTORELEASE(xx)      [xx autorelease];
#endif

#endif
