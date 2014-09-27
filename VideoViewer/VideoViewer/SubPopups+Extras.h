//
//  SubPopups+Extras.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "SubPopups.h"

@interface SubPopups (Extras)

+(SubPopups *)parseSubPopupFromDictionary:(NSDictionary *)dictionary forPopup:(Popups *)popup intoContext:(NSManagedObjectContext *)context;

@end
