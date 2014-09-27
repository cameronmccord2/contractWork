//
//  Languages+Extras.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "Languages.h"

@interface Languages (Extras)

+(Languages *)parseLanguageFromDictionary:(NSDictionary *)dictionary intoContext:(NSManagedObjectContext *)context;

@end
