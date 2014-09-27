//
//  Medias+Extras.h
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "Medias.h"

@interface Medias (Extras)

+(Medias *)parseMediaFromDictionary:(NSDictionary *)dictionary forLanguage:(Languages *)language intoContext:(NSManagedObjectContext *)context;

@end
