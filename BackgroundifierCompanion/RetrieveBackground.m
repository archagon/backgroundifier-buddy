//
//  RetrieveBackground.m
//  BackgroundifierCompanion
//
//  Created by Alexei Baboulevitch on 2018-4-21.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

#import <sqlite3.h>
#import "RetrieveBackground.h"

@implementation RetrieveBackground

+(NSString*) backgroundForDesktop:(NSUInteger)desktop screen:(NSUInteger)screen
{
    NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* dbPath = [dirs[0] stringByAppendingPathComponent:@"Dock/desktoppicture.db"];
    
    sqlite3* db;
    
    if (sqlite3_open(dbPath.UTF8String, &db) == SQLITE_OK)
    {
        sqlite3_stmt* statement;
        const char *sql = "SELECT * FROM data";
        
        if (sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK)
        {
            NSString* file;
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                file = @((char*)sqlite3_column_text(statement, 0));
                //printf("%s/%s\n", @"".UTF8String, file.UTF8String);
            }
            
            printf("Final: %s/%s\n\n", @"".UTF8String, file.UTF8String);
            sqlite3_finalize(statement);
        }
        
        sqlite3_close(db);
    }
    
    return @"";
}

@end
