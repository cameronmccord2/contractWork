//
//  Popups+Extras.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "Popups.h"

@interface Popups (Extras)

+(Popups *)parsePopupFromDictionary:(NSDictionary *)dictionary forMedia:(Medias *)media intoContext:(NSManagedObjectContext *)context;

@end
