//
//  main.m
//  mongo-test
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOD_internal.h"

bson *bson_from_json(const char *json, size_t length, int *error, size_t *totalProcessed);

MODServer *server;

@interface MongoDelegate : NSObject<MODServerDelegate, MODDatabaseDelegate>
- (void)mongoServerConnectionSucceded:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoServerConnectionFailed:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
@end

@implementation MongoDelegate

- (void)logQuery:(MODQuery *)query fromSelector:(SEL)selector
{
    NSLog(@"%@ %@", NSStringFromSelector(selector), query.parameters);
}

- (void)mongoServerConnectionSucceded:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServerConnectionFailed:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServer:(MODServer *)mongoServer serverStatusFetched:(NSArray *)serverStatus withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServer:(MODServer *)mongoServer databaseListFetched:(NSArray *)list withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    MODDatabase *database;
    
    [self logQuery:mongoQuery fromSelector:_cmd];
    database = [mongoServer databaseForName:[list objectAtIndex:1]];
    NSLog(@"database: %@", database.databaseName);
    database.delegate = self;
    [database fetchDatabaseStats];
    [database fetchCollectionList];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase databaseStatsFetched:(NSArray *)databaseStats withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionListFetched:(NSArray *)collectionList withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

@end

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        bson *result;
        char *json;
        int error;
        size_t processed;
        
        json = "{ \"test\":1, \"zob\" :[\"xx\"] }";
        result = bson_from_json(json, strlen(json), &error, &processed);
        bson_print(result);
        NSLog(@"error %d, processed %lu", error, processed);
        NSLog(@"%@", [MODServer objectsFromBson:result]);
        exit(0);
        
        MongoDelegate *delegate;
        const char *ip;

        ip = argv[1];
        delegate = [[MongoDelegate alloc] init];
        server = [[MODServer alloc] init];
        server.delegate = delegate;
        [server connectWithHostName:[NSString stringWithUTF8String:ip]];
        [server fetchServerStatus];
        [server fetchDatabaseList];
        
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

