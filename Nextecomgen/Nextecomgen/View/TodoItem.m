//
//  TodoItem.m
//  Nextecomgen
//
//  Created by Harshith on 07/07/26.
//

#import "TodoItem.h"

@implementation TodoItem


+ (BOOL)supportsSecureCoding {

    return YES;
}



-(void)encodeWithCoder:(NSCoder *)coder {


    [coder encodeObject:self.todoId
                 forKey:@"id"];


    [coder encodeObject:self.title
                 forKey:@"title"];


    [coder encodeBool:self.completed
               forKey:@"completed"];

}



-(instancetype)initWithCoder:(NSCoder *)coder {


    self = [super init];


    if(self) {


        self.todoId =
        [coder decodeObjectOfClass:NSString.class
                            forKey:@"id"];



        self.title =
        [coder decodeObjectOfClass:NSString.class
                            forKey:@"title"];



        self.completed =
        [coder decodeBoolForKey:@"completed"];

    }


    return self;

}


@end
