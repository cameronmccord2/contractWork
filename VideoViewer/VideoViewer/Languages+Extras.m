//
//  Languages+Extras.m
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "Languages+Extras.h"

@implementation Languages (Extras)

+(Languages *)parseLanguageFromDictionary:(NSDictionary *)dictionary intoContext:(NSManagedObjectContext *)context {
    
    NSNumber *languageId = dictionary[@"id"];
    NSError *error = nil;
    Languages *language = [[CoreDataTemplates getListForEntity:@"Languages" withPredicate:[NSPredicate predicateWithFormat:@"languageId == %@", languageId] forContext:context error:&error] firstObject];
    if (error) {
        DLog(@"error getting the language for parsing");

    }else if (language == nil){
        
        language = [NSEntityDescription insertNewObjectForEntityForName:@"Languages" inManagedObjectContext:context];
        [CoreDataTemplates mapKeys:[NSSet setWithArray:@[@"name", @"code1", @"code2", @"nativeName"]]
                    fromDictionary:dictionary
                   toManagedObject:language];
        language.languageId = languageId;
    }
    return language;
}

@end
