//
//  CoreDataTemplates.m
//  SLE
//
//  Created by Cameron McCord on 7/9/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import "CoreDataTemplates.h"
#import "NSDictionary+SafeJson.h"

@implementation CoreDataTemplates

+(void)saveContext:(NSManagedObjectContext *)context sender:(id)sender {
	NSError *e = nil;
	BOOL saved = [context save:&e];
	if (!saved) {
		NSString *callingFunction = [NSString stringWithFormat:@"%@",[[NSThread callStackSymbols] objectAtIndex:1]];
		callingFunction = [[callingFunction componentsSeparatedByString:@"["] objectAtIndex:1];
		callingFunction = [[callingFunction componentsSeparatedByString:@"]"] objectAtIndex:0];
		DLog(@"Whoops, couldn't save for sender: %@, error: %@, sent from: [%@]", NSStringFromClass([sender class]), [e.description stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"], callingFunction);
	}else{
        //		DLog(@"No errors! Saving complete. ALL DONE!");
	}
}

+(NSArray *)getListForEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:predicate];
	NSArray *results = [context executeFetchRequest:fetchRequest error:error];
	if (*error != nil)
		return nil;
	else
		return results;
}

+(NSDictionary*)dataStructureFromManagedObject:(NSManagedObject*)managedObject depth:(NSInteger)depth maxDepth:(NSInteger)maxDepth{
	if (depth == maxDepth) {
		return [NSDictionary new];
	}
	NSDictionary *attributesByName = [[managedObject entity] attributesByName];
	NSMutableDictionary *relationshipsByName = [[[managedObject entity] relationshipsByName] mutableCopy];
	[relationshipsByName removeObjectForKey:@"testHistoryStatuses"];
	[relationshipsByName removeObjectForKey:@"testsNeedToTake"];
	[relationshipsByName removeObjectForKey:@"assessments"];
	//	DLog(@"%@", relationshipsByName);
	NSMutableDictionary *valuesDictionary = [[managedObject dictionaryWithValuesForKeys:[attributesByName allKeys]] mutableCopy];
	[valuesDictionary setObject:[[managedObject entity] name] forKey:@"ManagedObjectName"];
	for (NSString *relationshipName in [relationshipsByName allKeys]) {
		NSRelationshipDescription *description = [[[managedObject entity] relationshipsByName] objectForKey:relationshipName];
		if (![description isToMany]) {
			NSManagedObject *relationshipObject = [managedObject valueForKey:relationshipName];
			[valuesDictionary setObject:[CoreDataTemplates dataStructureFromManagedObject:relationshipObject depth:depth+1 maxDepth:maxDepth] forKey:relationshipName];
			continue;
		}
		
		NSSet *relationshipObjects = [managedObject mutableSetValueForKeyPath:relationshipName];//[managedObject objectForKey:relationshipName];
		NSMutableArray *relationshipArray = [[NSMutableArray alloc] init];
		for (NSManagedObject *relationshipObject in relationshipObjects) {
			[relationshipArray addObject:[CoreDataTemplates dataStructureFromManagedObject:relationshipObject depth:depth+1 maxDepth:maxDepth]];
		}
		[valuesDictionary setObject:relationshipArray forKey:relationshipName];
	}
	[valuesDictionary removeObjectForKey:@"recieved"];
	return valuesDictionary;
}

+(NSArray*)dataStructuresFromManagedObjects:(NSArray*)managedObjects maxDepth:(NSInteger)maxDepth
{
	NSMutableArray *dataArray = [[NSMutableArray alloc] init];
	for (NSManagedObject *managedObject in managedObjects) {
		NSDictionary *d = [CoreDataTemplates dataStructureFromManagedObject:managedObject depth:1 maxDepth:maxDepth];
		[dataArray addObject:[d removeNullValues]];
	}
	return dataArray;
}

+(NSString*)jsonStructureFromManagedObjects:(NSArray*)managedObjects maxDepth:(NSInteger)maxDepth
{
	NSArray *objectsArray = [CoreDataTemplates dataStructuresFromManagedObjects:managedObjects maxDepth:maxDepth];
	NSError *error = nil;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objectsArray options:0 error:&error];
	NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	DLog(@"%@", jsonString);
	return jsonString;
}

+(NSManagedObject*)managedObjectFromStructure:(NSDictionary*)structureDictionary withManagedObjectContext:(NSManagedObjectContext*)moc
{
	NSString *objectName = [structureDictionary objectForKey:@"ManagedObjectName"];
	NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:objectName inManagedObjectContext:moc];
	[managedObject setValuesForKeysWithDictionary:structureDictionary];
	
	for (NSString *relationshipName in [[[managedObject entity] relationshipsByName] allKeys]) {
		NSRelationshipDescription *description = [[[managedObject entity] relationshipsByName] objectForKey:relationshipName];
		if (![description isToMany]) {
			NSDictionary *childStructureDictionary = [structureDictionary objectForKey:relationshipName];
			NSManagedObject *childObject = [CoreDataTemplates managedObjectFromStructure:childStructureDictionary withManagedObjectContext:moc];
			[managedObject setValue:childObject forKey:relationshipName]; //setObject:childObject forKey:relationshipName];
			continue;
		}
		NSMutableSet *relationshipSet = [managedObject mutableSetValueForKeyPath:relationshipName];
		NSArray *relationshipArray = [structureDictionary objectForKey:relationshipName];
		for (NSDictionary *childStructureDictionary in relationshipArray) {
			NSManagedObject *childObject = [CoreDataTemplates managedObjectFromStructure:childStructureDictionary withManagedObjectContext:moc];
			[relationshipSet addObject:childObject];
		}
	}
	return managedObject;
}

+(NSArray*)managedObjectsFromJSONStructure:(NSString*)json withManagedObjectContext:(NSManagedObjectContext*)context
{
	NSError *error = nil;
	NSArray *structureArray = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
	NSAssert2(error == nil, @"Failed to deserialize\n%@\n%@", [error localizedDescription], json);
	NSMutableArray *objectArray = [[NSMutableArray alloc] init];
	for (NSDictionary *structureDictionary in structureArray) {
		[objectArray addObject:[CoreDataTemplates managedObjectFromStructure:structureDictionary withManagedObjectContext:context]];
	}
	return objectArray;
}


//+(void)mapStringsFromKeys:(NSSet *)keys fromDictionary:(NSDictionary *)dictionary toManagedObject:(NSManagedObject *)object {
//	for (NSString *key in keys) {
//        NSObject *value = [NSString stringWithFormat:@"%@", dictionary[key]];
//		[object setValue:value forKey:key];
//	}
//}
//
//+(void)mapNumbersFromKeys:(NSSet *)keys fromDictionary:(NSDictionary *)dictionary toManagedObject:(NSManagedObject *)object {
//	for (NSString *key in keys) {
//		[object setValue:@([dictionary[key] longValue]) forKey:key];
//	}
//}

+(void)mapKeys:(NSSet *)keys fromDictionary:(NSDictionary *)dictionary toManagedObject:(NSManagedObject *)object {
	for (NSString *key in keys) {
		[object setValue:dictionary[key] forKey:key];
	}
}

+(NSDictionary *)mirroredDictionaryFromKeys:(NSSet *)keys {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
	for (NSString *key in keys) {
		[dictionary setObject:key forKey:key];
	}
	return dictionary;
}

+(void)deleteAllObjectsWithEntityDescription:(NSString *)entityDescription context:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
    
    
    for (NSManagedObject *managedObject in items) {
        [context deleteObject:managedObject];
    }
    [CoreDataTemplates saveContext:context sender:self];
}

@end
