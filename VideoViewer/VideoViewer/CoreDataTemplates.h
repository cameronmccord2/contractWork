//
//  CoreDataTemplates.h
//  SLE
//
//  Created by Cameron McCord on 7/9/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataTemplates : NSObject

+(void)saveContext:(NSManagedObjectContext *)context sender:(id)sender;
+(NSArray *)getListForEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error;
+(NSArray*)managedObjectsFromJSONStructure:(NSString*)json withManagedObjectContext:(NSManagedObjectContext*)context;
+(NSString*)jsonStructureFromManagedObjects:(NSArray*)managedObjects maxDepth:(NSInteger)maxDepth;
//+(void)mapNumbersFromKeys:(NSSet *)keys fromDictionary:(NSDictionary *)dictionary toManagedObject:(NSManagedObject *)object;
//+(void)mapStringsFromKeys:(NSSet *)keys fromDictionary:(NSDictionary *)dictionary toManagedObject:(NSManagedObject *)object;
+(void)mapKeys:(NSSet *)keys fromDictionary:(NSDictionary *)dictionary toManagedObject:(NSManagedObject *)object;
+(NSDictionary *)mirroredDictionaryFromKeys:(NSSet *)keys;
+(void)deleteAllObjectsWithEntityDescription:(NSString *)entityDescription context:(NSManagedObjectContext *)context;

@end
