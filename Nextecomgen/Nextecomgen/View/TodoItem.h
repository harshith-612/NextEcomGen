//
//  TodoItem.h
//  Nextecomgen
//
//  Created by Harshith on 07/07/26.
//
#import <Foundation/Foundation.h>

@interface TodoItem : NSObject <NSSecureCoding>

@property(nonatomic,strong) NSString *todoId;
@property(nonatomic,strong) NSString *title;
@property(nonatomic,assign) BOOL completed;

@end
