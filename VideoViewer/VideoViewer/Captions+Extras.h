//
//  Captions+Extras.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "Captions.h"

@interface Captions (Extras)

+(Captions *)parseCaptionFromDictionary:(NSDictionary *)dictionary forMedia:(Medias *)media intoContext:(NSManagedObjectContext *)context;

@end
